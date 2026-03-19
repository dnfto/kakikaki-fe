import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:hive_flutter/hive_flutter.dart';
part 'auth_enums.g.dart';

@HiveType(typeId: 2, adapterName: 'SocialTypeAdapter')
enum SocialType {
  @HiveField(12)
  google,
  @HiveField(13)
  kakao,
  @HiveField(14)
  apple
}

/// 내부 앱에서 사용하는 성별 enum
enum Gender {
  male,
  female,
  unknown,
}

/// 내부 앱에서 사용하는 연령대 enum
enum AgeRange {
  ageRange1_9,
  ageRange10_14,
  ageRange15_19,
  ageRange20_29,
  ageRange30_39,
  ageRange40_49,
  ageRange50_59,
  ageRange60_69,
  ageRange70_79,
  ageRange80_89,
  ageRange90Plus,
  unknown,
}

/// Gender → 서버 코드 변환 ('M', 'F', 'UNKNOWN')
extension GenderExtension on Gender {
  String get serverCode {
    switch (this) {
      case Gender.male:
        return 'M';
      case Gender.female:
        return 'F';
      case Gender.unknown:
        return 'UNKNOWN';
    }
  }

  static Gender fromServerCode(String code) {
    switch (code) {
      case 'M':
        return Gender.male;
      case 'F':
        return Gender.female;
      default:
        return Gender.unknown;
    }
  }
}

/// AgeRange → 서버 코드 변환 ('AGE_RANGE_10_14' 등)
extension AgeRangeExtension on AgeRange {
  String get serverCode {
    switch (this) {
      case AgeRange.ageRange1_9:
        return 'AGE_RANGE_1_9';
      case AgeRange.ageRange10_14:
        return 'AGE_RANGE_10_14';
      case AgeRange.ageRange15_19:
        return 'AGE_RANGE_15_19';
      case AgeRange.ageRange20_29:
        return 'AGE_RANGE_20_29';
      case AgeRange.ageRange30_39:
        return 'AGE_RANGE_30_39';
      case AgeRange.ageRange40_49:
        return 'AGE_RANGE_40_49';
      case AgeRange.ageRange50_59:
        return 'AGE_RANGE_50_59';
      case AgeRange.ageRange60_69:
        return 'AGE_RANGE_60_69';
      case AgeRange.ageRange70_79:
        return 'AGE_RANGE_70_79';
      case AgeRange.ageRange80_89:
        return 'AGE_RANGE_80_89';
      case AgeRange.ageRange90Plus:
        return 'AGE_RANGE_90_PLUS';
      case AgeRange.unknown:
        return 'UNKNOWN';
    }
  }

  static AgeRange fromServerCode(String code) {
    switch (code) {
      case 'AGE_RANGE_1_9':
        return AgeRange.ageRange1_9;
      case 'AGE_RANGE_10_14':
        return AgeRange.ageRange10_14;
      case 'AGE_RANGE_15_19':
        return AgeRange.ageRange15_19;
      case 'AGE_RANGE_20_29':
        return AgeRange.ageRange20_29;
      case 'AGE_RANGE_30_39':
        return AgeRange.ageRange30_39;
      case 'AGE_RANGE_40_49':
        return AgeRange.ageRange40_49;
      case 'AGE_RANGE_50_59':
        return AgeRange.ageRange50_59;
      case 'AGE_RANGE_60_69':
        return AgeRange.ageRange60_69;
      case 'AGE_RANGE_70_79':
        return AgeRange.ageRange70_79;
      case 'AGE_RANGE_80_89':
        return AgeRange.ageRange80_89;
      case 'AGE_RANGE_90_PLUS':
        return AgeRange.ageRange90Plus;
      default:
        return AgeRange.unknown;
    }
  }
}

/// Kakao SDK Gender → 내부 Gender 매핑
extension KakaoGenderMapper on kakao.Gender {
  Gender toInternalGender() {
    switch (this) {
      case kakao.Gender.female:
        return Gender.female;
      case kakao.Gender.male:
        return Gender.male;
      default:
        return Gender.unknown;
    }
  }
}

/// Kakao SDK AgeRange → 내부 AgeRange 매핑
extension KakaoAgeRangeMapper on kakao.AgeRange {
  AgeRange toInternalAgeRange() {
    switch (this) {
      case kakao.AgeRange.age_0_9:
        return AgeRange.ageRange1_9;
      case kakao.AgeRange.age_10_14:
        return AgeRange.ageRange10_14;
      case kakao.AgeRange.age_15_19:
        return AgeRange.ageRange15_19;
      case kakao.AgeRange.age_20_29:
        return AgeRange.ageRange20_29;
      case kakao.AgeRange.age_30_39:
        return AgeRange.ageRange30_39;
      case kakao.AgeRange.age_40_49:
        return AgeRange.ageRange40_49;
      case kakao.AgeRange.age_50_59:
        return AgeRange.ageRange50_59;
      case kakao.AgeRange.age_60_69:
        return AgeRange.ageRange60_69;
      case kakao.AgeRange.age_70_79:
        return AgeRange.ageRange70_79;
      case kakao.AgeRange.age_80_89:
        return AgeRange.ageRange80_89;
      case kakao.AgeRange.age_90above:
        return AgeRange.ageRange90Plus;
      default:
        return AgeRange.unknown;
    }
  }
}
