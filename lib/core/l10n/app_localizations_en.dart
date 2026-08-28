// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Barber Booking';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get bookNow => 'Book Now';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get loginSubtitle =>
      'Enter your Egyptian mobile number to receive a verification code.';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get egyptianPhoneHint => '10 1234 5678';

  @override
  String get invalidEgyptianPhone => 'Enter a valid Egyptian mobile number.';

  @override
  String get sendCode => 'Send code';

  @override
  String otpSentTo(String phoneNumber) {
    return 'We sent a verification code to $phoneNumber.';
  }

  @override
  String get invalidOtpCode => 'Enter the 6-digit verification code.';

  @override
  String get confirm => 'Confirm';

  @override
  String get resendCode => 'Resend code';

  @override
  String get welcomeMessage => 'Welcome to Barber Booking';

  @override
  String get logout => 'Log out';
}
