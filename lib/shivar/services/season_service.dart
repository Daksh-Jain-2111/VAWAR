/// Service responsible for mapping the current date to
/// Indian agricultural seasons: Kharif, Rabi, Zaid.
///
/// Rules (as per spec):
/// - June to October  → KHARIF
/// - October to March → RABI
/// - April to May     → ZAID
///
/// Because October and March appear in overlapping ranges,
/// ordering of checks matters. We prioritise:
///   1. June–October as KHARIF
///   2. Otherwise October–March as RABI
///   3. Otherwise April–May as ZAID
class SeasonService {
  const SeasonService();

  /// Returns one of: 'KHARIF', 'RABI', 'ZAID'.
  String detectSeason(DateTime now) {
    final int month = now.month; // 1–12

    // June (6) to October (10) inclusive → KHARIF
    if (month >= 6 && month <= 10) {
      return 'KHARIF';
    }

    // Otherwise October (10) to March (3) inclusive → RABI
    // Implemented as: month >= 10 (Oct–Dec) OR month <= 3 (Jan–Mar)
    if (month >= 10 || month <= 3) {
      return 'RABI';
    }

    // Remaining months: April (4) and May (5) → ZAID
    return 'ZAID';
  }

  /// Convenience helper using current system time.
  String currentSeason() => detectSeason(DateTime.now());
}

