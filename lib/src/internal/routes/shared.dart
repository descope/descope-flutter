import 'dart:io';

import 'package:flutter/foundation.dart';

import '/src/internal/http/responses.dart';
import '/src/internal/others/error.dart';
import '/src/session/token.dart';
import '/src/types/error.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '/src/types/user.dart';

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
    final nameValue = (name ?? '').isNotEmpty ? name : null;
    final givenNameValue = (givenName ?? '').isNotEmpty ? givenName : null;
    final middleNameValue = (middleName ?? '').isNotEmpty ? middleName : null;
    final familyNameValue = (familyName ?? '').isNotEmpty ? familyName : null;
    final caValue = customAttributes ?? <String, dynamic>{};

    Uri? uri;
    final pic = picture;
    if (pic != null && pic.isNotEmpty) {
      uri = Uri.parse(pic);
    }

    List<String> providers = [];
    providers.addAll(oauth?.keys ?? []);

    return DescopeUser(userId, loginIds, createdTime, nameValue, uri, emailValue, verifiedEmail, phoneValue, verifiedPhone, caValue, givenNameValue, middleNameValue, familyNameValue, password, status, roleNames, ssoAppIds, providers);
  }
}

extension ConvertJWTResponse on JWTServerResponse {
  AuthenticationResponse toAuthenticationResponse() {
    final sessionJwt = this.sessionJwt;
    if (sessionJwt == null || sessionJwt.isEmpty) {
      throw InternalErrors.decodeError.add(message: 'Missing session JWT');
    }
    final sessionToken = Token.decode(sessionJwt);

    DescopeToken refreshToken;
    final refreshJwt = this.refreshJwt;
    if (refreshJwt != null && refreshJwt.isNotEmpty) {
      refreshToken = Token.decode(refreshJwt);
    } else if (kIsWeb) {
      // web only - refresh might be available via cookie
      refreshToken = sessionToken;
    } else {
      throw InternalErrors.decodeError.add(message: 'Missing refresh JWT');
    }

    final user = this.user;
    if (user == null) {
      throw InternalErrors.decodeError.add(message: 'Missing user details');
    }

    return AuthenticationResponse(sessionToken, refreshToken, firstSeen, user.convert(), externalToken);
  }

  RefreshResponse toRefreshResponse() {
    final sessionJwt = this.sessionJwt;
    if (sessionJwt == null || sessionJwt.isEmpty) {
      throw InternalErrors.decodeError.add(message: 'Missing session JWT');
    }

    Token? refreshToken;
    final refreshJwt = this.refreshJwt;
    if (refreshJwt != null && refreshJwt.isNotEmpty) {
      refreshToken = Token.decode(refreshJwt);
    }
    
    return RefreshResponse(Token.decode(sessionJwt), refreshToken);
  }
}

void ensureMobilePlatform(DescopeException descopeException) {
  if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
    throw descopeException.add(message: 'Feature not supported on this platform');
  }
}
