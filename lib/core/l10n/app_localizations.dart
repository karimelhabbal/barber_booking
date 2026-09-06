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
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'إنشاء حساب'**
  String get register;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'احجز الآن'**
  String get bookNow;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'الرئيسية'**
  String get dashboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'المظهر'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'فاتح'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'داكن'**
  String get dark;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneNumber;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'إرسال الرمز'**
  String get sendCode;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'تم إرسال الرمز إلى'**
  String get otpSentTo;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'رمز التحقق'**
  String get otpCode;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'تأكيد الرمز'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'إعادة إرسال الرمز'**
  String get resendCode;

  /// No description provided for @welcomeBarberSaas.
  ///
  /// In en, this message translates to:
  /// **'أهلًا بك في Barber SaaS'**
  String get welcomeBarberSaas;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'أدخل اسمك.'**
  String get invalidName;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'أدخل رقم هاتف صحيح.'**
  String get invalidPhoneNumber;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'رمز التحقق غير صحيح.'**
  String get invalidVerificationCode;

  /// No description provided for @verificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'عملية التحقق قيد التنفيذ بالفعل.'**
  String get verificationInProgress;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا.'**
  String get sessionExpired;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'محاولات كثيرة جدًا. يرجى الانتظار قبل المحاولة مرة أخرى.'**
  String get tooManyRequests;

  /// No description provided for @networkRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.'**
  String get networkRequestFailed;

  /// No description provided for @operationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'تسجيل الدخول برقم الهاتف غير مفعّل لهذا المشروع في Firebase.'**
  String get operationNotAllowed;

  /// No description provided for @unauthorizedDomain.
  ///
  /// In en, this message translates to:
  /// **'هذا النطاق غير مصرح له باستخدام تسجيل الدخول برقم الهاتف في Firebase.'**
  String get unauthorizedDomain;

  /// No description provided for @captchaCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'فشل التحقق من reCAPTCHA. حاول مرة أخرى.'**
  String get captchaCheckFailed;

  /// No description provided for @firebaseNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'لم يتم تهيئة Firebase. أعد تشغيل التطبيق.'**
  String get firebaseNotInitialized;

  /// No description provided for @unsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'التحقق برقم الهاتف غير مدعوم على هذه المنصة.'**
  String get unsupportedPlatform;

  /// No description provided for @sendCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'تعذر إرسال رمز التحقق. حاول مرة أخرى.'**
  String get sendCodeFailed;

  /// No description provided for @verifyCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'تعذر التحقق من الرمز. حاول مرة أخرى.'**
  String get verifyCodeFailed;

  /// No description provided for @requestNewCode.
  ///
  /// In en, this message translates to:
  /// **'اطلب رمز تحقق جديدًا وحاول مرة أخرى.'**
  String get requestNewCode;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'تعذر تسجيل الخروج. حاول مرة أخرى.'**
  String get logoutFailed;

  /// No description provided for @genericAuthError.
  ///
  /// In en, this message translates to:
  /// **'فشلت المصادقة. حاول مرة أخرى.'**
  String get genericAuthError;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;
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
