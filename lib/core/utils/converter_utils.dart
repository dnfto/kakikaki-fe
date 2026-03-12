import 'package:json_annotation/json_annotation.dart';

import 'formatter_utils.dart';

/// "yyyy-MM-dd'T'HH:mm:ss.SSS" 형식의 문자열을 [DateTime]으로 변환
class ConvertStringToDateTime implements JsonConverter<DateTime, String> {
  const ConvertStringToDateTime();

  @override
  DateTime fromJson(String json) {
    try {
      return DateTimeFormatter.dateTimeConvert.parse(json);
    } on FormatException catch (_) {
      return DateTime.parse(json);
    }
  }

  @override
  String toJson(DateTime object) {
    return DateTimeFormatter.dateTimeConvert.format(object);
  }
}

/// 'yyyy-MM-dd' 형식의 문자열을 [DateTime]으로 변환
class ConvertStringToDate implements JsonConverter<DateTime, String> {
  const ConvertStringToDate();

  @override
  DateTime fromJson(String json) {
    try {
      return DateTimeFormatter.dateConvert.parse(json);
    } on FormatException catch (_) {
      return DateTime.parse(json);
    }
  }

  @override
  String toJson(DateTime object) {
    return DateTimeFormatter.dateConvert.format(object);
  }
}

/// 데이터를 [int]로 변환
class ConvertToInt implements JsonConverter<int, Object> {
  const ConvertToInt();

  @override
  int fromJson(Object json) => switch (json) {
        int() => json,
        double() => json.toInt(),
        String() => int.tryParse(json) ?? 0,
        Object() => json as int,
      };

  @override
  Object toJson(int object) => object;
}

/// 데이터를 [double]로 변환
class ConvertToDouble implements JsonConverter<double, Object> {
  const ConvertToDouble();

  @override
  double fromJson(Object json) => switch (json) {
        int() => json.toDouble(),
        double() => json,
        String() => double.tryParse(json) ?? 0.0,
        Object() => json as double,
      };

  @override
  Object toJson(double object) => object;
}

/// 데이터를 [bool]로 변환
class ConvertToBool implements JsonConverter<bool, Object> {
  const ConvertToBool();

  @override
  bool fromJson(Object json) => switch (json) {
        bool() => json,
        int() => json != 0, // 0: false | 1: true
        double() => json != 0.0, // 0: false | 1: true
        String() => bool.tryParse(json, caseSensitive: false) ?? false,
        Object() => json as bool,
      };

  @override
  Object toJson(bool object) => object;
}
