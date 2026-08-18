enum SharedPreferenceKey {
  steamUserId('steamUserId'),
  languageCode('languageCode'),
  recentSearches('recentSearches'),
  isDarkMode('isDarkMode'),
  bottomNavIndex('bottomNavIndex'),
  isFirstTimeUser('isFirstTimeUser'),
  userEmailAddress('userEmailAddress'),
  userPassword('userPassword'),
  biometricsEnabled('biometricsEnabled'),
  ;

  const SharedPreferenceKey(this.value);

  final String value;
}
