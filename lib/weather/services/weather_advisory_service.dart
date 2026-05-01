// lib/services/weather_advisory_service.dart

class WeatherInput {
  final double temperatureC; // e.g. 30.5
  final double humidity; // % e.g. 75
  final double windSpeedKmph; // e.g. 12
  final double rainMm; // predicted rainfall in mm
  final double rainProbability; // 0.0 - 1.0 (0% - 100%)
  final bool thunderstorm; // true if thunderstorm alert
  final bool cyclone; // true if cyclone alert
  final bool flood; // true if flood alert
  final bool fog; // true if fog alert
  final int dryDaysAhead; // how many dry days in forecast
  final double uvIndex; // UV index value

  WeatherInput({
    required this.temperatureC,
    required this.humidity,
    required this.windSpeedKmph,
    required this.rainMm,
    required this.rainProbability,
    required this.thunderstorm,
    required this.cyclone,
    required this.flood,
    required this.fog,
    required this.dryDaysAhead,
    required this.uvIndex,
  });
}

class AdvisoryResult {
  final List<String> mustDo100; // Compulsory
  final List<String> canDo50; // Recommended
  final List<String> canDo20; // Optional

  AdvisoryResult({
    required this.mustDo100,
    required this.canDo50,
    required this.canDo20,
  });
}

