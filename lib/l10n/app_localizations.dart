import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'JALNETRA'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Smart River Water Level Monitoring'**
  String get tagline;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @roleSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role to Login'**
  String get roleSelectionTitle;

  /// No description provided for @proceedToLogin.
  ///
  /// In en, this message translates to:
  /// **'PROCEED TO LOGIN'**
  String get proceedToLogin;

  /// No description provided for @fieldOfficerLogin.
  ///
  /// In en, this message translates to:
  /// **'Field Officer Login'**
  String get fieldOfficerLogin;

  /// No description provided for @supervisorLogin.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Login'**
  String get supervisorLogin;

  /// No description provided for @analystLogin.
  ///
  /// In en, this message translates to:
  /// **'Analyst Login'**
  String get analystLogin;

  /// No description provided for @adminLogin.
  ///
  /// In en, this message translates to:
  /// **'Administrator Login'**
  String get adminLogin;

  /// No description provided for @emailOrUserId.
  ///
  /// In en, this message translates to:
  /// **'Email or User ID'**
  String get emailOrUserId;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get signupQuestion;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials or user not found. Please try again.'**
  String get invalidCredentials;

  /// No description provided for @roleMismatch.
  ///
  /// In en, this message translates to:
  /// **'Role Mismatch'**
  String get roleMismatch;

  /// No description provided for @roleMismatchMsg.
  ///
  /// In en, this message translates to:
  /// **'The logged-in user\'s role does not match the selected role.'**
  String get roleMismatchMsg;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @fieldOfficerRegistration.
  ///
  /// In en, this message translates to:
  /// **'Field Officer Registration'**
  String get fieldOfficerRegistration;

  /// No description provided for @supervisorRegistration.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Registration'**
  String get supervisorRegistration;

  /// No description provided for @analystRegistration.
  ///
  /// In en, this message translates to:
  /// **'Analyst Registration'**
  String get analystRegistration;

  /// No description provided for @adminRegistration.
  ///
  /// In en, this message translates to:
  /// **'Administrator Registration'**
  String get adminRegistration;

  /// No description provided for @registrationDetails.
  ///
  /// In en, this message translates to:
  /// **'Registration Details for {role} Role'**
  String registrationDetails(Object role);

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @officialEmail.
  ///
  /// In en, this message translates to:
  /// **'Official Email'**
  String get officialEmail;

  /// No description provided for @passwordMin.
  ///
  /// In en, this message translates to:
  /// **'Password (min 6 chars)'**
  String get passwordMin;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @designation.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get designation;

  /// No description provided for @adminCode.
  ///
  /// In en, this message translates to:
  /// **'Admin Authorization Code'**
  String get adminCode;

  /// No description provided for @registerAccount.
  ///
  /// In en, this message translates to:
  /// **'Register Account'**
  String get registerAccount;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Back to Login'**
  String get backToLogin;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful'**
  String get registrationSuccessful;

  /// No description provided for @accountCreatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your account for the {role} role has been created. Please log in.'**
  String accountCreatedMsg(Object role);

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration Failed'**
  String get registrationFailed;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please use the Login screen.'**
  String get emailInUse;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak. Choose a stronger one.'**
  String get weakPassword;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unexpectedError;

  /// No description provided for @authorizationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authorization Failed'**
  String get authorizationFailed;

  /// No description provided for @invalidAdminCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid Admin Code. Registration requires a valid authorization key.'**
  String get invalidAdminCode;

  /// No description provided for @dashboardTitleOfficer.
  ///
  /// In en, this message translates to:
  /// **'Field Personnel Dashboard'**
  String get dashboardTitleOfficer;

  /// No description provided for @dashboardTitleAnalyst.
  ///
  /// In en, this message translates to:
  /// **'JALNETRA - Analytics'**
  String get dashboardTitleAnalyst;

  /// No description provided for @dashboardTitleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get dashboardTitleAdmin;

  /// No description provided for @checkWeather.
  ///
  /// In en, this message translates to:
  /// **'Check Weather'**
  String get checkWeather;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location Unavailable. Check GPS/Permissions.'**
  String get locationUnavailable;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in.'**
  String get userNotLoggedIn;

  /// No description provided for @profileFetchError.
  ///
  /// In en, this message translates to:
  /// **'Error fetching user data:'**
  String get profileFetchError;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editFeaturePending.
  ///
  /// In en, this message translates to:
  /// **'Profile edit feature coming soon.'**
  String get editFeaturePending;

  /// No description provided for @fetchingWeather.
  ///
  /// In en, this message translates to:
  /// **'Fetching live weather data...'**
  String get fetchingWeather;

  /// No description provided for @mapPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Live Geo-Tracking Placeholder'**
  String get mapPlaceholder;

  /// No description provided for @mapPlaceholderSub.
  ///
  /// In en, this message translates to:
  /// **'Showing current location and geofence for readings.'**
  String get mapPlaceholderSub;

  /// No description provided for @captureReading.
  ///
  /// In en, this message translates to:
  /// **'Capture Reading'**
  String get captureReading;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @getLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Get Live Location'**
  String get getLiveLocation;

  /// No description provided for @gpsFound.
  ///
  /// In en, this message translates to:
  /// **'GPS Found'**
  String get gpsFound;

  /// No description provided for @awaitingGps.
  ///
  /// In en, this message translates to:
  /// **'Awaiting GPS Fix...'**
  String get awaitingGps;

  /// No description provided for @proceedToQrScan.
  ///
  /// In en, this message translates to:
  /// **'Proceed to QR Scan'**
  String get proceedToQrScan;

  /// No description provided for @retryGps.
  ///
  /// In en, this message translates to:
  /// **'Retry GPS'**
  String get retryGps;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan Site QR Code'**
  String get scanQrCode;

  /// No description provided for @scanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Scan the physical QR label on the gauge post.'**
  String get scanInstruction;

  /// No description provided for @startQrScanner.
  ///
  /// In en, this message translates to:
  /// **'Start QR Scanner'**
  String get startQrScanner;

  /// No description provided for @validatingPosition.
  ///
  /// In en, this message translates to:
  /// **'Validating position...'**
  String get validatingPosition;

  /// No description provided for @geofencePassed.
  ///
  /// In en, this message translates to:
  /// **'Geofence Passed'**
  String get geofencePassed;

  /// No description provided for @geofenceFailed.
  ///
  /// In en, this message translates to:
  /// **'Geofence Failed'**
  String get geofenceFailed;

  /// No description provided for @distanceToSite.
  ///
  /// In en, this message translates to:
  /// **'Distance to Site'**
  String get distanceToSite;

  /// No description provided for @proceedToCapture.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Capture'**
  String get proceedToCapture;

  /// No description provided for @backAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Back & Retry'**
  String get backAndRetry;

  /// No description provided for @launchingCamera.
  ///
  /// In en, this message translates to:
  /// **'Launching Camera'**
  String get launchingCamera;

  /// No description provided for @prepareCamera.
  ///
  /// In en, this message translates to:
  /// **'Launching Camera for Gauge Capture...'**
  String get prepareCamera;

  /// No description provided for @logReading.
  ///
  /// In en, this message translates to:
  /// **'Log Reading'**
  String get logReading;

  /// No description provided for @imagePreview.
  ///
  /// In en, this message translates to:
  /// **'Captured Image Preview'**
  String get imagePreview;

  /// No description provided for @waterLevel.
  ///
  /// In en, this message translates to:
  /// **'Water Level'**
  String get waterLevel;

  /// No description provided for @levelRequired.
  ///
  /// In en, this message translates to:
  /// **'Water level is required'**
  String get levelRequired;

  /// No description provided for @submitAndEncrypt.
  ///
  /// In en, this message translates to:
  /// **'Submit Reading & Encrypt'**
  String get submitAndEncrypt;

  /// No description provided for @readingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Reading submitted successfully!'**
  String get readingSubmitted;

  /// No description provided for @submissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed. Error:'**
  String get submissionFailed;

  /// No description provided for @missingData.
  ///
  /// In en, this message translates to:
  /// **'Missing data.'**
  String get missingData;

  /// No description provided for @photoCancelled.
  ///
  /// In en, this message translates to:
  /// **'Photo capture cancelled. Please retry.'**
  String get photoCancelled;

  /// No description provided for @qrCancelled.
  ///
  /// In en, this message translates to:
  /// **'QR scanning cancelled. Returning to GPS.'**
  String get qrCancelled;

  /// No description provided for @qrProcessingFailed.
  ///
  /// In en, this message translates to:
  /// **'QR processing failed.'**
  String get qrProcessingFailed;

  /// No description provided for @gpsError.
  ///
  /// In en, this message translates to:
  /// **'Location check failed. Enable GPS & retry.'**
  String get gpsError;

  /// No description provided for @speechNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available.'**
  String get speechNotAvailable;

  /// No description provided for @voiceLevelDetected.
  ///
  /// In en, this message translates to:
  /// **'Level set via voice:'**
  String get voiceLevelDetected;

  /// No description provided for @voiceInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Voice input not recognized.'**
  String get voiceInvalidInput;

  /// No description provided for @speechRecognizing.
  ///
  /// In en, this message translates to:
  /// **'Recognizing'**
  String get speechRecognizing;

  /// No description provided for @qrScanner.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get qrScanner;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan the site QR code.'**
  String get cameraPermissionRequired;

  /// No description provided for @retryPermission.
  ///
  /// In en, this message translates to:
  /// **'Retry Permission'**
  String get retryPermission;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get openSettings;

  /// No description provided for @cameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied. Cannot scan QR.'**
  String get cameraDenied;

  /// No description provided for @cameraPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission permanently denied. Enable it in Settings.'**
  String get cameraPermanentlyDenied;

  /// No description provided for @currentSiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Site'**
  String get currentSiteLabel;

  /// No description provided for @publicUserLogin.
  ///
  /// In en, this message translates to:
  /// **'People Login'**
  String get publicUserLogin;

  /// No description provided for @publicUserRegistration.
  ///
  /// In en, this message translates to:
  /// **'People Registration'**
  String get publicUserRegistration;

  /// No description provided for @publicUserDashboard.
  ///
  /// In en, this message translates to:
  /// **'People Dashboard'**
  String get publicUserDashboard;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @sosAlert.
  ///
  /// In en, this message translates to:
  /// **'Send SOS Alert'**
  String get sosAlert;

  /// No description provided for @sosMessagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Describe your emergency situation briefly.'**
  String get sosMessagePrompt;

  /// No description provided for @yourEmail.
  ///
  /// In en, this message translates to:
  /// **'Your registered email'**
  String get yourEmail;

  /// No description provided for @sendSos.
  ///
  /// In en, this message translates to:
  /// **'Send Alert'**
  String get sendSos;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @sosSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'🚨 SOS alert sent successfully! Help is on the way.'**
  String get sosSentSuccess;

  /// No description provided for @sosSentFailure.
  ///
  /// In en, this message translates to:
  /// **'SOS alert failed to send. Check your connection.'**
  String get sosSentFailure;

  /// No description provided for @sosDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Emergency detected. Requester needs assistance.'**
  String get sosDefaultMessage;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @loginRequiredForSos.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to send an SOS alert.'**
  String get loginRequiredForSos;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not Logged In'**
  String get notLoggedIn;

  /// No description provided for @dlSuccess.
  ///
  /// In en, this message translates to:
  /// **' DL Model Success: Auto reading generated.'**
  String get dlSuccess;

  /// No description provided for @dlFailed.
  ///
  /// In en, this message translates to:
  /// **'DL Model Failed: Could not parse image result.'**
  String get dlFailed;

  /// No description provided for @dlApiError.
  ///
  /// In en, this message translates to:
  /// **' DL API Error: Status Code'**
  String get dlApiError;

  /// No description provided for @dlProcessingError.
  ///
  /// In en, this message translates to:
  /// **'DL Processing Exception: Check connection.'**
  String get dlProcessingError;

  /// No description provided for @autoWaterLevel.
  ///
  /// In en, this message translates to:
  /// **'Automatic Water Level (DL Model)'**
  String get autoWaterLevel;

  /// No description provided for @manualWaterLevel.
  ///
  /// In en, this message translates to:
  /// **'Manual Water Level Entry'**
  String get manualWaterLevel;

  /// No description provided for @processingImage.
  ///
  /// In en, this message translates to:
  /// **'Processing image...'**
  String get processingImage;

  /// No description provided for @awaitingDl.
  ///
  /// In en, this message translates to:
  /// **'Awaiting DL Model result...'**
  String get awaitingDl;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'ta': return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
