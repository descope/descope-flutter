import '/src/internal/others/stubs/stub_html.dart' if (dart.library.js) 'dart:html' hide Platform;
import '/src/internal/others/stubs/stub_js_util.dart' if (dart.library.js) 'dart:js_util';
import '/src/internal/others/stubs/stub_package_js.dart' if (dart.library.js) 'package:js/js.dart';

import '/src/internal/others/error.dart';
import '/src/types/error.dart';

class WebPasskeys {
  String getOrigin() {
    final origin = window.origin;
    if (origin != null) {
      return origin;
    }
    throw DescopeException.passkeyFailed.add(message:"Unable to get window origin");
  }

  Future<String> passkey(String options, bool create) async {
    try {
      _setupJs();
      if (create) {
        return await promiseToFuture(descopeWebAuthnCreate(options));
      } else {
        return await promiseToFuture(descopeWebAuthnGet(options));
      }
    } catch (e) {
      throw DescopeException.passkeyFailed.add(message: e.toString());
    }
  }
}

void _setupJs() async {
  ScriptElement scriptElement = ScriptElement();
  scriptElement.text = _webauthnScript;
  document.head?.children.add(scriptElement);
}

@JS()
external dynamic descopeWebAuthnCreate(String options);

@JS()
external dynamic descopeWebAuthnGet(String options);

const _webauthnScript = """

// webauthn create

async function descopeWebAuthnCreate(options) {
  if (!descopeIsWebAuthnSupported()) throw Error('Passkeys are not supported');
  const createOptions = descopeDecodeCreateOptions(options);
  const createResponse = await window.navigator.credentials.create(createOptions);
  return descopeEncodeCreateResponse(createResponse);
}

function descopeDecodeCreateOptions(value) {
  const options = JSON.parse(value);
  options.publicKey.challenge = descopeDecodeBase64Url(options.publicKey.challenge);
  options.publicKey.user.id = descopeDecodeBase64Url(options.publicKey.user.id);
  options.publicKey.excludeCredentials?.forEach((item) => {
    item.id = descopeDecodeBase64Url(item.id);
  });
  return options;
}

function descopeEncodeCreateResponse(credential) {
  return JSON.stringify({
    id: credential.id,
    rawId: descopeEncodeBase64Url(credential.rawId),
    type: credential.type,
    response: {
      attestationObject: descopeEncodeBase64Url(credential.response.attestationObject),
      clientDataJSON: descopeEncodeBase64Url(credential.response.clientDataJSON),
    }
  });
}

// webauthn get

async function descopeWebAuthnGet(options) {
  if (!descopeIsWebAuthnSupported()) throw Error('Passkeys are not supported');
  const getOptions = descopeDecodeGetOptions(options);
  const getResponse = await navigator.credentials.get(getOptions);
  return descopeEncodeGetResponse(getResponse);
}

function descopeDecodeGetOptions(value) {
  const options = JSON.parse(value);
  options.publicKey.challenge = descopeDecodeBase64Url(options.publicKey.challenge);
  options.publicKey.allowCredentials?.forEach((item) => {
    item.id = descopeDecodeBase64Url(item.id);
  });
  return options;
}

function descopeEncodeGetResponse(credential) {
  return JSON.stringify({
    id: credential.id,
    rawId: descopeEncodeBase64Url(credential.rawId),
    type: credential.type,
    response: {
      authenticatorData: descopeEncodeBase64Url(credential.response.authenticatorData),
      clientDataJSON: descopeEncodeBase64Url(credential.response.clientDataJSON),
      signature: descopeEncodeBase64Url(credential.response.signature),
      userHandle: credential.response.userHandle
        ? descopeEncodeBase64Url(credential.response.userHandle)
        : undefined,
    }
  });
}

// Conversion between ArrayBuffers and Base64Url strings

function descopeDecodeBase64Url(value) {
  const base64 = value.replace(/_/g, '/').replace(/-/g, '+');
  return Uint8Array.from(atob(base64), (c) => c.charCodeAt(0)).buffer;
}

function descopeEncodeBase64Url(value) {
  const base64 = btoa(String.fromCharCode.apply(null, new Uint8Array(value)));
  return base64.replace(/\\//g, '_').replace(/\\+/g, '-').replace(/=/g, '');
}

// Is supported

function descopeIsWebAuthnSupported() {
  const supported = !!(
    window.PublicKeyCredential &&
    navigator.credentials &&
    navigator.credentials.create &&
    navigator.credentials.get
  );
  return supported;
}
""";
