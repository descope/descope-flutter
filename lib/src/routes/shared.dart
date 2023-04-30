import '../http/responses.dart';
import '../types/others.dart';
import '../session/session.dart';

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

extension ConvertJWTResponse on JWTServerResponse {
  DescopeSession convert() {
    final refreshJwt = this.refreshJwt;
    if (refreshJwt == null) {
      throw Exception('Missing refresh JWT');
    }
    return DescopeSession(sessionJwt, refreshJwt);
  }
}
