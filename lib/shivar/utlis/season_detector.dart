class SeasonDetector {
  static String getCurrentSeason() {
    final month = DateTime.now().month; // 1-12

    // Northern Hemisphere seasons
    if (month >= 3 && month <= 5) {
      return 'Spring';
    } else if (month >= 6 && month <= 8) {
      return 'Summer';
    } else if (month >= 9 && month <= 11) {
      return 'Autumn';
    } else {
      return 'Winter';
    }
  }

  static String getSeasonForLocation(double latitude) {
    // If in Southern Hemisphere (negative latitude), invert seasons
    final isSouthern = latitude < 0;
    final month = DateTime.now().month;

    if (isSouthern) {
      if (month >= 3 && month <= 5) {
        return 'Autumn';
      } else if (month >= 6 && month <= 8) {
        return 'Winter';
      } else if (month >= 9 && month <= 11) {
        return 'Spring';
      } else {
        return 'Summer';
      }
    } else {
      return getCurrentSeason();
    }
  }
}

