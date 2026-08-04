class AppConstants {
  static const String appName = "DailyEarn CM";
  static const String appVersion = "1.0.0";

  // Récompenses
  static const double dailyCheckinBonus = 25;
  static const double referralBonus = 50;

  // Retraits
  static const double minWithdrawalAmount = 500;
  static const List<String> withdrawalMethods = [
    "MTN Mobile Money",
    "Orange Money"
  ];

  // Parrainage
  static const String referralPrefix = "EL";

  // Niveaux utilisateur
  static const Map<String, int> userLevels = {
    "Bronze": 0,
    "Silver": 10,
    "Gold": 25,
    "Platinum": 50,
    "Diamond": 100,
  };
}

