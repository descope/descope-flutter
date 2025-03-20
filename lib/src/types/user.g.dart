// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DescopeUser _$DescopeUserFromJson(Map<String, dynamic> json) => DescopeUser(
      json['userId'] as String,
      (json['loginIds'] as List<dynamic>).map((e) => e as String).toList(),
      (json['createdAt'] as num).toInt(),
      json['name'] as String?,
      json['picture'] == null ? null : Uri.parse(json['picture'] as String),
      json['email'] as String?,
      json['isVerifiedEmail'] as bool,
      json['phone'] as String?,
      json['isVerifiedPhone'] as bool,
      json['customAttributes'] as Map<String, dynamic>,
      json['givenName'] as String?,
      json['middleName'] as String?,
      json['familyName'] as String?,
      json['hasPassword'] as bool,
      json['status'] as String,
      (json['roleNames'] as List<dynamic>).map((e) => e as String).toList(),
      (json['ssoAppIds'] as List<dynamic>).map((e) => e as String).toList(),
      (json['oauth'] as List<dynamic>).map((e) => e as String).toList(),
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
      'givenName': instance.givenName,
      'middleName': instance.middleName,
      'familyName': instance.familyName,
      'hasPassword': instance.hasPassword,
      'status': instance.status,
      'roleNames': instance.roleNames,
      'ssoAppIds': instance.ssoAppIds,
      'oauth': instance.oauthProviders,
    };
