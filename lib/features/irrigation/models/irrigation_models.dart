class WeatherFeatures {
  final double tempMean;
  final double humidityMean;
  final double rain7d;
  final double rain14d;
  final double et07d;
  final double deficit7d;

  WeatherFeatures({
    required this.tempMean,
    required this.humidityMean,
    required this.rain7d,
    required this.rain14d,
    required this.et07d,
    required this.deficit7d,
  });

  factory WeatherFeatures.fromJson(Map<String, dynamic> json) {
    return WeatherFeatures(
      tempMean: (json['temp_mean'] as num).toDouble(),
      humidityMean: (json['humidity_mean'] as num).toDouble(),
      rain7d: (json['rain_7d'] as num).toDouble(),
      rain14d: (json['rain_14d'] as num).toDouble(),
      et07d: (json['et0_7d'] as num).toDouble(),
      deficit7d: (json['deficit_7d'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temp_mean': tempMean,
      'humidity_mean': humidityMean,
      'rain_7d': rain7d,
      'rain_14d': rain14d,
      'et0_7d': et07d,
      'deficit_7d': deficit7d,
    };
  }
}

class SentinelFeatures {
  final double vvMean;
  final double vvChange;
  final double sentinelAgeDays;

  SentinelFeatures({
    required this.vvMean,
    required this.vvChange,
    required this.sentinelAgeDays,
  });

  factory SentinelFeatures.fromJson(Map<String, dynamic> json) {
    return SentinelFeatures(
      vvMean: (json['vv_mean'] as num).toDouble(),
      vvChange: (json['vv_change'] as num).toDouble(),
      sentinelAgeDays: (json['sentinel_age_days'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vv_mean': vvMean,
      'vv_change': vvChange,
      'sentinel_age_days': sentinelAgeDays,
    };
  }
}

class Recommendation {
  final double irrigationMm;
  final int actionIndex;
  final String actionLabel;

  Recommendation({
    required this.irrigationMm,
    required this.actionIndex,
    required this.actionLabel,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      irrigationMm: (json['irrigation_mm'] as num).toDouble(),
      actionIndex: json['action_index'] as int,
      actionLabel: json['action_label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'irrigation_mm': irrigationMm,
      'action_index': actionIndex,
      'action_label': actionLabel,
    };
  }
}

class LocationPredictionResponse {
  final String status;
  final double latitude;
  final double longitude;
  final Recommendation recommendation;
  final List<double> qValues;
  final WeatherFeatures weatherFeatures;
  final SentinelFeatures sentinelFeatures;

  LocationPredictionResponse({
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.recommendation,
    required this.qValues,
    required this.weatherFeatures,
    required this.sentinelFeatures,
  });

  factory LocationPredictionResponse.fromJson(Map<String, dynamic> json) {
    final locJson = json['location'] as Map<String, dynamic>;
    return LocationPredictionResponse(
      status: json['status'] as String,
      latitude: (locJson['latitude'] as num).toDouble(),
      longitude: (locJson['longitude'] as num).toDouble(),
      recommendation: Recommendation.fromJson(json['recommendation'] as Map<String, dynamic>),
      qValues: (json['q_values'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      weatherFeatures: WeatherFeatures.fromJson(json['weather_features'] as Map<String, dynamic>),
      sentinelFeatures: SentinelFeatures.fromJson(json['sentinel_features'] as Map<String, dynamic>),
    );
  }
}
