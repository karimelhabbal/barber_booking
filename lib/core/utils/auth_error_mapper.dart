import 'package:barber_booking/core/l10n/app_localizations.dart';

extension AuthErrorLocalizer on String {
  String localizedMessage(AppLocalizations loc) {
    switch (this) {
      case 'invalid-name':
        return loc.invalidName;

      case 'invalid-phone-number':
        return loc.invalidPhoneNumber;

      case 'invalid-verification-code':
        return loc.invalidVerificationCode;

      case 'verification-in-progress':
        return loc.verificationInProgress;

      case 'session-expired':
        return loc.sessionExpired;

      case 'too-many-requests':
        return loc.tooManyRequests;

      case 'network-request-failed':
        return loc.networkRequestFailed;

      case 'operation-not-allowed':
        return loc.operationNotAllowed;

      case 'unauthorized-domain':
        return loc.unauthorizedDomain;

      case 'captcha-check-failed':
      case 'missing-app-credential':
        return loc.captchaCheckFailed;

      case 'firebase-not-initialized':
        return loc.firebaseNotInitialized;

      case 'unsupported-platform':
        return loc.unsupportedPlatform;

      case 'send-code-failed':
        return loc.sendCodeFailed;

      case 'verify-code-failed':
      case 'verification-failed':
        return loc.verifyCodeFailed;

      case 'request-new-code':
        return loc.requestNewCode;

      case 'logout-failed':
        return loc.logoutFailed;

      default:
        return loc.genericAuthError;
    }
  }
}
