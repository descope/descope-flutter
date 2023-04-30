import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

part 'responses.g.dart';

@JsonSerializable()
class JWTServerResponse {
  String sessionJwt;
  String? refreshJwt;
  UserResponse? user;
  bool firstSeen;

  JWTServerResponse(this.sessionJwt, this.refreshJwt, this.user, this.firstSeen);
  static var fromJson = _$JWTServerResponseFromJson;
}

@JsonSerializable()
class MaskedAddressServerResponse {
  String? maskedEmail;
  String? maskedPhone;

  MaskedAddressServerResponse(this.maskedEmail, this.maskedPhone);
  static var fromJson = _$MaskedAddressServerResponseFromJson;
}

@JsonSerializable()
class UserResponse {
  String userId;
  List<String> loginIds;
  String? name;
  String? picture;
  String? email;
  bool verifiedEmail;
  String? phone;
  bool verifiedPhone;

  UserResponse(this.userId, this.loginIds, this.name, this.picture, this.email, this.verifiedEmail, this.phone, this.verifiedPhone);
  static var fromJson = _$UserResponseFromJson;
}

@JsonSerializable()
class PasswordPolicyServerResponse {
  int minLength;
  bool lowercase;
  bool uppercase;
  bool number;
  bool nonAlphanumeric;

  PasswordPolicyServerResponse(this.minLength, this.lowercase, this.uppercase, this.number, this.nonAlphanumeric);
  static var fromJson = _$PasswordPolicyServerResponseFromJson;
}

@JsonSerializable()
class EnchantedLinkServerResponse {
  String linkId;
  String pendingRef;
  String maskedEmail;

  EnchantedLinkServerResponse(this.linkId, this.pendingRef, this.maskedEmail);
  static var fromJson = _$EnchantedLinkServerResponseFromJson;
}

@JsonSerializable()
class TotpServerResponse {
  final String provisioningUrl;
  @Uint8ListConverter()
  final Uint8List image;
  final String key;

  TotpServerResponse(this.provisioningUrl, this.image, this.key);
  static var fromJson = _$TotpServerResponseFromJson;
}

@JsonSerializable()
class OAuthServerResponse {
  final String url;

  OAuthServerResponse(this.url);
  static var fromJson = _$OAuthServerResponseFromJson;
}

@JsonSerializable()
class SsoServerResponse {
  final String url;

  SsoServerResponse(this.url);
  static var fromJson = _$SsoServerResponseFromJson;
}

class Uint8ListConverter implements JsonConverter<Uint8List, List<int>> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(List<int> json) {
    return Uint8List.fromList(json);
  }

  @override
  List<int> toJson(Uint8List object) {
    return object.toList();
  }
}
