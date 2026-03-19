/// Primary 색상 타입
enum PrimaryColorType {
  skyBlue, // 스카이 블루 (기본 테마)
  pink, // 핑크
  blue, // 파란색
  red, // 빨간색
  orange, // 주황색
}

extension PrimaryColorTypeExtension on PrimaryColorType {
  String get name {
    switch (this) {
      case PrimaryColorType.skyBlue:
        return 'skyBlue';
      case PrimaryColorType.pink:
        return 'pink';
      case PrimaryColorType.blue:
        return 'blue';
      case PrimaryColorType.red:
        return 'red';
      case PrimaryColorType.orange:
        return 'orange';
    }
  }
}

extension PrimaryColorTypeStringExtension on String {
  PrimaryColorType toPrimaryColorType() {
    switch (this) {
      case 'skyBlue':
        return PrimaryColorType.skyBlue;
      case 'pink':
        return PrimaryColorType.pink;
      case 'blue':
        return PrimaryColorType.blue;
      case 'red':
        return PrimaryColorType.red;
      case 'orange':
        return PrimaryColorType.orange;
      default:
        return PrimaryColorType.skyBlue;
    }
  }
}
