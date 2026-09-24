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
  String get noPhone => 'لا يوجد هاتف';

  @override
  String get noAddress => 'لا يوجد عنوان';

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

  @override
  String get ownerDashboard => 'لوحة تحكم المالك';

  @override
  String get accessDenied => 'تم رفض الوصول.';

  @override
  String get shopLoadError => 'تعذر تحميل متجرك';

  @override
  String get createShopTitle => 'أنشئ محل الحلاقة الخاص بك';

  @override
  String get createShopSubtitle =>
      'أعدّ ملف متجرك حتى يتمكن العملاء من اكتشاف خدماتك وحجزها.';

  @override
  String get createShop => 'إنشاء المتجر';

  @override
  String get yourShop => 'متجرك';

  @override
  String get editShopDetails => 'تعديل بيانات المتجر';

  @override
  String get todaysOverview => 'ملخص اليوم';

  @override
  String get todaysBookings => 'حجوزات اليوم';

  @override
  String get pendingApproval => 'بانتظار الموافقة';

  @override
  String get totalBarbers => 'إجمالي الحلاقين';

  @override
  String get totalServices => 'إجمالي الخدمات';

  @override
  String get manageTeam => 'إدارة الفريق';

  @override
  String get barbersDescription =>
      'أضف الحلاقين إلى متجرك وأدر جداولهم الأسبوعية.';

  @override
  String get manageBarbers => 'إدارة الحلاقين';

  @override
  String get servicesDescription => 'أنشئ الخدمات مع الأسعار والمدد.';

  @override
  String get manageServices => 'إدارة الخدمات';

  @override
  String get manageBookings => 'إدارة الحجوزات';

  @override
  String get manageWeeklyHours =>
      'إدارة ساعات العمل الأسبوعية والاستراحات والإجازات';

  @override
  String get refresh => 'تحديث';

  @override
  String get barbers => 'الحلاقون';

  @override
  String get noBarbersYet => 'لا يوجد حلاقون بعد';

  @override
  String get addFirstBarber => 'أضف أول حلاق للبدء.';

  @override
  String get addBarber => 'إضافة حلاق';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get manageSchedule => 'إدارة الجدول';

  @override
  String get deleteBarberTitle => 'حذف الحلاق؟';

  @override
  String deleteBarberMessage(String name) {
    return 'حذف $name؟ سيتم إلغاء تفعيله وإزالته من قائمة الحلاقين النشطين.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get editBarber => 'تعديل حلاق';

  @override
  String get barberNameRequired => 'اسم الحلاق مطلوب.';

  @override
  String get phone => 'الهاتف';

  @override
  String get save => 'حفظ';

  @override
  String get callBarber => 'اتصال';

  @override
  String get messageBarber => 'مراسلة';

  @override
  String get callFailed => 'تعذر إجراء المكالمة.';

  @override
  String get deleteServiceTitle => 'حذف الخدمة؟';

  @override
  String deleteServiceMessage(String name) {
    return 'حذف $name؟';
  }

  @override
  String get addService => 'إضافة خدمة';

  @override
  String get editService => 'تعديل الخدمة';

  @override
  String get description => 'الوصف';

  @override
  String get durationMinutes => 'المدة (بالدقائق)';

  @override
  String get noServicesYet => 'لا توجد خدمات بعد';

  @override
  String get addFirstService => 'أضف أول خدمة للبدء.';

  @override
  String get serviceNameRequired => 'اسم الخدمة مطلوب.';

  @override
  String get invalidDuration => 'يجب أن تكون المدة مضاعفًا موجبًا للرقم 5.';

  @override
  String get invalidPrice => 'يجب أن يكون السعر صفرًا أو أكبر.';

  @override
  String get shopBookings => 'حجوزات المتجر';

  @override
  String get confirmAction => 'تأكيد';

  @override
  String get rejectCancelAction => 'رفض / إلغاء';

  @override
  String get completeAction => 'إتمام';

  @override
  String get markNoShowAction => 'تسجيل عدم الحضور';

  @override
  String get schedule => 'الجدول';

  @override
  String scheduleForBarber(String name) {
    return 'جدول - $name';
  }

  @override
  String get scheduleExceptions => 'استثناءات الجدول';

  @override
  String get scheduleSaved => 'تم حفظ الجدول بنجاح.';

  @override
  String get open => 'مفتوح';

  @override
  String get closed => 'مغلق';

  @override
  String get workingDay => 'يوم عمل';

  @override
  String get dayOff => 'يوم إجازة';

  @override
  String get scheduleStart => 'البداية';

  @override
  String get scheduleEnd => 'النهاية';

  @override
  String get breaks => 'الاستراحات';

  @override
  String get addBreak => 'إضافة استراحة';

  @override
  String get noBreaks => 'لا توجد استراحات';

  @override
  String get removeBreak => 'إزالة الاستراحة';

  @override
  String get selectStartTime => 'اختر وقت البداية';

  @override
  String get selectEndTime => 'اختر وقت النهاية';

  @override
  String get saveSchedule => 'حفظ الجدول';

  @override
  String get monday => 'الاثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String timeOffForBarber(String name) {
    return 'الإجازات - $name';
  }

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get loadingExceptions => 'جارٍ تحميل الاستثناءات...';

  @override
  String get noExceptionsThisMonth => 'لا توجد استثناءات لهذا الشهر';

  @override
  String get addException => 'إضافة استثناء للجدول';

  @override
  String get working => 'يعمل';

  @override
  String get editException => 'تعديل الاستثناء';

  @override
  String get deleteException => 'حذف الاستثناء';

  @override
  String get deleteExceptionTitle => 'حذف الاستثناء؟';

  @override
  String get deleteExceptionMessage => 'حذف هذا الاستثناء؟';

  @override
  String get addExceptionTitle => 'إضافة استثناء';

  @override
  String get editExceptionTitle => 'تعديل الاستثناء';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get exceptionStartTime => 'وقت البداية';

  @override
  String get exceptionEndTime => 'وقت النهاية';

  @override
  String get reason => 'السبب';

  @override
  String get reasonHint => 'سبب اختياري لهذا الاستثناء';

  @override
  String get saveException => 'حفظ الاستثناء';

  @override
  String get updateException => 'تحديث الاستثناء';

  @override
  String get endTimeAfterStartTime =>
      'يجب أن يكون وقت النهاية بعد وقت البداية.';

  @override
  String get ownerNavDashboard => 'لوحة التحكم';

  @override
  String get ownerNavSchedule => 'الجدول';

  @override
  String get pendingBookings => 'الحجوزات قيد الانتظار';

  @override
  String get completedBookings => 'الحجوزات المكتملة';

  @override
  String get cancelledBookings => 'الحجوزات الملغاة';

  @override
  String get revenue => 'الإيرادات';

  @override
  String get currency => 'جنيه';

  @override
  String get popularServices => 'الخدمات الأكثر طلبًا';

  @override
  String bookingsCount(int count) {
    return '$count حجز';
  }

  @override
  String get noBarbersForSchedule => 'لا يوجد حلاقون لإدارة جدولهم';

  @override
  String breaksCount(int count) {
    return '$count استراحات';
  }

  @override
  String get edit => 'تعديل';

  @override
  String get barberName => 'اسم الحلاق';

  @override
  String get selectBarber => 'اختر الحلاق';

  @override
  String get pleaseSelectBarber => 'يرجى اختيار حلاق.';

  @override
  String get barberCreatedSuccessfully => 'تم إنشاء الحلاق بنجاح.';

  @override
  String get noBarberUsersAvailable => 'لا يوجد مستخدمون متاحون كحلاقين.';
}
