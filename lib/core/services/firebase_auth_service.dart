import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

/// Centralized service handling Firebase Phone Number Authentication
/// following official Firebase Android & Flutter documentation.
class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Returns current authenticated Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of user authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Formats the raw input phone number to E.164 standard (e.g. +91XXXXXXXXXX)
  static String formatPhoneNumber(String rawMobile, {String defaultCountryCode = '+91'}) {
    String clean = rawMobile.replaceAll(RegExp(r'[^\d+]'), '');
    if (!clean.startsWith('+')) {
      if (clean.length == 10) {
        clean = '$defaultCountryCode$clean';
      } else {
        clean = '+$clean';
      }
    }
    return clean;
  }

  /// Sends an SMS verification code to the given [phoneNumber].
  ///
  /// Implements all 4 official callbacks:
  /// 1. [verificationCompleted]: Invoked for instant verification or automatic SMS retrieval.
  /// 2. [verificationFailed]: Invoked on invalid request, bad format, quota issues, etc.
  /// 3. [codeSent]: Invoked when the SMS verification code has been dispatched.
  /// 4. [codeAutoRetrievalTimeout]: Invoked when auto-retrieval times out after [timeout].
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String errorMessage, FirebaseAuthException exception) onVerificationFailed,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final formattedNumber = formatPhoneNumber(phoneNumber);
    logger.i('📲 FirebaseAuthService: verifyPhoneNumber initiated for $formattedNumber');

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        timeout: timeout,
        forceResendingToken: resendToken,

        // 1. Instant verification or auto-retrieval via Play Services SMS Retriever API
        verificationCompleted: (PhoneAuthCredential credential) {
          logger.i('⚡ FirebaseAuthService: verificationCompleted (instant/auto-retrieval)');
          onVerificationCompleted(credential);
        },

        // 2. Verification failed callback
        verificationFailed: (FirebaseAuthException e) {
          final mappedError = mapFirebaseAuthException(e);
          logger.e('❌ FirebaseAuthService: verificationFailed [${e.code}] — $mappedError');
          onVerificationFailed(mappedError, e);
        },

        // 3. SMS code sent callback
        codeSent: (String verificationId, int? newResendToken) {
          logger.i('📬 FirebaseAuthService: codeSent [verificationId: $verificationId, resendToken: $newResendToken]');
          onCodeSent(verificationId, newResendToken);
        },

        // 4. Auto retrieval timeout callback
        codeAutoRetrievalTimeout: (String verificationId) {
          logger.w('⏳ FirebaseAuthService: codeAutoRetrievalTimeout for $verificationId');
          onCodeAutoRetrievalTimeout(verificationId);
        },
      );
    } on FirebaseAuthException catch (e) {
      final mappedError = mapFirebaseAuthException(e);
      logger.e('❌ FirebaseAuthService: verifyPhoneNumber exception [${e.code}] — $mappedError');
      onVerificationFailed(mappedError, e);
    } catch (e) {
      logger.e('❌ FirebaseAuthService: unexpected error during verifyPhoneNumber: $e');
      onVerificationFailed(e.toString(), FirebaseAuthException(code: 'unknown', message: e.toString()));
    }
  }

  /// Verifies the entered SMS code against the [verificationId] and signs the user in.
  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      logger.i('🔐 FirebaseAuthService: Creating PhoneAuthCredential with verificationId: $verificationId');
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      logger.i('🔐 FirebaseAuthService: Signing in with credential...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      logger.i('✅ FirebaseAuthService: Sign-in successful for UID: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      final message = mapFirebaseAuthException(e);
      logger.e('❌ FirebaseAuthService: signInWithOtp failed [${e.code}] — $message');
      throw FirebaseAuthException(code: e.code, message: message);
    } catch (e) {
      logger.e('❌ FirebaseAuthService: signInWithOtp unexpected error: $e');
      rethrow;
    }
  }

  /// Completes sign-in directly with an existing [PhoneAuthCredential]
  /// (e.g. obtained via [verificationCompleted]).
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      logger.i('⚡ FirebaseAuthService: Signing in with auto-retrieved credential...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      logger.i('✅ FirebaseAuthService: Auto sign-in successful for UID: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      final message = mapFirebaseAuthException(e);
      logger.e('❌ FirebaseAuthService: signInWithCredential failed [${e.code}] — $message');
      throw FirebaseAuthException(code: e.code, message: message);
    } catch (e) {
      logger.e('❌ FirebaseAuthService: signInWithCredential unexpected error: $e');
      rethrow;
    }
  }

  /// Signs the user out from Firebase Authentication.
  Future<void> signOut() async {
    try {
      logger.i('🚪 FirebaseAuthService: Signing out...');
      await _auth.signOut();
      logger.i('✅ FirebaseAuthService: Sign-out complete');
    } catch (e) {
      logger.e('❌ FirebaseAuthService: Error during signOut: $e');
    }
  }

  /// Maps official Firebase Authentication error codes to user-friendly messages.
  static String mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The provided phone number format is invalid. Please enter a valid 10-digit mobile number.';
      case 'invalid-verification-code':
        return 'The verification code entered is incorrect. Please check and try again.';
      case 'invalid-verification-id':
        return 'The verification session is invalid or has expired. Please request a new OTP.';
      case 'session-expired':
        return 'The SMS verification code has expired. Please tap Resend OTP to get a new code.';
      case 'quota-exceeded':
        return 'SMS quota for this project has been exceeded. Please try again later.';
      case 'too-many-requests':
        return 'Too many attempts have been made. We have temporarily blocked requests from this device for security. Please try again later.';
      case 'app-not-authorized':
        return 'App is not authorized to use Firebase Authentication. Please verify SHA certificate fingerprints.';
      case 'missing-activity-for-recaptcha':
      case 'null-activity':
        return 'reCAPTCHA verification failed due to missing activity.';
      case 'network-request-failed':
        return 'Network error occurred. Please check your internet connection and try again.';
      case 'user-disabled':
        return 'This user account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled in Firebase Console.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
