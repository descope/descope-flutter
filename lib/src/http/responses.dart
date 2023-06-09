import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
import 'http_client.dart';

part 'responses.g.dart';

const refreshCookieName = "DSR";

@JsonSerializable(createToJson: false)
class JWTServerResponse {
  String sessionJwt;
  String? refreshJwt;
  UserResponse? user;
  bool firstSeen;

  JWTServerResponse(this.sessionJwt, this.refreshJwt, this.user, this.firstSeen);
  static var fromJson = _$JWTServerResponseFromJson;
  static var decoder = _parseHeaders(fromJson, (response, headers) {
    response.refreshJwt = headers[refreshCookieName] ?? response.refreshJwt;
  });
}

@JsonSerializable(createToJson: false)
class MaskedAddressServerResponse {
  String? maskedEmail;
  String? maskedPhone;

  MaskedAddressServerResponse(this.maskedEmail, this.maskedPhone);
  static var fromJson = _$MaskedAddressServerResponseFromJson;
  static var decoder = _ignoreHeaders(fromJson);
}

@JsonSerializable(createToJson: false)
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
  static var decoder = _ignoreHeaders(fromJson);
}

@JsonSerializable(createToJson: false)
class PasswordPolicyServerResponse {
  int minLength;
  bool lowercase;
  bool uppercase;
  bool number;
  bool nonAlphanumeric;

  PasswordPolicyServerResponse(this.minLength, this.lowercase, this.uppercase, this.number, this.nonAlphanumeric);
  static var fromJson = _$PasswordPolicyServerResponseFromJson;
  static var decoder = _ignoreHeaders(fromJson);
}

@JsonSerializable(createToJson: false)
class EnchantedLinkServerResponse {
  String linkId;
  String pendingRef;
  String maskedEmail;

  EnchantedLinkServerResponse(this.linkId, this.pendingRef, this.maskedEmail);
  static var fromJson = _$EnchantedLinkServerResponseFromJson;
  static var decoder = _ignoreHeaders(fromJson);
}

@JsonSerializable(createToJson: false)
class TotpServerResponse {
  final String provisioningUrl;
  @Uint8ListConverter()
  final Uint8List image;
  final String key;

  TotpServerResponse(this.provisioningUrl, this.image, this.key);
  static var fromJson = _$TotpServerResponseFromJson;
  static var decoder = _ignoreHeaders(fromJson);
}

@JsonSerializable(createToJson: false)
class OAuthServerResponse {
  final String url;

  OAuthServerResponse(this.url);
  static var fromJson = _$OAuthServerResponseFromJson;
  static var decoder = _ignoreHeaders(fromJson);
}

@JsonSerializable(createToJson: false)
class SsoServerResponse {
  final String url;

  SsoServerResponse(this.url);
  static var fromJson = _$SsoServerResponseFromJson;
  static var decoder = _ignoreHeaders(fromJson);
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

ResponseDecoder<T> _ignoreHeaders<T>(T Function(Map<String, dynamic>) fromJson) {
  return (json, headers) => fromJson(json);
}

ResponseDecoder<T> _parseHeaders<T>(T Function(Map<String, dynamic>) fromJson, void Function(T, Map<String, String>) parser) {
  return (json, headers) {
    final response = fromJson(json);
    parser(response, headers);
    return response;
  };
}
