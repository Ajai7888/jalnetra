// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'जलनेत्र';

  @override
  String get tagline => 'स्मार्ट नदी जल स्तर निगरानी';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get roleSelectionTitle => 'लॉगिन के लिए अपनी भूमिका चुनें';

  @override
  String get proceedToLogin => 'लॉगिन जारी रखें';

  @override
  String get fieldOfficerLogin => 'फील्ड अधिकारी लॉगिन';

  @override
  String get supervisorLogin => 'पर्यवेक्षक लॉगिन';

  @override
  String get analystLogin => 'विश्लेषक लॉगिन';

  @override
  String get adminLogin => 'प्रशासक लॉगिन';

  @override
  String get emailOrUserId => 'ईमेल या यूज़र आईडी';

  @override
  String get password => 'पासवर्ड';

  @override
  String get login => 'लॉगिन';

  @override
  String get signupQuestion => 'खाता नहीं है? साइन अप करें';

  @override
  String get loginFailed => 'लॉगिन असफल';

  @override
  String get invalidCredentials => 'अमान्य जानकारी। कृपया फिर से प्रयास करें।';

  @override
  String get roleMismatch => 'भूमिका मेल नहीं खाती';

  @override
  String get roleMismatchMsg => 'लॉगिन की गई भूमिका चयनित भूमिका से मेल नहीं खाती।';

  @override
  String get okay => 'ठीक है';

  @override
  String get fieldOfficerRegistration => 'फील्ड अधिकारी पंजीकरण';

  @override
  String get supervisorRegistration => 'पर्यवेक्षक पंजीकरण';

  @override
  String get analystRegistration => 'विश्लेषक पंजीकरण';

  @override
  String get adminRegistration => 'प्रशासक पंजीकरण';

  @override
  String registrationDetails(Object role) {
    return '$role भूमिका के लिए पंजीकरण विवरण';
  }

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get officialEmail => 'आधिकारिक ईमेल';

  @override
  String get passwordMin => 'पासवर्ड (कम से कम 6 अक्षर)';

  @override
  String get employeeId => 'कर्मचारी आईडी';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get department => 'विभाग';

  @override
  String get designation => 'पदनाम';

  @override
  String get adminCode => 'एडमिन प्रमाणीकरण कोड';

  @override
  String get registerAccount => 'खाता पंजीकृत करें';

  @override
  String get backToLogin => 'पहले से खाता है? लॉगिन पर वापस जाएं';

  @override
  String get registrationSuccessful => 'पंजीकरण सफल';

  @override
  String accountCreatedMsg(Object role) {
    return '$role भूमिका के लिए आपका खाता बन गया है। कृपया लॉगिन करें।';
  }

  @override
  String get registrationFailed => 'पंजीकरण असफल';

  @override
  String get emailInUse => 'यह ईमेल पहले से पंजीकृत है।';

  @override
  String get weakPassword => 'पासवर्ड बहुत कमजोर है।';

  @override
  String get unexpectedError => 'कुछ त्रुटि हुई। कृपया पुनः प्रयास करें।';

  @override
  String get authorizationFailed => 'प्रमाणीकरण असफल';

  @override
  String get invalidAdminCode => 'अमान्य एडमिन कोड — पंजीकरण के लिए वैध कोड आवश्यक।';

  @override
  String get dashboardTitleOfficer => 'फील्ड कर्मचारी डैशबोर्ड';

  @override
  String get dashboardTitleAnalyst => 'जलनेत्र - विश्लेषण';

  @override
  String get dashboardTitleAdmin => 'एडमिन डैशबोर्ड';

  @override
  String get checkWeather => 'मौसम देखें';

  @override
  String get viewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get locationUnavailable => 'स्थान उपलब्ध नहीं — GPS/अनुमतियाँ जाँचें।';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get userNotLoggedIn => 'यूज़र लॉगिन नहीं है।';

  @override
  String get profileFetchError => 'प्रोफ़ाइल लोड करने में त्रुटि:';

  @override
  String get userProfile => 'यूज़र प्रोफ़ाइल';

  @override
  String get email => 'ईमेल';

  @override
  String get phone => 'फ़ोन';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get editFeaturePending => 'प्रोफ़ाइल संपादन सुविधा जल्द आ रही है।';

  @override
  String get fetchingWeather => 'लाइव मौसम डेटा प्राप्त किया जा रहा है...';

  @override
  String get mapPlaceholder => 'लाइव जियो ट्रैकिंग';

  @override
  String get mapPlaceholderSub => 'वर्तमान लोकेशन और जियोज़ोन प्रदर्शित किया जा रहा है।';

  @override
  String get captureReading => 'पठन रिकॉर्ड करें';

  @override
  String get step => 'चरण';

  @override
  String get getLiveLocation => 'लाइव स्थान प्राप्त करें';

  @override
  String get gpsFound => 'GPS मिला';

  @override
  String get awaitingGps => 'GPS सिग्नल की प्रतीक्षा...';

  @override
  String get proceedToQrScan => 'QR स्कैन पर जारी रखें';

  @override
  String get retryGps => 'GPS पुनः प्रयास';

  @override
  String get scanQrCode => 'साइट QR कोड स्कैन करें';

  @override
  String get scanInstruction => 'गेज पोल पर लगे QR लेबल को स्कैन करें।';

  @override
  String get startQrScanner => 'QR स्कैनर प्रारंभ करें';

  @override
  String get validatingPosition => 'स्थान सत्यापित किया जा रहा है...';

  @override
  String get geofencePassed => 'जियोफेंस सफल';

  @override
  String get geofenceFailed => 'जियोफेंस असफल';

  @override
  String get distanceToSite => 'साइट तक की दूरी';

  @override
  String get proceedToCapture => 'कैप्चर करने के लिए आगे बढ़ें';

  @override
  String get backAndRetry => 'वापस जाएं और पुनः प्रयास करें';

  @override
  String get launchingCamera => 'कैमरा चालू किया जा रहा है';

  @override
  String get prepareCamera => 'गेज कैप्चर के लिए कैमरा तैयार किया जा रहा है...';

  @override
  String get logReading => 'पठन दर्ज करें';

  @override
  String get imagePreview => 'क्लिक की गई छवि पूर्वावलोकन';

  @override
  String get waterLevel => 'जल स्तर';

  @override
  String get levelRequired => 'जल स्तर आवश्यक है';

  @override
  String get submitAndEncrypt => 'सबमिट करें और एन्क्रिप्ट करें';

  @override
  String get readingSubmitted => 'पठन सफलतापूर्वक जमा किया गया!';

  @override
  String get submissionFailed => 'सबमिट असफल — त्रुटि:';

  @override
  String get missingData => 'डेटा अनुपलब्ध है।';

  @override
  String get photoCancelled => 'फोटो रद्द किया गया — पुनः प्रयास करें।';

  @override
  String get qrCancelled => 'QR स्कैन रद्द — GPS पर लौट रहा है।';

  @override
  String get qrProcessingFailed => 'QR प्रक्रिया विफल।';

  @override
  String get gpsError => 'GPS त्रुटि — अनुमति सक्षम कर पुनः प्रयास करें।';

  @override
  String get speechNotAvailable => 'वॉइस रिकग्निशन उपलब्ध नहीं।';

  @override
  String get voiceLevelDetected => 'वॉइस द्वारा स्तर दर्ज:';

  @override
  String get voiceInvalidInput => 'वॉइस इनपुट पहचाना नहीं गया।';

  @override
  String get speechRecognizing => 'पहचाना जा रहा है...';

  @override
  String get qrScanner => 'QR स्कैनर';

  @override
  String get cameraPermissionRequired => 'QR स्कैन करने के लिए कैमरा अनुमति आवश्यक है।';

  @override
  String get retryPermission => 'अनुमति पुनः प्रयास';

  @override
  String get openSettings => 'ऐप सेटिंग्स खोलें';

  @override
  String get cameraDenied => 'कैमरा अनुमति अस्वीकृत।';

  @override
  String get cameraPermanentlyDenied => 'अनुमति स्थायी रूप से अस्वीकृत — सेटिंग्स में सक्षम करें।';

  @override
  String get currentSiteLabel => 'वर्तमान साइट';

  @override
  String get publicUserLogin => 'जनता लॉगिन';

  @override
  String get publicUserRegistration => 'जनता पंजीकरण';

  @override
  String get publicUserDashboard => 'जनता डैशबोर्ड';

  @override
  String get sos => 'SOS';

  @override
  String get sosAlert => 'SOS अलर्ट भेजें';

  @override
  String get sosMessagePrompt => 'अपनी आपात स्थिति का संक्षिप्त विवरण दें।';

  @override
  String get yourEmail => 'आपका पंजीकृत ईमेल';

  @override
  String get sendSos => 'अलर्ट भेजें';

  @override
  String get cancel => 'रद्द';

  @override
  String get sosSentSuccess => '🚨 SOS अलर्ट सफलतापूर्वक भेजा गया! सहायता रास्ते में है।';

  @override
  String get sosSentFailure => 'SOS भेजने में विफल — इंटरनेट जांचें।';

  @override
  String get sosDefaultMessage => 'आपात स्थिति का पता चला — सहायता चाहिए।';

  @override
  String get message => 'संदेश';

  @override
  String get loginRequiredForSos => 'SOS अलर्ट भेजने के लिए आपको लॉग इन होना आवश्यक है।';

  @override
  String get notLoggedIn => 'लॉग इन नहीं किया गया';

  @override
  String get dlSuccess => 'DL मॉडल सफल: स्वतः रीडिंग उत्पन्न की गई।';

  @override
  String get dlFailed => 'DL मॉडल असफल: छवि परिणाम को पढ़ा नहीं जा सका।';

  @override
  String get dlApiError => ' DL API त्रुटि: स्टेटस कोड';

  @override
  String get dlProcessingError => 'DL प्रोसेसिंग त्रुटि: कनेक्शन जांचें।';

  @override
  String get autoWaterLevel => 'स्वचालित जल स्तर (DL मॉडल)';

  @override
  String get manualWaterLevel => 'मैन्युअल जल स्तर प्रविष्टि';

  @override
  String get processingImage => 'छवि संसाधित हो रही है...';

  @override
  String get awaitingDl => 'DL मॉडल परिणाम की प्रतीक्षा...';
}
