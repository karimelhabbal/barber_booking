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
  String get theme => 'المظهر';

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

  @override
  String get noBarberShopsAvailable => 'لا توجد محلات حلاقة نشطة حاليًا';

  @override
  String get customerDashboard => 'لوحة تحكم العميل';

  @override
  String get bookings => 'الحجوزات';

  @override
  String get loadingDashboard => 'جارٍ تحميل لوحة التحكم...';

  @override
  String get loadingHome => 'جارٍ تحميل الصفحة الرئيسية...';

  @override
  String get dashboardLoadError => 'تعذر تحميل لوحة التحكم';

  @override
  String get availableBarbersLater =>
      'يرجى المحاولة لاحقًا لرؤية الحلاقين المتاحين.';

  @override
  String get upcomingAppointment => 'الموعد القادم';

  @override
  String get noUpcomingAppointment => 'لا يوجد موعد قادم';

  @override
  String get nextBookingMessage => 'سيظهر حجزك القادم هنا.';

  @override
  String get barberSelection => 'اختيار الحلاق';

  @override
  String get services => 'الخدمات';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String get customer => 'العميل';

  @override
  String get minutes => 'دقيقة';

  @override
  String get hour => 'ساعة';

  @override
  String get hours => 'ساعات';

  @override
  String get hourShort => 'س';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get confirmed => 'مؤكد';

  @override
  String get completed => 'مكتمل';

  @override
  String get cancelled => 'ملغى';

  @override
  String get noShow => 'لم يحضر';

  @override
  String get loadingBarbers => 'جارٍ تحميل الحلاقين...';

  @override
  String get loadingServices => 'جارٍ تحميل الخدمات...';

  @override
  String get loadBarbersError => 'تعذر تحميل الحلاقين.';

  @override
  String get noActiveBarbers => 'لا يوجد حلاقون نشطون';

  @override
  String get noBarbersMessage => 'لا يوجد حلاقون متاحون في هذا المحل حاليًا.';

  @override
  String get loadServicesError => 'تعذر تحميل الخدمات.';

  @override
  String get noServicesAvailable => 'لا توجد خدمات متاحة';

  @override
  String get noServicesMessage => 'لا يقدم هذا المحل أي خدمات نشطة حاليًا.';

  @override
  String get noBarbersCurrentlyAvailable => 'لا يوجد حلاقون متاحون حاليًا.';

  @override
  String get customerProfileIncomplete => 'بيانات ملف العميل غير مكتملة.';

  @override
  String get showAvailableSlots => 'عرض المواعيد المتاحة';

  @override
  String get noAvailableSlots => 'لا توجد مواعيد متاحة لهذا التاريخ.';

  @override
  String get confirmAppointment => 'تأكيد الموعد';

  @override
  String get at => 'في';

  @override
  String get creating => 'جارٍ الإنشاء...';

  @override
  String get confirmBooking => 'تأكيد الحجز';

  @override
  String get bookingCreated => 'تم إنشاء الحجز بنجاح.';

  @override
  String get noServicesCurrentlyAvailable => 'لا توجد خدمات متاحة حاليًا.';

  @override
  String get cancelBookingQuestion => 'إلغاء الحجز؟';

  @override
  String get bookingCancelledMessage => 'سيتم إلغاء هذا الحجز.';

  @override
  String get keep => 'احتفاظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get myBookings => 'حجوزاتي';

  @override
  String get loadingBookings => 'جارٍ تحميل الحجوزات...';

  @override
  String get loadBookingsError => 'تعذر تحميل الحجوزات.';

  @override
  String get noBookingsYet => 'لا توجد حجوزات بعد.';

  @override
  String get bookingsEmptyMessage => 'ستظهر حجوزاتك القادمة والسابقة هنا.';

  @override
  String get upcoming => 'القادمة';

  @override
  String get noUpcomingBookings => 'لا توجد حجوزات قادمة.';

  @override
  String get noUpcomingAppointments => 'لا توجد مواعيد قادمة حاليًا.';

  @override
  String get history => 'السجل';

  @override
  String get noBookingHistory => 'لا يوجد سجل حجوزات.';

  @override
  String get pastAppointments => 'ستظهر المواعيد السابقة هنا.';

  @override
  String get barber => 'الحلاق';

  @override
  String get date => 'التاريخ';

  @override
  String get time => 'الوقت';

  @override
  String get price => 'السعر';

  @override
  String get cancelBooking => 'إلغاء الحجز';

  @override
  String get retry => 'إعادة المحاولة';
}
