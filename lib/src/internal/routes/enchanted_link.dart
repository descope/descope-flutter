import '/src/internal/http/descope_client.dart';
import '/src/internal/http/responses.dart';
import '/src/sdk/routes.dart';
import '/src/types/error.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import 'shared.dart';

const defaultPollDuration = Duration(minutes: 2);

class EnchantedLink implements DescopeEnchantedLink {
  final DescopeClient client;

  EnchantedLink(this.client);

  @override
  Future<EnchantedLinkResponse> signUp({required String loginId, SignUpDetails? details, String? redirectUrl}) async {
    return (await client.enchantedLinkSignUp(loginId, details, redirectUrl)).convert();
  }

  @override
  Future<EnchantedLinkResponse> signIn({required String loginId, String? redirectUrl, SignInOptions? options}) async {
    return (await client.enchantedLinkSignIn(loginId, redirectUrl, options)).convert();
  }

  @override
  Future<EnchantedLinkResponse> signUpOrIn({required String loginId, String? redirectUrl, SignInOptions? options}) async {
    return (await client.enchantedLinkSignUpOrIn(loginId, redirectUrl, options)).convert();
  }

  @override
  Future<EnchantedLinkResponse> updateEmail({required String email, required String loginId, String? redirectUrl, required String refreshJwt, UpdateOptions? options}) async {
    return (await client.enchantedLinkUpdateEmail(email, loginId, redirectUrl, refreshJwt, options)).convert();
  }

  @override
  Future<AuthenticationResponse> checkForSession({required String pendingRef}) async {
    return (await client.enchantedLinkPendingSession(pendingRef)).convert();
  }

  @override
  Future<AuthenticationResponse> pollForSession({required String pendingRef, Duration? timeout}) async {
    final start = DateTime.now();
    do {
      try {
        final jwtResponse = await checkForSession(pendingRef: pendingRef);
        return jwtResponse;
      } catch (e) {
        // Wait for 1 second
        Future.delayed(const Duration(seconds: 1));
      }
    } while (DateTime.now().difference(start) <= (timeout ?? defaultPollDuration));
    throw DescopeException.enchantedLinkExpired;
  }
}

extension on EnchantedLinkServerResponse {
  EnchantedLinkResponse convert() {
    return EnchantedLinkResponse(linkId, pendingRef, maskedEmail);
  }
}
