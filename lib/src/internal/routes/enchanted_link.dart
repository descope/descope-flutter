import '/src/sdk/routes.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '../http/descope_client.dart';
import '../http/responses.dart';
import 'shared.dart';

const defaultPollDuration = Duration(minutes: 2);

class EnchantedLink implements DescopeEnchantedLink {
  final DescopeClient client;

  EnchantedLink(this.client);

  @override
  Future<EnchantedLinkResponse> signUp({required String loginId, SignUpDetails? details, String? uri}) async {
    return (await client.enchantedLinkSignUp(loginId, details, uri)).convert();
  }

  @override
  Future<EnchantedLinkResponse> signIn({required String loginId, String? uri}) async {
    return (await client.enchantedLinkSignIn(loginId, uri)).convert();
  }

  @override
  Future<EnchantedLinkResponse> signUpOrIn({required String loginId, String? uri}) async {
    return (await client.enchantedLinkSignUpOrIn(loginId, uri)).convert();
  }

  @override
  Future<EnchantedLinkResponse> updateEmail({required String email, required String loginId, String? uri, required String refreshJwt}) async {
    return (await client.enchantedLinkUpdateEmail(email, loginId, uri, refreshJwt)).convert();
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
    throw Exception('polling timed out');
  }
}

extension on EnchantedLinkServerResponse {
  EnchantedLinkResponse convert() {
    return EnchantedLinkResponse(linkId, pendingRef, maskedEmail);
  }
}
