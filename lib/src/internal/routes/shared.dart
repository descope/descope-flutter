import 'package:descope/src/internal/others/error.dart';

import '/src/session/token.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '/src/types/user.dart';
import '../http/responses.dart';

extension ConvertMaskedAddress on MaskedAddressServerResponse {
  String convert(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.email:
        return maskedEmail != null ? maskedEmail! : throw InternalErrors.decodeError.add(message: 'Missing masked email');
      case DeliveryMethod.sms:
      case DeliveryMethod.whatsapp:
        return maskedPhone != null ? maskedPhone! : throw InternalErrors.decodeError.add(message: 'Missing masked phone');
    }
  }
}

extension ConvertUserResponse on UserResponse {
  DescopeUser convert() {
    final emailValue = (email ?? '').isNotEmpty ? email : null;
    final phoneValue = (phone ?? '').isNotEmpty ? phone : null;
    Uri? uri;
    final pic = picture;
    if (pic != null && pic.isNotEmpty) {
      uri = Uri.parse(pic);
    }
    return DescopeUser(userId, loginIds, createdTime, name, uri, emailValue, verifiedEmail, phoneValue, verifiedPhone);
  }
}

extension ConvertJWTResponse on JWTServerResponse {
  AuthenticationResponse convert() {
    final refreshJwt = this.refreshJwt;
    if (refreshJwt == null) {
      throw InternalErrors.decodeError.add(message: 'Missing refresh JWT');
    }
    final user = this.user;
    if (user == null) {
      throw InternalErrors.decodeError.add(message: 'Missing user details');
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
