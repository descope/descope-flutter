// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Value _$ValueFromJson(Map<String, dynamic> json) => _Value(
      json['sessionJwt'] as String,
      json['refreshJwt'] as String,
      DescopeUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ValueToJson(_Value instance) => <String, dynamic>{
      'sessionJwt': instance.sessionJwt,
      'refreshJwt': instance.refreshJwt,
      'user': instance.user,
    };
