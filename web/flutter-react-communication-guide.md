> 🔗 참고자료
> - [InAppWebView 공식 문서](https://inappwebview.dev/)
> - [Flutter WebView 가이드](https://flutter.dev/docs/development/packages-and-plugins/using-packages)

&nbsp;
# 기본적인 통신 방식
### **Flutter → React**
- Flutter에서 JavaScript 코드를 직접 실행
- React의 전역 함수 호출
- 데이터를 문자열로 전달
### **React → Flutter**
- React에서 특별한 함수 호출
- Flutter의 핸들러가 수신
- JSON 형태로 데이터 전달 가능

&nbsp;
# 환경 설정 예시
### Flutter 쪽
- `flutter_inappwebview` 패키지 설치
```dart
// 기본 WebView 설정 예시
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MyWebViewPage extends StatefulWidget {
  @override
  _MyWebViewPageState createState() => _MyWebViewPageState();
}

class _MyWebViewPageState extends State<MyWebViewPage> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("https://your-react-website.com")
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,        // JavaScript 활성화 (필수로 설정하기)
          domStorageEnabled: true,        // localStorage 사용 가능
          databaseEnabled: true,          // IndexedDB 사용 가능
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
          _setupCommunication(controller);  // 통신 설정
        },
        onLoadStop: (controller, url) {
          _onPageLoaded(controller);        // 페이지 로드 완료 시 호출
        },
      ),
    );
  }
}
```
### React 쪽
```javascript
// React 앱의 public/index.html 또는 App.js에 추가
// Flutter와 통신하기 위한 기본 설정

// 1. Flutter WebView 환경인지 확인하는 함수
function isFlutterWebView() {
  return typeof window.flutter_inappwebview !== 'undefined';
}

// 2. 안전하게 로그를 출력하는 함수
function safeLog(message, data = '') {
  console.log(`[React] ${message}`, data);
}

// 3. 앱 초기화 시 환경 확인
window.addEventListener('DOMContentLoaded', function() {
  if (isFlutterWebView()) {
    safeLog('Flutter WebView 환경에서 실행 중');
  } else {
    safeLog('일반 브라우저 환경에서 실행 중');
  }
});
```

&nbsp;
# Flutter → React 단방향 통신
### 첫 번째 방식 - Flutter에서 JS 코드 직접 작성하기
- `flutter_inappwebview` 패키지에서 제공하는 `InAppWebViewController` 클래스의 `evalueateJavascript(required String source)` 메서드를 활용
- 이름 그대로 JS를 평가/실행하는 메서드로, 웹뷰(Webview) 내에 로드된 웹 페이지의 컨텍스트에서 **JS 코드를 직접 실행**하는 데 사용된다.
- `source` 파라미터로 웹뷰 내에서 실행하고자 하는 JS 코드 문자열을 넘겨주면 된다.
```dart
Future<void> _sendDataToReact(InAppWebViewController controller, String message) async {
  await controller.evaluateJavascript(source: '''
    console.log('Flutter에서 메시지 받음: $message');
    // 전역(`window`)에서 `receiveMessageFromFlutter` 함수를 찾아서 실행
    if (typeof window.receiveMessageFromFlutter === 'function') {
      window.receiveMessageFromFlutter('$message');
    }
  ''');
}
```
### 예시 - Flutter에서 로그인 정보를 React에 전달
```dart
class UserInfo {
  final String name;
  final String email;
  final String token;

  UserInfo({required this.name, required this.email, required this.token});

  String toJson() {
    return '{"name": "$name", "email": "$email", "token": "$token"}';
  }
}

Future<void> _sendUserInfoToReact(UserInfo user) async {
  if (webViewController == null) return;
  await webViewController!.evaluateJavascript(source: '''
    // React에 사용자 정보 전달
    const userInfo = ${user.toJson()};
    localStorage.setItem('user_info', JSON.stringify(userInfo));
    localStorage.setItem('access_token', userInfo.token);
    
    // React 함수 호출
    if (typeof window.receiveUserInfo === 'function') {
      window.receiveUserInfo(userInfo);
    }
    
    // React 컴포넌트 새로고침 트리거
    if (typeof window.refreshUserData === 'function') {
      window.refreshUserData();
    }
  ''');
}
```
### 예시 - React 컴포넌트에서 Flutter로부터 데이터 수신
```javascript
import React, { useState, useEffect } from 'react';

function UserProfile() {
  const [userInfo, setUserInfo] = useState(null);
  
  useEffect(() => {
    // 1. Flutter로부터 사용자 정보 받는 함수 등록
    window.receiveUserInfo = function(userData) {
      setUserInfo(userData);
    };
    
    // 2. 기존에 저장된 정보가 있는지 확인
    const savedUserInfo = localStorage.getItem('user_info');
    if (savedUserInfo) {
      const parsedInfo = JSON.parse(savedUserInfo);
      setUserInfo(parsedInfo);
    }
    
    // 3. 컴포넌트 언마운트 시 리소스 정리하기
    return () => {
      delete window.receiveUserInfo;
    };
  }, []);
  
  if (!userInfo) {
    return <div>사용자 정보 로딩 중...</div>;
  }
  
  return (
    <div>
      <p>이름: {userInfo.name} / 이메일: {userInfo.email} / 토큰: {userInfo.token.substring(0, 20)}...</p>
    </div>
  );
}

export default UserProfile;
```

&nbsp;
# React → Flutter 단방향 통신
- `InAppWebViewController`의 `addJavaScriptHandler` 메서드를 활용할 수 있다.
- 이름 그대로 JS 핸들러를 추가하는 메서드다.
- 웹뷰 내의 JS 코드에서 특정 이름으로 정의된 핸들러를 호출하면, 이 호출이 Flutter 앱으로 전달되어 미리 정의된 Dart 함수를 실행하도록 설정한다.
- 이를 통해 웹 쪽에서 앱의 기능을 실행하거나 데이터를 Flutter 앱으로 보낼 수 있다.
- `evaluateJavascript`이랑 반대라고 생각해도 된다.
- `handlerName` 파라미터로 웹뷰의 JS 코드에서 핸들러를 호출할 때 사용할 이름을 설정해준다.
  - 이 이름은 **JS 쪽에서 `window.flutter_inappwebview.callHandler('handlerName', ...)` 형태로 사용**된다.
- `callback` 파라미터로 JS 쪽에서 핸들러를 호출했을 때 앱에서 실제로 실행될 함수를 넘겨준다.
  - 이 콜백 함수는 JS에서 핸들러를 호출할 때 전달한 인자들을 Dart의 `List<dynamic>` 형태로 받는다.
  - 그리고 비동기적으로 작동할 수 있으며, 앱에서 처리한 결과 값을 JS로 다시 반환할 수도 있다.
  - JS 쪽에서는 Promise를 반환하므로 당연히 `then`이나 async-await도 쓸 수 있다.
### 예시
```dart
void _setupCommunication(InAppWebViewController controller) {
  // 네비게이션 요청 받기
  controller.addJavaScriptHandler(
    handlerName: 'navigate',
    callback: (args) {
      if (args.isNotEmpty) {
        final route = args[0].toString();
        _handleNavigation(route);
      }
    },
  );
}

// 대충 라우팅 로직
```
```javascript
// Flutter와 통신 가능한지 확인
static isAvailable() {
  return typeof window.flutter_inappwebview !== 'undefined';
}

// 네비게이션 요청
static async navigate(route) {
  if (!this.isAvailable()) {
    return false;
  }
  
  await window.flutter_inappwebview.callHandler('navigate', route);
  return true;
}
```

&nbsp;
# 실제 적용된 코드 (픽스 X)
####  TypeScript 타입 선언
- 각 파일에 주석으로 설명을 달아두었으므로 자세한 설명은 생략
```typescript
// src/types/window.d.ts
export {}; // tsconfig 조절하면 안 써도 됨

declare global {
  interface Window {
    flutter_inappwebview?: {
      callHandler: <T = unknown>(
        handlerName: string,
        ...args: unknown[]
      ) => Promise<T>;
    };

    receiveTokenFromFlutter: (token: string) => void;
  }
}
```
#### Flutter 통신 유틸리티
```typescript
// src/utils/flutterBridge.ts
export const notifyFlutter = (
  handler: string, 
  args: Record<string, unknown> = {}
): void => {
  if (window.flutter_inappwebview) {
    window.flutter_inappwebview.callHandler(handler, args);
    console.log(`Flutter 핸들러 호출 성공: ${handler}`, args);
  } else {
    console.warn('flutter_inappwebview is not available');
  }
};
```
#### React 앱 초기화
```typescript
// src/main.tsx
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { GlobalStyle } from "./styles/global";

window.receiveTokenFromFlutter = (token: string) => {
  console.log(`플러터로부터 토큰 수신: ${token}`);
  localStorage.setItem("access_token", token);
  
  // 토큰을 저장한 후, 페이지를 새로고침하여 로그인 상태를 반영
  // (또는 상태 관리 라이브러리를 사용해 리렌더링 트리거)
  window.location.reload();
};

// 2. root 엘리먼트를 가져와서 리액트 앱을 한 번만 렌더링
const rootElement = document.getElementById("root");
if (rootElement) {
  const root = ReactDOM.createRoot(rootElement);
  root.render(
    <React.StrictMode>
      <GlobalStyle />
      <App />
    </React.StrictMode>
  );
} else {
  console.error("Failed to find the root element");
}
```
#### API 클라이언트 통합
```typescript
// src/api/client.ts
import ky, { Options } from "ky";
import { notifyFlutter } from "../utils/flutterBridge";

const ACCESS_TOKEN_KEY = 'access_token';
const getAccessToken = () => localStorage.getItem(ACCESS_TOKEN_KEY);

const refreshAccessToken = async (): Promise<string | null> => {
  try {
    const res = await authApi.post('users/token/refresh').json<{ accessToken: string }>();
    const newToken = res.accessToken;
    localStorage.setItem(ACCESS_TOKEN_KEY, newToken);
    console.log('토큰 재발급 성공');
    return newToken;
  } catch (error) {
    console.warn('토큰 재발급 실패:', error);
    localStorage.removeItem(ACCESS_TOKEN_KEY);
    return null;
  }
};

// 1. 인증 없는 기본 API (prefix만 있음)
const baseApi = ky.create({
  prefixUrl: import.meta.env.VITE_API_BASE_URL,
  credentials: 'include',
});

// 2. 인증 관련 API 전용 (refresh, login 등)
const authApi = baseApi.extend({});

// 3. 메인 API (AccessToken 자동 주입 및 만료 처리)
export const api = baseApi.extend({
  hooks: {
    beforeRequest: [
      (request) => {
        const token = getAccessToken();
        if (token) {
          request.headers.set('Authorization', `Bearer ${token}`);
        }
      },
    ],
    afterResponse: [
      async (request, options, response) => {
        if (response.status === 401) {
          console.log('401 에러 감지 - 토큰 재발급 시도');
          
          const newToken = await refreshAccessToken();

          if (newToken) {
            // AccessToken 재설정 후 재요청
            const retryOptions: Options = {
              ...options,
              headers: {
                ...options.headers,
                Authorization: `Bearer ${newToken}`,
              },
            };
            console.log('새 토큰으로 재요청');
            return await baseApi(request.url, retryOptions);
          } else {
            // 재발급 실패 시 플러터에 세션 만료 알림
            console.log('토큰 재발급 실패 - Flutter에 세션 만료 알림');
            notifyFlutter('sessionExpired');
            
            // 재발급 실패: 로그아웃 처리
            window.location.href = "/You-don't-have-any-token";
          }
        }

        return response;
      },
    ],
  },
});
```
#### 라우트
```typescript
// src/components/ProtectedRoute.tsx
import { Navigate, Outlet } from 'react-router-dom';
import { useEffect, useState } from 'react';

export const ProtectedRoute = () => {
  const [isClient, setIsClient] = useState(false);
  const [tokenExists, setTokenExists] = useState<boolean | null>(null);

  useEffect(() => {
    setIsClient(true);
    const token = localStorage.getItem('access_token');
    setTokenExists(!!token);
    
    console.log(`토큰 확인 결과: ${token ? '존재함' : '없음'}`);
  }, []);

  if (!isClient || tokenExists === null) {
    // 클라이언트 측 렌더링 및 토큰 확인 전까지는 로딩 표시
    return <div className="loading">토큰 확인 중...</div>;
  }

  if (!tokenExists) {
    // 토큰이 없을 때의 처리
    if (window.flutter_inappwebview) {
      // WebView 환경: Flutter에 로그인 요청
      console.log('토큰 없음. 플러터에 로그인 요청.');
      window.flutter_inappwebview.callHandler('onRequireLogin');
      
      return (
        <div className="login-required">
          <h2>로그인이 필요</h2>
          <p>로그인 화면으로 이동 중...</p>
        </div>
      );
    } else {
      // 일반 브라우저 환경: 로그인 페이지로 리다이렉트
      console.log('일반 브라우저 환경. 로그인 페이지로 이동.');
      return <Navigate to="/You-don't-have-any-token" replace />;
    }
  }

  // 토큰이 존재하면 자식 라우트들을 렌더링
  return <Outlet />;
};

// 사용 예시: App.tsx에서
function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/You-don't-have-any-token" element={<TokenErrorPage />} />
        
        {/* 보호된 라우트들 */}
        <Route element={<ProtectedRoute />}>
          <Route path="/" element={<HomePage />} />
          <Route path="/profile" element={<ProfilePage />} />
          <Route path="/dashboard" element={<DashboardPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
```

&nbsp;
# 발생 가능한 에러
#### window.myFunction is not defined
```javascript
// 함수 존재 여부를 항상 확인하거나
if (typeof window.myFunction === 'function') {
  window.myFunction(data);
} else {
  console.warn('myFunction이 정의되지 않았습니다.');
}

// 안전한 호출 함수 사용
function safeCall(functionName, ...args) {
  if (typeof window[functionName] === 'function') {
    return window[functionName](...args);
  } else {
    console.warn(`함수 ${functionName}가 존재하지 않습니다.`);
    return null;
  }
}
```

&nbsp;
#### 왜 데이터 전달 안 되지 ¯\_ಠ_ಠ_/¯
```dart
// 문제 진단: React가 준비되었는지 확인
Future<void> diagnoseReactStatus(InAppWebViewController controller) async {
  try {
    // 1. 기본 JavaScript 실행 가능한지 확인
    final basicTest = await controller.evaluateJavascript(
      source: "console.log('Basic JS works'); 'OK';"
    );
    print('기본 JavaScript 실행: $basicTest');
    
    // 2. Flutter 통신 객체 존재 확인
    final flutterObject = await controller.evaluateJavascript(
      source: "typeof window.flutter_inappwebview"
    );
    print('Flutter 통신 객체: $flutterObject');
    
    // 3. 특정 함수 존재 확인
    final targetFunction = await controller.evaluateJavascript(
      source: "typeof window.receiveMessageFromFlutter"
    );
    print('대상 함수 존재: $targetFunction');
    
  } catch (e) {
    print('진단 실패: $e');
  }
}
```
