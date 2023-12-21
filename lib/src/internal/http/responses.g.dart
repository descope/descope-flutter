// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JWTServerResponse _$JWTServerResponseFromJson(Map<String, dynamic> json) =>
    JWTServerResponse(
      json['sessionJwt'] as String?,
      json['refreshJwt'] as String?,
      json['user'] == null
          ? null
          : UserResponse.fromJson(json['user'] as Map<String, dynamic>),
      json['firstSeen'] as bool,
    );

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
      json['userId'] as String,
      (json['loginIds'] as List<dynamic>).map((e) => e as String).toList(),
      json['name'] as String?,
      json['picture'] as String?,
      json['email'] as String?,
      json['verifiedEmail'] as bool,
      json['phone'] as String?,
      json['verifiedPhone'] as bool,
      json['createdTime'] as int,
      json['customAttributes'] as Map<String, dynamic>?,
      json['givenName'] as String?,
      json['middleName'] as String?,
      json['familyName'] as String?,
    );

MaskedAddressServerResponse _$MaskedAddressServerResponseFromJson(
        Map<String, dynamic> json) =>
    MaskedAddressServerResponse(
      json['maskedEmail'] as String?,
      json['maskedPhone'] as String?,
    );

PasswordPolicyServerResponse _$PasswordPolicyServerResponseFromJson(
        Map<String, dynamic> json) =>
    PasswordPolicyServerResponse(
      json['minLength'] as int,
      json['lowercase'] as bool,
      json['uppercase'] as bool,
      json['number'] as bool,
      json['nonAlphanumeric'] as bool,
    );

EnchantedLinkServerResponse _$EnchantedLinkServerResponseFromJson(
        Map<String, dynamic> json) =>
    EnchantedLinkServerResponse(
      json['linkId'] as String,
      json['pendingRef'] as String,
      json['maskedEmail'] as String,
    );

TotpServerResponse _$TotpServerResponseFromJson(Map<String, dynamic> json) =>
    TotpServerResponse(
      json['provisioningUrl'] as String,
      const Uint8ListConverter().fromJson(json['image'] as List<int>),
      json['key'] as String,
    );

OAuthServerResponse _$OAuthServerResponseFromJson(Map<String, dynamic> json) =>
    OAuthServerResponse(
      json['url'] as String,
    );

SsoServerResponse _$SsoServerResponseFromJson(Map<String, dynamic> json) =>
    SsoServerResponse(
      json['url'] as String,
    );
