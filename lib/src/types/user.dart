import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import '/src/session/session.dart';

part 'user.g.dart';

/// The [DescopeUser] class represents an existing user in Descope.
///
/// After a user is signed in with any authentication method the [DescopeSession] object
/// keeps a [DescopeUser] value in its [DescopeSession.user] property so the user's details are always
/// available.
///
/// In the example below we finalize an OTP authentication for the user by verifying the
/// code. The authentication response has a [DescopeUser] property which can be used
/// directly or later on when it's kept in the [DescopeSession].
///
///     final authResponse = await Descope.otp.verify(method: DeliveryMethod.email, loginId: 'andy@example.com', code: '123456');
///     print('Finished OTP login for user: ${authResponse.user}');
///
///     Descope.sessionManager.session = DescopeSession(authResponse);
///     print('Created session for user ${descopeSession.user.userId}');
///
/// The details for a signed in user can be updated manually by calling the `auth.me` API with
/// the `refreshJwt` from the active [DescopeSession]. If the operation is successful the call
/// returns a new [DescopeUser] value.
///
///     final session = Descope.sessionManager.session;
///     if (session != null) {
///       final descopeUser = await Descope.auth.me(refreshJwt: session.refreshJwt);
///       session.updateUser(descopeUser);
///     }
///
/// In the code above we check that there's an active [DescopeSession] in the shared
/// session manager. If so we ask the Descope server for the latest user details and
/// then update the [DescopeSession] with them.
@JsonSerializable()
class DescopeUser {
  /// The unique identifier for the user in Descope.
  /// This value never changes after the user is created, and it always matches
  /// the `Subject` (`sub`) claim value in the user's JWT after signing in.
  final String userId;

  /// The identifiers the user can sign in with.
  /// This is a list of one or more email addresses, phone numbers, usernames, or any
  /// custom identifiers the user can authenticate with.
  final List<String> loginIds;

  /// The time at which the user was created in Descope.
  final int createdAt;

  /// The user's full name.
  final String? name;

  /// The user's profile picture.
  final Uri? picture;

  /// The user's email address.
  ///
  /// If this is non-null and the `isVerifiedEmail` flag is `true` then this email address
  /// can be used to do email based authentications such as magic link, OTP, etc.
  final String? email;

  /// Whether the email address has been verified to be a valid authentication method
  /// for this user. If `email` is `nil` then this is always `false`.
  final bool isVerifiedEmail;

  /// The user's phone number.
  ///
  /// If this is non-null and the `isVerifiedPhone` flag is `true` then this phone number
  /// can be used to do phone based authentications such as OTP.
  final String? phone;

  /// Whether the phone number has been verified to be a valid authentication method
  /// for this user. If `phone` is `null` then this is always `false`.
  final bool isVerifiedPhone;

  /// A mapping of any custom attributes associated with this user.
  /// User custom attributes are managed via the Descope console.
  final Map<String, dynamic> customAttributes;

  /// Optional user's given name.
  final String? givenName;

  /// Optional user's middle name.
  final String? middleName;

  /// Optional user's family name.
  final String? familyName;

  /// Whether the user has a password set or not.
  final bool hasPassword;

  /// The user's status, one of 'enabled', 'disabled' or 'invited'.
  String status;

  /// A list of role names the user is associated with. Can be empty.
  List<String> roleNames;

  /// A list of SSO App IDs the user is associated with. Can be empty.
  List<String> ssoAppIds;

  /// A list of OAuth providers the user has used. Can be empty.
  List<String> oauthProviders;

  DescopeUser(this.userId, this.loginIds, this.createdAt, this.name, this.picture, this.email, this.isVerifiedEmail, this.phone, this.isVerifiedPhone, this.customAttributes, this.givenName, this.middleName, this.familyName, this.hasPassword, this.status, this.roleNames, this.ssoAppIds, this.oauthProviders);

  static var fromJson = _$DescopeUserFromJson;
  static var toJson = _$DescopeUserToJson;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DescopeUser &&
        other.userId == userId &&
        listEquals(other.loginIds, loginIds) &&
        other.createdAt == createdAt &&
        other.name == name &&
        other.picture == picture &&
        other.email == email &&
        other.isVerifiedEmail == isVerifiedEmail &&
        other.phone == phone &&
        other.isVerifiedPhone == isVerifiedPhone &&
        other.givenName == givenName &&
        other.middleName == middleName &&
        other.familyName == familyName;
  }

  @override
  int get hashCode {
    return Object.hash(userId, loginIds, createdAt, name, picture, email, isVerifiedEmail, phone, isVerifiedPhone, givenName, middleName, familyName);
  }
}
