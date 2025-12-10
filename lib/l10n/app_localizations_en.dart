// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'JALNETRA';

  @override
  String get tagline => 'Smart River Water Level Monitoring';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get roleSelectionTitle => 'Select Your Role to Login';

  @override
  String get proceedToLogin => 'PROCEED TO LOGIN';

  @override
  String get fieldOfficerLogin => 'Field Officer Login';

  @override
  String get supervisorLogin => 'Supervisor Login';

  @override
  String get analystLogin => 'Analyst Login';

  @override
  String get adminLogin => 'Administrator Login';

  @override
  String get emailOrUserId => 'Email or User ID';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get signupQuestion => 'Don\'t have an account? Sign Up';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get invalidCredentials => 'Invalid credentials or user not found. Please try again.';

  @override
  String get roleMismatch => 'Role Mismatch';

  @override
  String get roleMismatchMsg => 'The logged-in user\'s role does not match the selected role.';

  @override
  String get okay => 'Okay';

  @override
  String get fieldOfficerRegistration => 'Field Officer Registration';

  @override
  String get supervisorRegistration => 'Supervisor Registration';

  @override
  String get analystRegistration => 'Analyst Registration';

  @override
  String get adminRegistration => 'Administrator Registration';

  @override
  String registrationDetails(Object role) {
    return 'Registration Details for $role Role';
  }

  @override
  String get fullName => 'Full Name';

  @override
  String get officialEmail => 'Official Email';

  @override
  String get passwordMin => 'Password (min 6 chars)';

  @override
  String get employeeId => 'Employee ID';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get department => 'Department';

  @override
  String get designation => 'Designation';

  @override
  String get adminCode => 'Admin Authorization Code';

  @override
  String get registerAccount => 'Register Account';

  @override
  String get backToLogin => 'Already have an account? Back to Login';

  @override
  String get registrationSuccessful => 'Registration Successful';

  @override
  String accountCreatedMsg(Object role) {
    return 'Your account for the $role role has been created. Please log in.';
  }

  @override
  String get registrationFailed => 'Registration Failed';

  @override
  String get emailInUse => 'This email is already registered. Please use the Login screen.';

  @override
  String get weakPassword => 'The password is too weak. Choose a stronger one.';

  @override
  String get unexpectedError => 'An unexpected error occurred. Please try again.';

  @override
  String get authorizationFailed => 'Authorization Failed';

  @override
  String get invalidAdminCode => 'Invalid Admin Code. Registration requires a valid authorization key.';

  @override
  String get dashboardTitleOfficer => 'Field Personnel Dashboard';

  @override
  String get dashboardTitleAnalyst => 'JALNETRA - Analytics';

  @override
  String get dashboardTitleAdmin => 'Admin Dashboard';

  @override
  String get checkWeather => 'Check Weather';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get logout => 'Logout';

  @override
  String get locationUnavailable => 'Location Unavailable. Check GPS/Permissions.';

  @override
  String get profile => 'Profile';

  @override
  String get userNotLoggedIn => 'User not logged in.';

  @override
  String get profileFetchError => 'Error fetching user data:';

  @override
  String get userProfile => 'User Profile';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editFeaturePending => 'Profile edit feature coming soon.';

  @override
  String get fetchingWeather => 'Fetching live weather data...';

  @override
  String get mapPlaceholder => 'Live Geo-Tracking Placeholder';

  @override
  String get mapPlaceholderSub => 'Showing current location and geofence for readings.';

  @override
  String get captureReading => 'Capture Reading';

  @override
  String get step => 'Step';

  @override
  String get getLiveLocation => 'Get Live Location';

  @override
  String get gpsFound => 'GPS Found';

  @override
  String get awaitingGps => 'Awaiting GPS Fix...';

  @override
  String get proceedToQrScan => 'Proceed to QR Scan';

  @override
  String get retryGps => 'Retry GPS';

  @override
  String get scanQrCode => 'Scan Site QR Code';

  @override
  String get scanInstruction => 'Scan the physical QR label on the gauge post.';

  @override
  String get startQrScanner => 'Start QR Scanner';

  @override
  String get validatingPosition => 'Validating position...';

  @override
  String get geofencePassed => 'Geofence Passed';

  @override
  String get geofenceFailed => 'Geofence Failed';

  @override
  String get distanceToSite => 'Distance to Site';

  @override
  String get proceedToCapture => 'Proceed to Capture';

  @override
  String get backAndRetry => 'Back & Retry';

  @override
  String get launchingCamera => 'Launching Camera';

  @override
  String get prepareCamera => 'Launching Camera for Gauge Capture...';

  @override
  String get logReading => 'Log Reading';

  @override
  String get imagePreview => 'Captured Image Preview';

  @override
  String get waterLevel => 'Water Level';

  @override
  String get levelRequired => 'Water level is required';

  @override
  String get submitAndEncrypt => 'Submit Reading & Encrypt';

  @override
  String get readingSubmitted => 'Reading submitted successfully!';

  @override
  String get submissionFailed => 'Submission failed. Error:';

  @override
  String get missingData => 'Missing data.';

  @override
  String get photoCancelled => 'Photo capture cancelled. Please retry.';

  @override
  String get qrCancelled => 'QR scanning cancelled. Returning to GPS.';

  @override
  String get qrProcessingFailed => 'QR processing failed.';

  @override
  String get gpsError => 'Location check failed. Enable GPS & retry.';

  @override
  String get speechNotAvailable => 'Speech recognition not available.';

  @override
  String get voiceLevelDetected => 'Level set via voice:';

  @override
  String get voiceInvalidInput => 'Voice input not recognized.';

  @override
  String get speechRecognizing => 'Recognizing';

  @override
  String get qrScanner => 'QR Scanner';

  @override
  String get cameraPermissionRequired => 'Camera permission is required to scan the site QR code.';

  @override
  String get retryPermission => 'Retry Permission';

  @override
  String get openSettings => 'Open App Settings';

  @override
  String get cameraDenied => 'Camera permission denied. Cannot scan QR.';

  @override
  String get cameraPermanentlyDenied => 'Camera permission permanently denied. Enable it in Settings.';

  @override
  String get currentSiteLabel => 'Current Site';

  @override
  String get publicUserLogin => 'People Login';

  @override
  String get publicUserRegistration => 'People Registration';

  @override
  String get publicUserDashboard => 'People Dashboard';

  @override
  String get sos => 'SOS';

  @override
  String get sosAlert => 'Send SOS Alert';

  @override
  String get sosMessagePrompt => 'Describe your emergency situation briefly.';

  @override
  String get yourEmail => 'Your registered email';

  @override
  String get sendSos => 'Send Alert';

  @override
  String get cancel => 'Cancel';

  @override
  String get sosSentSuccess => '🚨 SOS alert sent successfully! Help is on the way.';

  @override
  String get sosSentFailure => 'SOS alert failed to send. Check your connection.';

  @override
  String get sosDefaultMessage => 'Emergency detected. Requester needs assistance.';

  @override
  String get message => 'Message';

  @override
  String get loginRequiredForSos => 'You must be logged in to send an SOS alert.';

  @override
  String get notLoggedIn => 'Not Logged In';

  @override
  String get dlSuccess => ' DL Model Success: Auto reading generated.';

  @override
  String get dlFailed => 'DL Model Failed: Could not parse image result.';

  @override
  String get dlApiError => ' DL API Error: Status Code';

  @override
  String get dlProcessingError => 'DL Processing Exception: Check connection.';

  @override
  String get autoWaterLevel => 'Automatic Water Level (DL Model)';

  @override
  String get manualWaterLevel => 'Manual Water Level Entry';

  @override
  String get processingImage => 'Processing image...';

  @override
  String get awaitingDl => 'Awaiting DL Model result...';

  @override
  String get liveTitle => 'Live Validation';

  @override
  String get liveInitMessage => 'Initializing camera...';

  @override
  String get liveInitVoice => 'Initializing camera. Please wait.';

  @override
  String get liveNoCamera => 'No camera found on this device.';

  @override
  String get liveCameraError => 'Error initializing camera. Please go back and try again.';

  @override
  String get liveChecking => 'Checking...';

  @override
  String get liveAimAtGauge => 'Aim at the gauge...';

  @override
  String get liveCameraReadyVoice => 'Camera ready. Please aim at the water level gauge and hold your phone steady.';

  @override
  String get liveGaugeNotFound => 'Gauge Not Found';

  @override
  String get liveFrameError => 'Unable to validate frame. Please try again.';

  @override
  String get liveGaugeNotDetectedAim => 'Gauge not detected. Aim at the gauge and hold steady.';

  @override
  String get liveTooFarOverlay => 'Move Closer';

  @override
  String get liveTooFarBottom => 'Gauge detected, but you are too far. Please move closer.';

  @override
  String get liveReadyOverlay => 'Gauge Found - Capture Enabled';

  @override
  String get liveReadyBottom => 'Gauge detected. Hold steady and press the capture button.';

  @override
  String get liveNetworkError => 'Network error during validation.';

  @override
  String get liveCaptureSuccess => 'Image captured successfully.';

  @override
  String get liveCaptureError => 'There was an error capturing the image. Please try again.';
}
