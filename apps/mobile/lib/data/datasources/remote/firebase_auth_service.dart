import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';  // Temporarily disabled
import '../../../core/constants/enums.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';

/// Firebase authentication service for OAuth token acquisition
/// Handles Google, Apple, and Facebook sign-in
abstract class FirebaseAuthService {
  /// Sign in with Google and get OAuth ID token
  /// Returns Firebase user and OAuth token
  /// Throws [AuthException] on failure
  Future<Map<String, String>> signInWithGoogle();

  /// Sign in with Apple and get OAuth ID token
  /// Returns Firebase user and OAuth token
  /// Throws [AuthException] on failure
  Future<Map<String, String>> signInWithApple();

  /// Sign in with Facebook and get OAuth access token
  /// Returns Firebase user and OAuth token
  /// Throws [AuthException] on failure
  Future<Map<String, String>> signInWithFacebook();

  /// Sign out from Firebase
  Future<void> signOut();

  /// Get OAuth token for specified provider
  Future<Map<String, String>> getOAuthToken(AuthProvider provider);
}

/// Implementation of FirebaseAuthService
class FirebaseAuthServiceImpl implements FirebaseAuthService {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  FirebaseAuthServiceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  @override
  Future<Map<String, String>> signInWithGoogle() async {
    try {
      AppLogger.info('[FirebaseAuth] Starting Google sign-in flow...');

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.warning('[FirebaseAuth] Google sign-in cancelled by user');
        throw const AuthException(message: 'Google sign-in cancelled by user');
      }

      AppLogger.debug(
          '[FirebaseAuth] Google user signed in: ${googleUser.email}');

      // Obtain Google Auth credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      AppLogger.debug(
          '[FirebaseAuth] Signing in to Firebase with Google credential...');
      final userCredential =
          await firebaseAuth.signInWithCredential(credential);

      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        AppLogger.error('[FirebaseAuth] Failed to get Firebase ID token');
        throw const AuthException(message: 'Failed to get Firebase ID token');
      }

      AppLogger.info('[FirebaseAuth] Google sign-in successful');
      return {
        'token': idToken,
        'provider': AuthProvider.google.value,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('[FirebaseAuth] Google sign-in failed', error: e);
      throw AuthException(message: 'Google sign-in failed: ${e.message}');
    } catch (e) {
      AppLogger.error('[FirebaseAuth] Google sign-in error', error: e);
      throw AuthException(message: 'Google sign-in error: $e');
    }
  }

  @override
  Future<Map<String, String>> signInWithApple() async {
    try {
      AppLogger.info('[FirebaseAuth] Starting Apple sign-in flow...');

      // Trigger Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      AppLogger.debug('[FirebaseAuth] Apple credential obtained');

      // Create OAuth credential for Firebase
      final oAuthCredential =
          firebase_auth.OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Sign in to Firebase
      AppLogger.debug(
          '[FirebaseAuth] Signing in to Firebase with Apple credential...');
      final userCredential =
          await firebaseAuth.signInWithCredential(oAuthCredential);

      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        AppLogger.error('[FirebaseAuth] Failed to get Firebase ID token');
        throw const AuthException(message: 'Failed to get Firebase ID token');
      }

      AppLogger.info('[FirebaseAuth] Apple sign-in successful');
      return {
        'token': idToken,
        'provider': AuthProvider.apple.value,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('[FirebaseAuth] Apple sign-in failed', error: e);
      throw AuthException(message: 'Apple sign-in failed: ${e.message}');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        AppLogger.warning('[FirebaseAuth] Apple sign-in cancelled by user');
        throw const AuthException(message: 'Apple sign-in cancelled by user');
      }
      AppLogger.error('[FirebaseAuth] Apple sign-in authorization error',
          error: e);
      throw AuthException(message: 'Apple sign-in error: ${e.message}');
    } catch (e) {
      AppLogger.error('[FirebaseAuth] Apple sign-in error', error: e);
      throw AuthException(message: 'Apple sign-in error: $e');
    }
  }

  @override
  Future<Map<String, String>> signInWithFacebook() async {
    // TODO: Re-enable when flutter_facebook_auth iOS issues are fixed
    AppLogger.warning('[FirebaseAuth] Facebook sign-in temporarily disabled');
    throw const AuthException(message: 'Facebook sign-in temporarily disabled');
    /* try {
      // Trigger Facebook Sign-In flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw const AuthException(message: 'Facebook sign-in failed');
      }

      final accessToken = result.accessToken;
      if (accessToken == null) {
        throw const AuthException(message: 'Failed to get Facebook access token');
      }

      // Create Firebase credential
      final credential = 
          firebase_auth.FacebookAuthProvider.credential(accessToken.tokenString);

      // Sign in to Firebase
      final userCredential = 
          await firebaseAuth.signInWithCredential(credential);

      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw const AuthException(message: 'Failed to get Firebase ID token');
      }

      return {
        'token': idToken,
        'provider': AuthProvider.facebook.value,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: 'Facebook sign-in failed: ${e.message}');
    } catch (e) {
      throw AuthException(message: 'Facebook sign-in error: $e');
    } */
  }

  @override
  Future<void> signOut() async {
    try {
      AppLogger.info('[FirebaseAuth] Signing out from all providers...');
      await Future.wait([
        firebaseAuth.signOut(),
        googleSignIn.signOut(),
        // FacebookAuth.instance.logOut(),  // Temporarily disabled
      ]);
      AppLogger.info('[FirebaseAuth] Sign-out successful');
    } catch (e) {
      AppLogger.error('[FirebaseAuth] Sign-out failed', error: e);
      throw AuthException(message: 'Sign-out failed: $e');
    }
  }

  @override
  Future<Map<String, String>> getOAuthToken(AuthProvider provider) async {
    switch (provider) {
      case AuthProvider.google:
        return await signInWithGoogle();
      case AuthProvider.apple:
        return await signInWithApple();
      case AuthProvider.facebook:
        return await signInWithFacebook();
      case AuthProvider.email:
        throw const AuthException(message: 'Email provider does not use OAuth');
    }
  }
}
