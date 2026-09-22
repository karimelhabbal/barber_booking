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
  String get bookNow => 'Book Appointment';

  @override
  String get dashboard => 'Home';

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
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get otpSentTo => 'تم إرسال الرمز إلى';

  @override
  String get otpCode => 'رمز التحقق';

  @override
  String get confirm => 'Confirm appointment';

  @override
  String get verifyCode => 'تأكيد الرمز';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get welcomeBarberSaas => 'أهلًا بك في Barber SaaS';

  @override
  String get logout => 'Logout';

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

  @override
  String get noBarberShopsAvailable => 'No active shops right now';

  @override
  String get customerDashboard => 'Customer Dashboard';

  @override
  String get bookings => 'Bookings';

  @override
  String get loadingDashboard => 'Loading your dashboard...';

  @override
  String get loadingHome => 'Loading your home...';

  @override
  String get dashboardLoadError => 'Unable to load your dashboard';

  @override
  String get availableBarbersLater =>
      'Please check back later for available barbers.';

  @override
  String get upcomingAppointment => 'Upcoming Appointment';

  @override
  String get noUpcomingAppointment => 'No upcoming appointment';

  @override
  String get nextBookingMessage => 'Your next booking will appear here.';

  @override
  String get barberSelection => 'Barber Selection';

  @override
  String get services => 'Services';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get customer => 'Customer';

  @override
  String get minutes => 'min';

  @override
  String get hour => 'hour';

  @override
  String get hours => 'hours';

  @override
  String get hourShort => 'h';

  @override
  String get pending => 'Pending';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get noShow => 'No show';

  @override
  String get loadingBarbers => 'Loading barbers...';

  @override
  String get loadingServices => 'Loading services...';

  @override
  String get loadBarbersError => 'Unable to load barbers.';

  @override
  String get noActiveBarbers => 'No active barbers';

  @override
  String get noBarbersMessage =>
      'There are no barbers available for this shop right now.';

  @override
  String get loadServicesError => 'Unable to load services.';

  @override
  String get noServicesAvailable => 'No services available';

  @override
  String get noServicesMessage =>
      'This shop is not offering any active services right now.';

  @override
  String get noBarbersCurrentlyAvailable =>
      'No barbers are currently available.';

  @override
  String get customerProfileIncomplete =>
      'Your customer profile is incomplete.';

  @override
  String get showAvailableSlots => 'Show available slots';

  @override
  String get noAvailableSlots => 'No available slots for this date.';

  @override
  String get confirmAppointment => 'Confirm appointment';

  @override
  String get at => 'at';

  @override
  String get creating => 'Creating...';

  @override
  String get confirmBooking => 'Confirm booking';

  @override
  String get bookingCreated => 'Booking created successfully.';

  @override
  String get noServicesCurrentlyAvailable =>
      'No services are currently available.';

  @override
  String get cancelBookingQuestion => 'Cancel booking?';

  @override
  String get bookingCancelledMessage => 'This booking will be cancelled.';

  @override
  String get keep => 'Keep';

  @override
  String get cancel => 'Cancel';

  @override
  String get myBookings => 'My bookings';

  @override
  String get loadingBookings => 'Loading bookings...';

  @override
  String get loadBookingsError => 'Unable to load bookings.';

  @override
  String get noBookingsYet => 'No bookings yet.';

  @override
  String get bookingsEmptyMessage =>
      'Your upcoming and past bookings will appear here.';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get noUpcomingBookings => 'No upcoming bookings.';

  @override
  String get noUpcomingAppointments =>
      'There are no upcoming appointments right now.';

  @override
  String get history => 'History';

  @override
  String get noBookingHistory => 'No booking history.';

  @override
  String get pastAppointments => 'Past appointments will appear here.';

  @override
  String get barber => 'Barber';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get price => 'Price';

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get retry => 'Retry';
}
