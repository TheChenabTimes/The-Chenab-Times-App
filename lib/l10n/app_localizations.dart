import 'dart:async';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'home': 'Home',
      'donate': 'Donate',
      'saved': 'Saved',
      'more': 'More',
      'select_language': 'Select Your Language',
      'next': 'Next',
      'welcome_message': 'Welcome to The Chenab Times',
      'continue_as_new': 'Continue as a New User',
      'login_restore': 'Login or Restore from Backup',
      'terms_title': 'Terms & Conditions',
      'terms_agreement': 'I agree to the Terms of Service.',
      'age_agreement': 'I confirm that I am 13 years of age or older.',
      'proceed': 'Proceed',
    },
    'hi': {
      'home': 'होम',
      'donate': 'दान करें',
      'saved': 'सहेजे गए',
      'more': 'अधिक',
      'select_language': 'अपनी भाषा चुनें',
      'next': 'अगला',
      'welcome_message': 'चिनाब टाइम्स में आपका स्वागत है',
      'continue_as_new': 'एक नए उपयोगकर्ता के रूप में जारी रखें',
      'login_restore': 'लॉगिन या बैकअप से पुनर्स्थापित करें',
      'terms_title': 'नियम और शर्तें',
      'terms_agreement': 'मैं सेवा की शर्तों से सहमत हूं।',
      'age_agreement':
          'मैं पुष्टि करता हूं कि मेरी उम्र 13 वर्ष या उससे अधिक है।',
      'proceed': 'आगे बढ़ें',
    },
    'ur': {
      'home': 'گھر',
      'donate': 'عطیہ کریں',
      'saved': 'محفوظ کردہ',
      'more': 'مزید',
      'select_language': 'اپنی زبان منتخب کریں',
      'next': 'اگلا',
      'welcome_message': 'چناب ٹائمز میں خوش آمدید',
      'continue_as_new': 'ایک نئے صارف کے طور پر جاری رکھیں',
      'login_restore': 'لاگ ان یا بیک اپ سے بحال کریں',
      'terms_title': 'شرائط و ضوابط',
      'terms_agreement': 'میں سروس کی شرائط سے اتفاق کرتا ہوں۔',
      'age_agreement':
          'میں تصدیق کرتا ہوں کہ میری عمر 13 سال یا اس سے زیادہ ہے۔',
      'proceed': 'آگے بڑھیں',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]![key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'ur'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
