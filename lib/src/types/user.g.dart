// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DescopeUser _$DescopeUserFromJson(Map<String, dynamic> json) => DescopeUser(
      json['userId'] as String,
      (json['loginIds'] as List<dynamic>).map((e) => e as String).toList(),
      json['createdAt'] as int,
      json['name'] as String?,
      json['picture'] == null ? null : Uri.parse(json['picture'] as String),
      json['email'] as String?,
      json['isVerifiedEmail'] as bool,
      json['phone'] as String?,
      json['isVerifiedPhone'] as bool,
      json['customAttributes'] == null ? <String, dynamic>{} : json['customAttributes'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$DescopeUserToJson(DescopeUser instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'loginIds': instance.loginIds,
      'createdAt': instance.createdAt,
      'name': instance.name,
      'picture': instance.picture?.toString(),
      'email': instance.email,
      'isVerifiedEmail': instance.isVerifiedEmail,
      'phone': instance.phone,
      'isVerifiedPhone': instance.isVerifiedPhone,
      'customAttributes': instance.customAttributes,
    };
