import '/src/session/token.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '/src/types/user.dart';
import '../http/responses.dart';

extension ConvertMaskedAddress on MaskedAddressServerResponse {
  String convert(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.email:
        return maskedEmail != null ? maskedEmail! : throw Exception('Missing masked email');
      case DeliveryMethod.sms:
      case DeliveryMethod.whatsapp:
        return maskedPhone != null ? maskedPhone! : throw Exception('Missing masked phone');
    }
  }
}

extension on UserResponse {
  DescopeUser convert() {
    Uri? uri;
    final picture = this.picture;
    if (picture != null) {
      uri = Uri.parse(picture);
    }
    return DescopeUser(userId, loginIds, createdTime, name, uri, email, verifiedEmail, phone, verifiedPhone);
  }
}

extension ConvertJWTResponse on JWTServerResponse {
  AuthenticationResponse convert() {
    final refreshJwt = this.refreshJwt;
    if (refreshJwt == null) {
      throw Exception('Missing refresh JWT');
    }
    final user = this.user;
    if (user == null) {
      throw Exception('Missing user details');
    }
    return AuthenticationResponse(Token.decode(sessionJwt), Token.decode(refreshJwt), firstSeen, user.convert());
  }
}

extension ConvertJWTResponseToRefresh on JWTServerResponse {
  RefreshResponse toRefreshResponse() {
    Token? refreshToken;
    final refreshJwt = this.refreshJwt;
    if (refreshJwt != null) {
      refreshToken = Token.decode(refreshJwt);
    }
    return RefreshResponse(Token.decode(sessionJwt), refreshToken);
  }
}
