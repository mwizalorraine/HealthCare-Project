import 'package:flutter/widgets.dart';

class AppL10n {
  final Locale locale;
  const AppL10n(this.locale);

  static AppL10n of(BuildContext context) =>
      Localizations.of<AppL10n>(context, AppL10n)!;

  static const delegate = _AppL10nDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('rw'),
    Locale('sw'),
  ];

  String _t(String en, String fr, String rw, String sw) {
    switch (locale.languageCode) {
      case 'fr':
        return fr;
      case 'rw':
        return rw;
      case 'sw':
        return sw;
      default:
        return en;
    }
  }

  // ── App ───────────────────────────────────────────────────────────────────
  String get appName => 'RapidSave';
  String get tagline => _t('Medicine, delivered fast', 'Médicaments, livrés vite', 'Imiti iherekeza vuba', 'Dawa, zinawasilishwa haraka');

  // ── Navigation ───────────────────────────────────────────────────────────
  String get navHome => _t('Home', 'Accueil', 'Ahabanza', 'Nyumbani');
  String get navSearch => _t('Search', 'Rechercher', 'Shakisha', 'Tafuta');
  String get navPharmacies => _t('Pharmacies', 'Pharmacies', 'Amaduka', 'Maduka');
  String get navOrders => _t('Orders', 'Commandes', 'Amabwiriza', 'Maagizo');
  String get navProfile => _t('Profile', 'Profil', 'Umwirondoro', 'Wasifu');

  // ── Common ────────────────────────────────────────────────────────────────
  String get cancel => _t('Cancel', 'Annuler', 'Hagarika', 'Ghairi');
  String get confirm => _t('Confirm', 'Confirmer', 'Emeza', 'Thibitisha');
  String get save => _t('Save', 'Enregistrer', 'Bika', 'Hifadhi');
  String get close => _t('Close', 'Fermer', 'Funga', 'Funga');
  String get on => _t('On', 'Activé', 'Fungura', 'Washa');
  String get off => _t('Off', 'Désactivé', 'Funga', 'Zima');
  String get yes => _t('Yes', 'Oui', 'Yego', 'Ndiyo');
  String get no => _t('No', 'Non', 'Oya', 'Hapana');

  // ── Profile ───────────────────────────────────────────────────────────────
  String get myProfile => _t('My Profile', 'Mon Profil', 'Umwirondoro Wanjye', 'Wasifu Wangu');
  String get editProfile => _t('Edit Profile', 'Modifier Profil', 'Hindura Umwirondoro', 'Hariri Wasifu');
  String get verified => _t('Verified', 'Vérifié', 'Byemejwe', 'Imethibitishwa');
  String get unverified => _t('Unverified', 'Non Vérifié', 'Bitemewe', 'Haijathibitishwa');
  String get patient => _t('Patient', 'Patient', 'Umurwayi', 'Mgonjwa');
  String get pharmacyAdmin => _t('Pharmacy Admin', 'Admin Pharmacie', 'Umuyobozi w\'Duka', 'Msimamizi');
  String get adminRole => _t('Admin', 'Admin', 'Umuyobozi', 'Msimamizi Mkuu');

  // ── Profile sections ─────────────────────────────────────────────────────
  String get sectionAccount => _t('Account', 'Compte', 'Konti', 'Akaunti');
  String get sectionOrdersHistory => _t('Orders & History', 'Commandes & Historique', 'Amabwiriza & Amateka', 'Maagizo & Historia');
  String get sectionSecurity => _t('Security', 'Sécurité', 'Umutekano', 'Usalama');
  String get sectionAppSettings => _t('App Settings', 'Paramètres', 'Igenamiterere', 'Mipangilio');
  String get sectionSupport => _t('Support', 'Support', 'Inkunga', 'Msaada');

  String get personalInfo => _t('Personal Information', 'Informations Personnelles', 'Amakuru Bwite', 'Taarifa Binafsi');
  String get phoneNumber => _t('Phone Number', 'Numéro de Téléphone', 'Nimero ya Telefoni', 'Nambari ya Simu');
  String get myAddress => _t('My Address', 'Mon Adresse', 'Aderesi Yanjye', 'Anwani Yangu');
  String get myOrders => _t('My Orders', 'Mes Commandes', 'Amabwiriza Yanjye', 'Maagizo Yangu');
  String get savedPharmacies => _t('Saved Pharmacies', 'Pharmacies Sauvegardées', 'Amaduka Abitswe', 'Maduka Yaliyohifadhiwa');
  String get orderHistory => _t('Order History', 'Historique des Commandes', 'Amateka y\'Amabwiriza', 'Historia ya Maagizo');
  String get changePassword => _t('Change Password', 'Changer Mot de Passe', 'Hindura Ijambo Banga', 'Badilisha Nenosiri');
  String get notifications => _t('Notifications', 'Notifications', 'Amatangazo', 'Arifa');
  String get privacyPolicy => _t('Privacy Policy', 'Politique de Confidentialité', 'Amategeko y\'Ibanga', 'Sera ya Faragha');

  String get language => _t('Language', 'Langue', 'Ururimi', 'Lugha');
  String get darkMode => _t('Dark Mode', 'Mode Sombre', 'Uburyo bw\'Ijoro', 'Hali ya Giza');
  String get pushNotifications => _t('Push Notifications', 'Notifications Push', 'Amatangazo ya Telefoni', 'Arifa za Simu');
  String get locationServices => _t('Location Services', 'Services de Localisation', 'Serivisi z\'Aho uri', 'Huduma za Mahali');

  String get helpSupport => _t('Help & Support', 'Aide & Support', 'Ubufasha & Inkunga', 'Msaada wa Programu');
  String get rateApp => _t('Rate RapidSave', 'Évaluer RapidSave', 'Ongera Gusuzuma RapidSave', 'Kadiria Programu');
  String get aboutApp => _t('About RapidSave', 'À propos de RapidSave', 'Ibyerekeye RapidSave', 'Kuhusu RapidSave');

  String get signOut => _t('Sign Out', 'Déconnexion', 'Sohoka', 'Toka');
  String get signOutTitle => _t('Sign Out', 'Déconnexion', 'Sohoka', 'Toka');
  String get signOutMessage => _t(
    'Are you sure you want to sign out?',
    'Voulez-vous vraiment vous déconnecter?',
    'Urashaka gusohoka?',
    'Una uhakika unataka kutoka?',
  );

  // ── Language picker ───────────────────────────────────────────────────────
  String get selectLanguage => _t('Select Language', 'Choisir une Langue', 'Hitamo Ururimi', 'Chagua Lugha');
  String get english => 'English';
  String get french => 'Français';
  String get kinyarwanda => 'Kinyarwanda';
  String get kiswahili => 'Kiswahili';

  // ── Search ────────────────────────────────────────────────────────────────
  String get findMedicines => _t('Find Medicines', 'Trouver des Médicaments', 'Shakisha Imiti', 'Tafuta Dawa');
  String get searchHint => _t('Search medicine name...', 'Nom du médicament...', 'Shakisha izina ry\'umuti...', 'Tafuta jina la dawa...');
  String get medicinesNearYou => _t('medicines found near you', 'médicaments trouvés près de vous', 'imiti ibonetse hafi yawe', 'dawa karibu nawe');
  String get noMedicinesFound => _t('No medicines found', 'Aucun médicament trouvé', 'Nta muti ubonetse', 'Hakuna dawa zilizopatikana');
  String get recentSearches => _t('Recent Searches', 'Recherches Récentes', 'Gushakisha Vuba', 'Utafutaji wa Hivi Karibuni');
  String get clearAll => _t('Clear all', 'Tout effacer', 'Siba byose', 'Futa yote');
  String get inStock => _t('In Stock', 'En Stock', 'Iraboneka', 'Ipo');
  String get outOfStock => _t('Out of Stock', 'Rupture de Stock', 'Ntiraboneka', 'Haipatikani');
  String get find => _t('Find', 'Trouver', 'Shaka', 'Pata');
  String get notify => _t('Notify', 'Notifier', 'Menyesha', 'Niarifu');
  String get gpsActive => _t('GPS Active', 'GPS Actif', 'GPS Irakora', 'GPS Inafanya Kazi');
  String get noGps => _t('No GPS', 'Pas de GPS', 'Nta GPS', 'Hakuna GPS');

  // ── Delivery tracking ────────────────────────────────────────────────────
  String get trackDelivery => _t('Track Delivery', 'Suivre Livraison', 'Kurikirana Itanga', 'Fuatilia Utoaji');
  String get yourRider => _t('Your delivery rider', 'Votre livreur', 'Umutwara wawe', 'Mpeleka wako');
  String get estimatedArrival => _t('Estimated Arrival', 'Arrivée Estimée', 'Igihe cy\'Kugera', 'Wakati wa Kuwasili');
  String get deliveryAddress => _t('Delivery Address', 'Adresse de Livraison', 'Aderesi yo Gutangira', 'Anwani ya Utoaji');
  String get deliveryProgress => _t('Delivery Progress', 'Progression de Livraison', 'Aho Bigezeho', 'Maendeleo ya Utoaji');
  String get stepAssigned => _t('Order Assigned', 'Commande Assignée', 'Itegeko Ryahawe', 'Agizo Limepewa');
  String get stepAssignedSub => _t('Rider assigned to your order', 'Livreur assigné', 'Umutwara yahawe itegeko ryawe', 'Mpeleka amepewa agizo lako');
  String get stepPickedUp => _t('Picked Up', 'Récupéré', 'Byafashwe', 'Imechukuliwa');
  String get stepPickedUpSub => _t('Rider picked up your order', 'Livreur a récupéré', 'Umutwara yafashe itegeko ryawe', 'Mpeleka amechukua agizo');
  String get stepInTransit => _t('On The Way', 'En Route', 'Mu nzira', 'Njiani');
  String get stepInTransitSub => _t('Rider heading to your location', 'Livreur en route', 'Umutwara aragaruka', 'Mpeleka anakuja kwako');
  String get stepDelivered => _t('Delivered', 'Livré', 'Byashyikirijwe', 'Imetolewa');
  String get stepDeliveredSub => _t('Order delivered to your address', 'Livré à votre adresse', 'Itegeko ryashyikirijwe', 'Agizo limetolewa');
  String get riderLocation => _t('Driver Location', 'Position du Livreur', 'Aho Umutwara ari', 'Mahali pa Dereva');
  String get nowLabel => _t('Now', 'Maintenant', 'Ubu', 'Sasa');
  String get calculating => _t('Calculating...', 'Calcul...', 'Birararimbura...', 'Inakokotoa...');
  String get arrivingSoon => _t('Arriving soon', 'Arrive bientôt', 'Aragera vuba', 'Anafika hivi karibuni');
  String get trackingLive => _t('Tracking live', 'Suivi en direct', 'Gukurikirana', 'Inafuatiliwa');
  String get orderDelivered => _t('Order delivered', 'Commande livrée', 'Itegeko ryashyikirijwe', 'Agizo limetolewa');
  String get liveLabel => _t('LIVE', 'DIRECT', 'NZIZA', 'MOJA KWA MOJA');
  String get openInMaps => _t('Open in Maps', 'Ouvrir dans Maps', 'Fungura Ikarita', 'Fungua Ramani');
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr', 'rw', 'sw'].contains(locale.languageCode);

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}
