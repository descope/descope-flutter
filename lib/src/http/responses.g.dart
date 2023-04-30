// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JWTServerResponse _$JWTServerResponseFromJson(Map<String, dynamic> json) =>
    JWTServerResponse(
      json['sessionJwt'] as String,
      json['refreshJwt'] as String?,
      json['user'] == null
          ? null
          : UserResponse.fromJson(json['user'] as Map<String, dynamic>),
      json['firstSeen'] as bool,
    );

Map<String, dynamic> _$JWTServerResponseToJson(JWTServerResponse instance) =>
    <String, dynamic>{
      'sessionJwt': instance.sessionJwt,
      'refreshJwt': instance.refreshJwt,
      'user': instance.user,
      'firstSeen': instance.firstSeen,
    };

MaskedAddressServerResponse _$MaskedAddressServerResponseFromJson(
        Map<String, dynamic> json) =>
    MaskedAddressServerResponse(
      json['maskedEmail'] as String?,
      json['maskedPhone'] as String?,
    );

Map<String, dynamic> _$MaskedAddressServerResponseToJson(
        MaskedAddressServerResponse instance) =>
    <String, dynamic>{
      'maskedEmail': instance.maskedEmail,
      'maskedPhone': instance.maskedPhone,
    };

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
      json['userId'] as String,
      (json['loginIds'] as List<dynamic>).map((e) => e as String).toList(),
      json['name'] as String?,
      json['picture'] as String?,
      json['email'] as String?,
      json['verifiedEmail'] as bool,
      json['phone'] as String?,
      json['verifiedPhone'] as bool,
    );

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'loginIds': instance.loginIds,
      'name': instance.name,
      'picture': instance.picture,
      'email': instance.email,
      'verifiedEmail': instance.verifiedEmail,
      'phone': instance.phone,
      'verifiedPhone': instance.verifiedPhone,
    };

PasswordPolicyServerResponse _$PasswordPolicyServerResponseFromJson(
        Map<String, dynamic> json) =>
    PasswordPolicyServerResponse(
      json['minLength'] as int,
      json['lowercase'] as bool,
      json['uppercase'] as bool,
      json['number'] as bool,
      json['nonAlphanumeric'] as bool,
    );

Map<String, dynamic> _$PasswordPolicyServerResponseToJson(
        PasswordPolicyServerResponse instance) =>
    <String, dynamic>{
      'minLength': instance.minLength,
      'lowercase': instance.lowercase,
      'uppercase': instance.uppercase,
      'number': instance.number,
      'nonAlphanumeric': instance.nonAlphanumeric,
    };

EnchantedLinkServerResponse _$EnchantedLinkServerResponseFromJson(
        Map<String, dynamic> json) =>
    EnchantedLinkServerResponse(
      json['linkId'] as String,
      json['pendingRef'] as String,
      json['maskedEmail'] as String,
    );

Map<String, dynamic> _$EnchantedLinkServerResponseToJson(
        EnchantedLinkServerResponse instance) =>
    <String, dynamic>{
      'linkId': instance.linkId,
      'pendingRef': instance.pendingRef,
      'maskedEmail': instance.maskedEmail,
    };

TotpServerResponse _$TotpServerResponseFromJson(Map<String, dynamic> json) =>
    TotpServerResponse(
      json['provisioningUrl'] as String,
      const Uint8ListConverter().fromJson(json['image'] as List<int>),
      json['key'] as String,
    );

Map<String, dynamic> _$TotpServerResponseToJson(TotpServerResponse instance) =>
    <String, dynamic>{
      'provisioningUrl': instance.provisioningUrl,
      'image': const Uint8ListConverter().toJson(instance.image),
      'key': instance.key,
    };

OAuthServerResponse _$OAuthServerResponseFromJson(Map<String, dynamic> json) =>
    OAuthServerResponse(
      json['url'] as String,
    );

Map<String, dynamic> _$OAuthServerResponseToJson(
        OAuthServerResponse instance) =>
    <String, dynamic>{
      'url': instance.url,
    };

SsoServerResponse _$SsoServerResponseFromJson(Map<String, dynamic> json) =>
    SsoServerResponse(
      json['url'] as String,
    );

Map<String, dynamic> _$SsoServerResponseToJson(SsoServerResponse instance) =>
    <String, dynamic>{
      'url': instance.url,
    };
