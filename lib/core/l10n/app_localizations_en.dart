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
  String get theme => 'المظهر';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get otpSentTo => 'تم إرسال الرمز إلى';

  @override
  String get otpCode => 'رمز التحقق';

  @override
  String get confirm => 'تأكيد';

  @override
  String get verifyCode => 'تأكيد الرمز';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get welcomeBarberSaas => 'أهلًا بك في Barber SaaS';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get invalidName => 'أدخل اسمك.';

  @override
  String get invalidPhoneNumber => 'أدخل رقم هاتف صحيح.';

  @override
  String get invalidVerificationCode => 'رمز التحقق غير صحيح.';

  @override
  String get verificationInProgress => 'عملية التحقق قيد التنفيذ بالفعل.';

  @override
  String get sessionExpired => 'انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا.';

  @override
  String get tooManyRequests =>
      'محاولات كثيرة جدًا. يرجى الانتظار قبل المحاولة مرة أخرى.';

  @override
  String get networkRequestFailed => 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';

  @override
  String get operationNotAllowed =>
      'تسجيل الدخول برقم الهاتف غير مفعّل لهذا المشروع في Firebase.';

  @override
  String get unauthorizedDomain =>
      'هذا النطاق غير مصرح له باستخدام تسجيل الدخول برقم الهاتف في Firebase.';

  @override
  String get captchaCheckFailed => 'فشل التحقق من reCAPTCHA. حاول مرة أخرى.';

  @override
  String get firebaseNotInitialized =>
      'لم يتم تهيئة Firebase. أعد تشغيل التطبيق.';

  @override
  String get unsupportedPlatform =>
      'التحقق برقم الهاتف غير مدعوم على هذه المنصة.';

  @override
  String get sendCodeFailed => 'تعذر إرسال رمز التحقق. حاول مرة أخرى.';

  @override
  String get verifyCodeFailed => 'تعذر التحقق من الرمز. حاول مرة أخرى.';

  @override
  String get requestNewCode => 'اطلب رمز تحقق جديدًا وحاول مرة أخرى.';

  @override
  String get logoutFailed => 'تعذر تسجيل الخروج. حاول مرة أخرى.';

  @override
  String get genericAuthError => 'فشلت المصادقة. حاول مرة أخرى.';

  @override
  String get name => 'Name';
}
