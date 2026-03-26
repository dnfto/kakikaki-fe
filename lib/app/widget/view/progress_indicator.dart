import 'package:kakikaki/core/extension/context_extension.dart';
import 'package:flutter/cupertino.dart';

/// `CupertinoActivityIndicator`를 기반으로  iOS 스타일의 인디케이터를 커스텀한 위젯
///
/// * 색상 커스터마이징: 사용자 지정 색상 적용.
/// * 진행률 표시: 부분적으로 진행 상태를 나타내는 partiallyRevealed 인디케이터 지원
class DefaultCircularProgressIndicator extends StatelessWidget {
  const DefaultCircularProgressIndicator(
      {super.key, this.color, this.progress});

  final Color? color; // 인디케이터 색상
  final double? progress; // 진행률 값 (0.0 ~ 1.0)
  // progress가 null이면 일반 인디케이터를 표시하고, 값이 있으면 부분적으로 진행된 인디케이터를 표시

  @override
  Widget build(BuildContext context) {
    if (progress != null) {
      return CupertinoActivityIndicator.partiallyRevealed(
        color: color ?? context.palette.primary,
        radius: 18,
        progress: progress!,
      );
    } else {
      return CupertinoActivityIndicator(
        color: color ?? context.palette.primary,
        radius: 18,
      );
    }
  }
}
