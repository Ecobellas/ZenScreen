/// Defines premium features and free tier limits (MNTZ-01, MNTZ-02).
enum PremiumFeature {
  unlimitedApps,
  allFrictionTypes,
  strictMode,
  fullJournal,
  detailedReports,
  csvExport,
  multipleProfiles,
}

/// Free tier limits (MNTZ-01).
class FreeTierLimits {
  FreeTierLimits._();

  static const int maxApps = 5;
  static const int maxProfiles = 1;
  static const int journalDays = 7;

  /// Free tier only gets the wait timer friction type (index 0).
  static const int frictionTypeWaitIndex = 0;
}
