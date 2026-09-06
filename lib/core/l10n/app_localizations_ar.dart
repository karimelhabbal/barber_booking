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
  String get phoneNumber => 'رقم الجوال';

  @override
  String get sendCode => 'ارسال الكود';

  @override
  String get otpSentTo => 'تم ارسال الكود الى';

  @override
  String get otpCode => 'رمز التحقق';

  @override
  String get confirm => 'تأكيد';

  @override
  String get verifyCode => 'تحقق من الرمز';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get welcomeBarberSaas => 'اهلا بيك في Barber SaaS';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get invalidName => 'الاسم غير صحيح';

  @override
  String get invalidPhoneNumber => 'رقم الهاتف غير صحيح';

  @override
  String get invalidVerificationCode => 'رمز التحقق غير صحيح';

  @override
  String get verificationInProgress => 'جاري التحقق...';

  @override
  String get sessionExpired => 'انتهت صلاحية الرمز، اطلب رمزًا جديدًا';

  @override
  String get tooManyRequests =>
      'محاولات كثيرة، يرجى الانتظار قبل المحاولة مرة أخرى';

  @override
  String get networkRequestFailed => 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى';

  @override
  String get operationNotAllowed =>
      'تسجيل الدخول بالهاتف غير مفعّل لهذا المشروع';

  @override
  String get unauthorizedDomain =>
      'هذا النطاق غير مصرح له بتسجيل الدخول بالهاتف';

  @override
  String get captchaCheckFailed => 'فشل التحقق من reCAPTCHA، حاول مرة أخرى';

  @override
  String get firebaseNotInitialized => 'Firebase غير مهيأ، أعد تشغيل التطبيق';

  @override
  String get unsupportedPlatform => 'التحقق بالهاتف غير مدعوم على هذه المنصة';

  @override
  String get sendCodeFailed => 'تعذر إرسال الرمز، حاول مرة أخرى';

  @override
  String get verifyCodeFailed => 'تعذر التحقق من الرمز، حاول مرة أخرى';

  @override
  String get requestNewCode => 'اطلب رمز تحقق جديد وحاول مرة أخرى';

  @override
  String get logoutFailed => 'تعذر تسجيل الخروج، حاول مرة أخرى';

  @override
  String get genericAuthError => 'حدث خطأ في المصادقة، حاول مرة أخرى';

  @override
  String get name => 'الاسم';
}