class WeatherAdvisoryService {
  AdvisoryResult generateAdvisory(WeatherInput w) {
    final List<String> mustDo100 = [];
    final List<String> canDo50 = [];
    final List<String> canDo20 = [];

    // -----------------------------
    // 1. RAIN & DRY SPELL LOGIC
    // -----------------------------

    final bool rainComing = w.rainProbability >= 0.6 || w.rainMm >= 5.0;
    final bool heavyRain = w.rainMm >= 20.0;

    if (rainComing) {
      mustDo100.add("Stop irrigation immediately (rain expected).");
      mustDo100.add("Do not spray pesticides or fertilizers before rain.");
      canDo50.add("Check and clean field drainage channels.");
      canDo20.add("Cover tools, machines and inputs properly.");
    }

    if (heavyRain) {
      mustDo100.add(
        "Ensure drainage to remove excess water (heavy rain forecast).",
      );
      mustDo100.add("Avoid harvesting during heavy rain period.");
      canDo50.add("Protect stored grains and fodder from moisture.");
      canDo20.add("Store excess rainwater in farm pond if available.");
    }

    if (!rainComing && w.dryDaysAhead >= 2) {
      mustDo100.add("Irrigate crops as required (no rain for next days).");
      canDo50.add("Do light weeding and intercultural operations.");
      canDo20.add("Apply organic mulches to conserve soil moisture.");
    }

    // -----------------------------
    // 2. TEMPERATURE / HEAT / COLD
    // -----------------------------

    if (w.temperatureC >= 35.0 && w.temperatureC < 40.0) {
      mustDo100.add("Increase irrigation frequency due to high temperature.");
      canDo50.add("Use mulching to reduce evaporation.");
      canDo20.add("Provide shade to sensitive crops (nursery, vegetables).");
    }

    if (w.temperatureC >= 40.0) {
      mustDo100.add(
        "Severe heat: irrigate in evening or night to reduce stress.",
      );
      mustDo100.add("Avoid heavy field work during afternoon.");
      canDo50.add("Mulching and shade nets are strongly recommended.");
      canDo20.add(
        "Use reflective sheets for very sensitive crops if available.",
      );
    }

    if (w.temperatureC <= 10.0 && w.temperatureC > 5.0) {
      mustDo100.add("Low temperature: protect young crops from cold.");
      canDo50.add("Light irrigation in morning can help reduce frost risk.");
      canDo20.add("Use crop covers or plastic sheets where possible.");
    }

    if (w.temperatureC <= 5.0) {
      mustDo100.add(
        "Severe cold / frost risk: cover crops and create smoke near field.",
      );
      canDo50.add("Avoid irrigating at night during frost risk.");
      canDo20.add(
        "Use low tunnels or temporary structures for high-value crops.",
      );
    }

    // -----------------------------
    // 3. WIND SPEED & SPRAYING
    // -----------------------------

    if (w.windSpeedKmph > 15.0) {
      mustDo100.add("Do NOT spray pesticides or fertilizers (wind too high).");
      canDo50.add("Secure loose structures, shade nets, and plastic covers.");
      canDo20.add("Support weak or tall plants if needed.");
    } else if (w.windSpeedKmph >= 1.0 && w.windSpeedKmph <= 10.0) {
      // Suitable for spraying IF farmer wants to spray
      canDo50.add("Wind speed is suitable for pesticide spraying if required.");
      canDo20.add("Foliar nutrient spraying can also be done at this time.");
    }

    // -----------------------------
    // 4. HUMIDITY & DISEASE RISK
    // -----------------------------

    if (w.humidity >= 80.0) {
      canDo50.add("High humidity: monitor crops for fungal diseases.");
      if (!rainComing) {
        canDo50.add(
          "If disease history is present, apply preventive fungicide.",
        );
      }
      canDo20.add(
        "Plan slightly wider spacing for next sowing season to reduce humidity between plants.",
      );
    } else if (w.humidity <= 40.0) {
      mustDo100.add(
        "Low humidity: conditions are suitable for harvesting and grain drying.",
      );
      canDo50.add("Dry harvested produce in sun and store in dry place.");
      canDo20.add("Do light intercultural operations like weeding.");
    }

    // -----------------------------
    // 5. EXTREME EVENTS (STORM / CYCLONE / FLOOD / FOG / UV)
    // -----------------------------

    if (w.thunderstorm) {
      mustDo100.add("Thunderstorm forecast: stop all field operations.");
      mustDo100.add(
        "Avoid standing under trees or electric poles in the field.",
      );
      canDo50.add("Secure tools, equipment and temporary structures.");
      canDo20.add("Tie young or tall plants if they may lodge.");
    }

    if (w.cyclone) {
      mustDo100.add(
        "Cyclone warning: harvest ready crops as early as possible.",
      );
      mustDo100.add(
        "Shift livestock, seeds and fertilizers to safe covered area.",
      );
      canDo50.add("Protect storage sheds and cover stored produce.");
      canDo20.add("Strengthen fencing and support structures if possible.");
    }

    if (w.flood) {
      mustDo100.add(
        "Flood alert: move seeds, fertilizers and tools to higher ground.",
      );
      mustDo100.add(
        "Create drainage paths where possible to divert excess water.",
      );
      canDo50.add("Check bunds and field boundaries for weak points.");
      canDo20.add("Elevate pumps and electrical equipment above water level.");
    }

    if (w.fog) {
      mustDo100.add("Avoid pesticide spraying during fog.");
      canDo50.add("Monitor for fungal diseases during persistent fog.");
      canDo20.add("Delay early morning field work if visibility is very low.");
    }

    if (w.uvIndex >= 8.0) {
      mustDo100.add(
        "High UV index: protect nursery and young plants from direct midday sun.",
      );
      canDo50.add("Reduce afternoon field work for labourers.");
      canDo20.add("Use UV protective sheets or shade nets where available.");
    }

    // -----------------------------
    // 6. CLEAR WEATHER (GENERAL)
    // -----------------------------

    final bool clearDay =
        !rainComing && !w.thunderstorm && !w.cyclone && !w.flood;

    if (clearDay) {
      canDo50.add(
        "Clear day: good time for fertilizer application and planned pesticide sprays.",
      );
      if (w.dryDaysAhead >= 2) {
        mustDo100.add(
          "Dry weather: suitable period for harvesting and drying produce.",
        );
      }
      canDo20.add("Carry out weeding and intercultural operations.");
    }

    // -----------------------------
    // 7. INTELLIGENT FALLBACK:
    // If no strong rules matched, still give useful advice.
    // -----------------------------

    if (mustDo100.isEmpty && canDo50.isEmpty && canDo20.isEmpty) {
      // "Based on my intelligence" -> safe generic suggestions
      mustDo100.add(
        "Check soil moisture and irrigate only if the top layer is dry.",
      );
      canDo50.add(
        "Inspect crops for pests and diseases at least once this week.",
      );
      canDo50.add(
        "Plan fertilizer application according to crop stage and local recommendations.",
      );
      canDo20.add(
        "Clean and maintain farm tools, pumps and irrigation channels.",
      );
    }

    return AdvisoryResult(
      mustDo100: _unique(mustDo100),
      canDo50: _unique(canDo50),
      canDo20: _unique(canDo20),
    );
  }

  // Helper to remove duplicate lines
  List<String> _unique(List<String> items) {
    return items.toSet().toList();
  }
}
