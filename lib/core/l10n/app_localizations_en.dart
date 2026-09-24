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
  String get register => 'Create Account';

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
  String get phoneNumber => 'Phone Number';

  @override
  String get sendCode => 'Send Code';

  @override
  String get otpSentTo => 'Code sent to';

  @override
  String get otpCode => 'Verification Code';

  @override
  String get confirm => 'Confirm';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get welcomeBarberSaas => 'Welcome to Barber SaaS';

  @override
  String get logout => 'Logout';

  @override
  String get invalidName => 'Please enter your name.';

  @override
  String get invalidPhoneNumber => 'Please enter a valid phone number.';

  @override
  String get invalidVerificationCode => 'Invalid verification code.';

  @override
  String get verificationInProgress => 'Verification is already in progress.';

  @override
  String get sessionExpired =>
      'The verification code has expired. Please request a new code.';

  @override
  String get tooManyRequests =>
      'Too many attempts. Please wait before trying again.';

  @override
  String get networkRequestFailed =>
      'Check your internet connection and try again.';

  @override
  String get operationNotAllowed =>
      'Phone sign-in is not enabled for this project in Firebase.';

  @override
  String get unauthorizedDomain =>
      'This domain is not authorized to use phone sign-in in Firebase.';

  @override
  String get captchaCheckFailed =>
      'reCAPTCHA verification failed. Please try again.';

  @override
  String get firebaseNotInitialized =>
      'Firebase has not been initialized. Restart the app.';

  @override
  String get unsupportedPlatform =>
      'Phone verification is not supported on this platform.';

  @override
  String get sendCodeFailed =>
      'Unable to send the verification code. Please try again.';

  @override
  String get verifyCodeFailed => 'Unable to verify the code. Please try again.';

  @override
  String get requestNewCode => 'Request a new verification code and try again.';

  @override
  String get logoutFailed => 'Unable to log out. Please try again.';

  @override
  String get genericAuthError => 'Authentication failed. Please try again.';

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
  String get noPhone => 'No phone';

  @override
  String get noAddress => 'No address';

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

  @override
  String get ownerDashboard => 'Owner Dashboard';

  @override
  String get accessDenied => 'Access denied.';

  @override
  String get shopLoadError => 'Could not load your shop';

  @override
  String get createShopTitle => 'Create your barber shop';

  @override
  String get createShopSubtitle =>
      'Set up your shop profile so customers can discover and book your services.';

  @override
  String get createShop => 'Create shop';

  @override
  String get yourShop => 'Your shop';

  @override
  String get editShopDetails => 'Edit shop details';

  @override
  String get todaysOverview => 'Today\'s overview';

  @override
  String get todaysBookings => 'Today\'s bookings';

  @override
  String get pendingApproval => 'Pending approval';

  @override
  String get totalBarbers => 'Total barbers';

  @override
  String get totalServices => 'Total services';

  @override
  String get manageTeam => 'Manage your team';

  @override
  String get barbersDescription =>
      'Add barbers to your shop and manage their weekly schedules.';

  @override
  String get manageBarbers => 'Manage barbers';

  @override
  String get servicesDescription =>
      'Create service offerings with pricing and durations.';

  @override
  String get manageServices => 'Manage services';

  @override
  String get manageBookings => 'Manage bookings';

  @override
  String get manageWeeklyHours => 'Manage weekly hours, breaks and time off';

  @override
  String get refresh => 'Refresh';

  @override
  String get barbers => 'Barbers';

  @override
  String get noBarbersYet => 'No barbers yet';

  @override
  String get addFirstBarber => 'Add your first barber to get started.';

  @override
  String get addBarber => 'Add barber';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get manageSchedule => 'Manage schedule';

  @override
  String get deleteBarberTitle => 'Delete barber?';

  @override
  String deleteBarberMessage(String name) {
    return 'Delete $name? They will be deactivated and removed from the active barbers list.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get editBarber => 'Edit barber';

  @override
  String get barberNameRequired => 'Barber name is required.';

  @override
  String get phone => 'Phone';

  @override
  String get save => 'Save';

  @override
  String get callBarber => 'Call';

  @override
  String get messageBarber => 'Message';

  @override
  String get callFailed => 'Could not place the call.';

  @override
  String get deleteServiceTitle => 'Delete service?';

  @override
  String deleteServiceMessage(String name) {
    return 'Delete $name?';
  }

  @override
  String get addService => 'Add service';

  @override
  String get editService => 'Edit service';

  @override
  String get description => 'Description';

  @override
  String get durationMinutes => 'Duration (minutes)';

  @override
  String get noServicesYet => 'No services yet';

  @override
  String get addFirstService => 'Add your first service to get started.';

  @override
  String get serviceNameRequired => 'Service name is required.';

  @override
  String get invalidDuration => 'Duration must be a positive multiple of 5.';

  @override
  String get invalidPrice => 'Price must be zero or greater.';

  @override
  String get shopBookings => 'Shop bookings';

  @override
  String get confirmAction => 'Confirm';

  @override
  String get rejectCancelAction => 'Reject / cancel';

  @override
  String get completeAction => 'Complete';

  @override
  String get markNoShowAction => 'Mark no-show';

  @override
  String get schedule => 'Schedule';

  @override
  String scheduleForBarber(String name) {
    return 'Schedule - $name';
  }

  @override
  String get scheduleExceptions => 'Schedule Exceptions';

  @override
  String get scheduleSaved => 'Schedule saved successfully.';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String get workingDay => 'Working day';

  @override
  String get dayOff => 'Day off';

  @override
  String get scheduleStart => 'Start';

  @override
  String get scheduleEnd => 'End';

  @override
  String get breaks => 'Breaks';

  @override
  String get addBreak => 'Add Break';

  @override
  String get noBreaks => 'No breaks';

  @override
  String get removeBreak => 'Remove break';

  @override
  String get selectStartTime => 'Select start time';

  @override
  String get selectEndTime => 'Select end time';

  @override
  String get saveSchedule => 'Save schedule';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String timeOffForBarber(String name) {
    return 'Time off - $name';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get loadingExceptions => 'Loading exceptions...';

  @override
  String get noExceptionsThisMonth => 'No exceptions for this month';

  @override
  String get addException => 'Add schedule exception';

  @override
  String get working => 'Working';

  @override
  String get editException => 'Edit exception';

  @override
  String get deleteException => 'Delete exception';

  @override
  String get deleteExceptionTitle => 'Delete exception?';

  @override
  String get deleteExceptionMessage => 'Delete this exception?';

  @override
  String get addExceptionTitle => 'Add exception';

  @override
  String get editExceptionTitle => 'Edit exception';

  @override
  String get selectDate => 'Select date';

  @override
  String get exceptionStartTime => 'Start time';

  @override
  String get exceptionEndTime => 'End time';

  @override
  String get reason => 'Reason';

  @override
  String get reasonHint => 'Optional reason for this exception';

  @override
  String get saveException => 'Save Exception';

  @override
  String get updateException => 'Update Exception';

  @override
  String get endTimeAfterStartTime => 'End time must be after start time.';

  @override
  String get ownerNavDashboard => 'Dashboard';

  @override
  String get ownerNavSchedule => 'Schedule';

  @override
  String get pendingBookings => 'Pending bookings';

  @override
  String get completedBookings => 'Completed bookings';

  @override
  String get cancelledBookings => 'Cancelled bookings';

  @override
  String get revenue => 'Revenue';

  @override
  String get currency => 'EGP';

  @override
  String get popularServices => 'Popular services';

  @override
  String bookingsCount(int count) {
    return '$count bookings';
  }

  @override
  String get noBarbersForSchedule => 'No barbers available for scheduling';

  @override
  String breaksCount(int count) {
    return '$count breaks';
  }

  @override
  String get edit => 'Edit';

  @override
  String get barberName => 'Barber Name';

  @override
  String get selectBarber => 'Select Barber';

  @override
  String get pleaseSelectBarber => 'Please select a barber.';

  @override
  String get barberCreatedSuccessfully => 'Barber created successfully.';

  @override
  String get noBarberUsersAvailable => 'No barber users are available.';
}
