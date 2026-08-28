// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'حجز الحلاقة';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get bookNow => 'احجز الآن';

  @override
  String get dashboard => 'الرئيسية';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'الثيم';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get loginSubtitle => 'أدخل رقم هاتفك المصري لإرسال رمز التحقق.';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get egyptianPhoneHint => '10 1234 5678';

  @override
  String get invalidEgyptianPhone => 'أدخل رقم هاتف مصري صحيح.';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String otpSentTo(String phoneNumber) {
    return 'أرسلنا رمز التحقق إلى $phoneNumber.';
  }

  @override
  String get invalidOtpCode => 'أدخل رمز التحقق المكون من 6 أرقام.';

  @override
  String get confirm => 'تأكيد';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get welcomeMessage => 'مرحبًا بك في حجز الحلاق';

  @override
  String get logout => 'تسجيل الخروج';
}
