import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Barber Booking'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get register;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookNow;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dashboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to'**
  String get otpSentTo;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get otpCode;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @welcomeBarberSaas.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Barber SaaS'**
  String get welcomeBarberSaas;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get invalidName;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get invalidPhoneNumber;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code.'**
  String get invalidVerificationCode;

  /// No description provided for @verificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Verification is already in progress.'**
  String get verificationInProgress;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'The verification code has expired. Please request a new code.'**
  String get sessionExpired;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait before trying again.'**
  String get tooManyRequests;

  /// No description provided for @networkRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get networkRequestFailed;

  /// No description provided for @operationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Phone sign-in is not enabled for this project in Firebase.'**
  String get operationNotAllowed;

  /// No description provided for @unauthorizedDomain.
  ///
  /// In en, this message translates to:
  /// **'This domain is not authorized to use phone sign-in in Firebase.'**
  String get unauthorizedDomain;

  /// No description provided for @captchaCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'reCAPTCHA verification failed. Please try again.'**
  String get captchaCheckFailed;

  /// No description provided for @firebaseNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Firebase has not been initialized. Restart the app.'**
  String get firebaseNotInitialized;

  /// No description provided for @unsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Phone verification is not supported on this platform.'**
  String get unsupportedPlatform;

  /// No description provided for @sendCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the verification code. Please try again.'**
  String get sendCodeFailed;

  /// No description provided for @verifyCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify the code. Please try again.'**
  String get verifyCodeFailed;

  /// No description provided for @requestNewCode.
  ///
  /// In en, this message translates to:
  /// **'Request a new verification code and try again.'**
  String get requestNewCode;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to log out. Please try again.'**
  String get logoutFailed;

  /// No description provided for @genericAuthError.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get genericAuthError;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @noBarberShopsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No active shops right now'**
  String get noBarberShopsAvailable;

  /// No description provided for @customerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Customer Dashboard'**
  String get customerDashboard;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading your dashboard...'**
  String get loadingDashboard;

  /// No description provided for @loadingHome.
  ///
  /// In en, this message translates to:
  /// **'Loading your home...'**
  String get loadingHome;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your dashboard'**
  String get dashboardLoadError;

  /// No description provided for @availableBarbersLater.
  ///
  /// In en, this message translates to:
  /// **'Please check back later for available barbers.'**
  String get availableBarbersLater;

  /// No description provided for @upcomingAppointment.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointment'**
  String get upcomingAppointment;

  /// No description provided for @noUpcomingAppointment.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointment'**
  String get noUpcomingAppointment;

  /// No description provided for @nextBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your next booking will appear here.'**
  String get nextBookingMessage;

  /// No description provided for @barberSelection.
  ///
  /// In en, this message translates to:
  /// **'Barber Selection'**
  String get barberSelection;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @hourShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourShort;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @noShow.
  ///
  /// In en, this message translates to:
  /// **'No show'**
  String get noShow;

  /// No description provided for @loadingBarbers.
  ///
  /// In en, this message translates to:
  /// **'Loading barbers...'**
  String get loadingBarbers;

  /// No description provided for @loadingServices.
  ///
  /// In en, this message translates to:
  /// **'Loading services...'**
  String get loadingServices;

  /// No description provided for @loadBarbersError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load barbers.'**
  String get loadBarbersError;

  /// No description provided for @noActiveBarbers.
  ///
  /// In en, this message translates to:
  /// **'No active barbers'**
  String get noActiveBarbers;

  /// No description provided for @noBarbersMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no barbers available for this shop right now.'**
  String get noBarbersMessage;

  /// No description provided for @loadServicesError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load services.'**
  String get loadServicesError;

  /// No description provided for @noServicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No services available'**
  String get noServicesAvailable;

  /// No description provided for @noServicesMessage.
  ///
  /// In en, this message translates to:
  /// **'This shop is not offering any active services right now.'**
  String get noServicesMessage;

  /// No description provided for @noBarbersCurrentlyAvailable.
  ///
  /// In en, this message translates to:
  /// **'No barbers are currently available.'**
  String get noBarbersCurrentlyAvailable;

  /// No description provided for @customerProfileIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Your customer profile is incomplete.'**
  String get customerProfileIncomplete;

  /// No description provided for @showAvailableSlots.
  ///
  /// In en, this message translates to:
  /// **'Show available slots'**
  String get showAvailableSlots;

  /// No description provided for @noAvailableSlots.
  ///
  /// In en, this message translates to:
  /// **'No available slots for this date.'**
  String get noAvailableSlots;

  /// No description provided for @confirmAppointment.
  ///
  /// In en, this message translates to:
  /// **'Confirm appointment'**
  String get confirmAppointment;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// No description provided for @bookingCreated.
  ///
  /// In en, this message translates to:
  /// **'Booking created successfully.'**
  String get bookingCreated;

  /// No description provided for @noServicesCurrentlyAvailable.
  ///
  /// In en, this message translates to:
  /// **'No services are currently available.'**
  String get noServicesCurrentlyAvailable;

  /// No description provided for @cancelBookingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking?'**
  String get cancelBookingQuestion;

  /// No description provided for @bookingCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'This booking will be cancelled.'**
  String get bookingCancelledMessage;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get myBookings;

  /// No description provided for @loadingBookings.
  ///
  /// In en, this message translates to:
  /// **'Loading bookings...'**
  String get loadingBookings;

  /// No description provided for @loadBookingsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load bookings.'**
  String get loadBookingsError;

  /// No description provided for @noBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet.'**
  String get noBookingsYet;

  /// No description provided for @bookingsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your upcoming and past bookings will appear here.'**
  String get bookingsEmptyMessage;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @noUpcomingBookings.
  ///
  /// In en, this message translates to:
  /// **'No upcoming bookings.'**
  String get noUpcomingBookings;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'There are no upcoming appointments right now.'**
  String get noUpcomingAppointments;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noBookingHistory.
  ///
  /// In en, this message translates to:
  /// **'No booking history.'**
  String get noBookingHistory;

  /// No description provided for @pastAppointments.
  ///
  /// In en, this message translates to:
  /// **'Past appointments will appear here.'**
  String get pastAppointments;

  /// No description provided for @barber.
  ///
  /// In en, this message translates to:
  /// **'Barber'**
  String get barber;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get noPhone;

  /// No description provided for @noAddress.
  ///
  /// In en, this message translates to:
  /// **'No address'**
  String get noAddress;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @ownerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Owner Dashboard'**
  String get ownerDashboard;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied.'**
  String get accessDenied;

  /// No description provided for @shopLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your shop'**
  String get shopLoadError;

  /// No description provided for @createShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your barber shop'**
  String get createShopTitle;

  /// No description provided for @createShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your shop profile so customers can discover and book your services.'**
  String get createShopSubtitle;

  /// No description provided for @createShop.
  ///
  /// In en, this message translates to:
  /// **'Create shop'**
  String get createShop;

  /// No description provided for @yourShop.
  ///
  /// In en, this message translates to:
  /// **'Your shop'**
  String get yourShop;

  /// No description provided for @editShopDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit shop details'**
  String get editShopDetails;

  /// No description provided for @todaysOverview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s overview'**
  String get todaysOverview;

  /// No description provided for @todaysBookings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s bookings'**
  String get todaysBookings;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get pendingApproval;

  /// No description provided for @totalBarbers.
  ///
  /// In en, this message translates to:
  /// **'Total barbers'**
  String get totalBarbers;

  /// No description provided for @totalServices.
  ///
  /// In en, this message translates to:
  /// **'Total services'**
  String get totalServices;

  /// No description provided for @manageTeam.
  ///
  /// In en, this message translates to:
  /// **'Manage your team'**
  String get manageTeam;

  /// No description provided for @barbersDescription.
  ///
  /// In en, this message translates to:
  /// **'Add barbers to your shop and manage their weekly schedules.'**
  String get barbersDescription;

  /// No description provided for @manageBarbers.
  ///
  /// In en, this message translates to:
  /// **'Manage barbers'**
  String get manageBarbers;

  /// No description provided for @servicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Create service offerings with pricing and durations.'**
  String get servicesDescription;

  /// No description provided for @manageServices.
  ///
  /// In en, this message translates to:
  /// **'Manage services'**
  String get manageServices;

  /// No description provided for @manageBookings.
  ///
  /// In en, this message translates to:
  /// **'Manage bookings'**
  String get manageBookings;

  /// No description provided for @manageWeeklyHours.
  ///
  /// In en, this message translates to:
  /// **'Manage weekly hours, breaks and time off'**
  String get manageWeeklyHours;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @barbers.
  ///
  /// In en, this message translates to:
  /// **'Barbers'**
  String get barbers;

  /// No description provided for @noBarbersYet.
  ///
  /// In en, this message translates to:
  /// **'No barbers yet'**
  String get noBarbersYet;

  /// No description provided for @addFirstBarber.
  ///
  /// In en, this message translates to:
  /// **'Add your first barber to get started.'**
  String get addFirstBarber;

  /// No description provided for @addBarber.
  ///
  /// In en, this message translates to:
  /// **'Add barber'**
  String get addBarber;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @manageSchedule.
  ///
  /// In en, this message translates to:
  /// **'Manage schedule'**
  String get manageSchedule;

  /// No description provided for @deleteBarberTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete barber?'**
  String get deleteBarberTitle;

  /// No description provided for @deleteBarberMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? They will be deactivated and removed from the active barbers list.'**
  String deleteBarberMessage(String name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @editBarber.
  ///
  /// In en, this message translates to:
  /// **'Edit barber'**
  String get editBarber;

  /// No description provided for @barberNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Barber name is required.'**
  String get barberNameRequired;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @callBarber.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callBarber;

  /// No description provided for @messageBarber.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageBarber;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not place the call.'**
  String get callFailed;

  /// No description provided for @deleteServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete service?'**
  String get deleteServiceTitle;

  /// No description provided for @deleteServiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteServiceMessage(String name);

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add service'**
  String get addService;

  /// No description provided for @editService.
  ///
  /// In en, this message translates to:
  /// **'Edit service'**
  String get editService;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationMinutes;

  /// No description provided for @noServicesYet.
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get noServicesYet;

  /// No description provided for @addFirstService.
  ///
  /// In en, this message translates to:
  /// **'Add your first service to get started.'**
  String get addFirstService;

  /// No description provided for @serviceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Service name is required.'**
  String get serviceNameRequired;

  /// No description provided for @invalidDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration must be a positive multiple of 5.'**
  String get invalidDuration;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Price must be zero or greater.'**
  String get invalidPrice;

  /// No description provided for @shopBookings.
  ///
  /// In en, this message translates to:
  /// **'Shop bookings'**
  String get shopBookings;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @rejectCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Reject / cancel'**
  String get rejectCancelAction;

  /// No description provided for @completeAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeAction;

  /// No description provided for @markNoShowAction.
  ///
  /// In en, this message translates to:
  /// **'Mark no-show'**
  String get markNoShowAction;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @scheduleForBarber.
  ///
  /// In en, this message translates to:
  /// **'Schedule - {name}'**
  String scheduleForBarber(String name);

  /// No description provided for @scheduleExceptions.
  ///
  /// In en, this message translates to:
  /// **'Schedule Exceptions'**
  String get scheduleExceptions;

  /// No description provided for @scheduleSaved.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved successfully.'**
  String get scheduleSaved;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @workingDay.
  ///
  /// In en, this message translates to:
  /// **'Working day'**
  String get workingDay;

  /// No description provided for @dayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get dayOff;

  /// No description provided for @scheduleStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get scheduleStart;

  /// No description provided for @scheduleEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get scheduleEnd;

  /// No description provided for @breaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get breaks;

  /// No description provided for @addBreak.
  ///
  /// In en, this message translates to:
  /// **'Add Break'**
  String get addBreak;

  /// No description provided for @noBreaks.
  ///
  /// In en, this message translates to:
  /// **'No breaks'**
  String get noBreaks;

  /// No description provided for @removeBreak.
  ///
  /// In en, this message translates to:
  /// **'Remove break'**
  String get removeBreak;

  /// No description provided for @selectStartTime.
  ///
  /// In en, this message translates to:
  /// **'Select start time'**
  String get selectStartTime;

  /// No description provided for @selectEndTime.
  ///
  /// In en, this message translates to:
  /// **'Select end time'**
  String get selectEndTime;

  /// No description provided for @saveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Save schedule'**
  String get saveSchedule;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @timeOffForBarber.
  ///
  /// In en, this message translates to:
  /// **'Time off - {name}'**
  String timeOffForBarber(String name);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @loadingExceptions.
  ///
  /// In en, this message translates to:
  /// **'Loading exceptions...'**
  String get loadingExceptions;

  /// No description provided for @noExceptionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No exceptions for this month'**
  String get noExceptionsThisMonth;

  /// No description provided for @addException.
  ///
  /// In en, this message translates to:
  /// **'Add schedule exception'**
  String get addException;

  /// No description provided for @working.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get working;

  /// No description provided for @editException.
  ///
  /// In en, this message translates to:
  /// **'Edit exception'**
  String get editException;

  /// No description provided for @deleteException.
  ///
  /// In en, this message translates to:
  /// **'Delete exception'**
  String get deleteException;

  /// No description provided for @deleteExceptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete exception?'**
  String get deleteExceptionTitle;

  /// No description provided for @deleteExceptionMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this exception?'**
  String get deleteExceptionMessage;

  /// No description provided for @addExceptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add exception'**
  String get addExceptionTitle;

  /// No description provided for @editExceptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit exception'**
  String get editExceptionTitle;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @exceptionStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get exceptionStartTime;

  /// No description provided for @exceptionEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get exceptionEndTime;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @reasonHint.
  ///
  /// In en, this message translates to:
  /// **'Optional reason for this exception'**
  String get reasonHint;

  /// No description provided for @saveException.
  ///
  /// In en, this message translates to:
  /// **'Save Exception'**
  String get saveException;

  /// No description provided for @updateException.
  ///
  /// In en, this message translates to:
  /// **'Update Exception'**
  String get updateException;

  /// No description provided for @endTimeAfterStartTime.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time.'**
  String get endTimeAfterStartTime;

  /// No description provided for @ownerNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get ownerNavDashboard;

  /// No description provided for @ownerNavSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get ownerNavSchedule;

  /// No description provided for @pendingBookings.
  ///
  /// In en, this message translates to:
  /// **'Pending bookings'**
  String get pendingBookings;

  /// No description provided for @completedBookings.
  ///
  /// In en, this message translates to:
  /// **'Completed bookings'**
  String get completedBookings;

  /// No description provided for @cancelledBookings.
  ///
  /// In en, this message translates to:
  /// **'Cancelled bookings'**
  String get cancelledBookings;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get currency;

  /// No description provided for @popularServices.
  ///
  /// In en, this message translates to:
  /// **'Popular services'**
  String get popularServices;

  /// No description provided for @bookingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bookings'**
  String bookingsCount(int count);

  /// No description provided for @noBarbersForSchedule.
  ///
  /// In en, this message translates to:
  /// **'No barbers available for scheduling'**
  String get noBarbersForSchedule;

  /// No description provided for @breaksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} breaks'**
  String breaksCount(int count);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @barberName.
  ///
  /// In en, this message translates to:
  /// **'Barber Name'**
  String get barberName;

  /// No description provided for @selectBarber.
  ///
  /// In en, this message translates to:
  /// **'Select Barber'**
  String get selectBarber;

  /// No description provided for @pleaseSelectBarber.
  ///
  /// In en, this message translates to:
  /// **'Please select a barber.'**
  String get pleaseSelectBarber;

  /// No description provided for @barberCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Barber created successfully.'**
  String get barberCreatedSuccessfully;

  /// No description provided for @noBarberUsersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No barber users are available.'**
  String get noBarberUsersAvailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
