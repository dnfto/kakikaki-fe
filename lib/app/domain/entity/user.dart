import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// 사용자 엔티티
@freezed
@HiveType(typeId: 1, adapterName: 'UserAdapter')
class User with _$User {
  const factory User({
    @HiveField(8) required String id,
    @HiveField(9) String? email,
    @HiveField(10) String? name,
  }) = _User;

  const User._();
}
