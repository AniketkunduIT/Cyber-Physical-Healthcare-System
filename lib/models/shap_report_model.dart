class FeatureContributionItem {
  final String feature;
  final double shapValue;
  final String direction; // 'positive', 'negative', 'neutral'
  final double? rawValue;

  const FeatureContributionItem({
    required this.feature,
    required this.shapValue,
    required this.direction,
    this.rawValue,
  });

  bool get isPositive => direction == 'positive' || shapValue > 0;
  bool get isNegative => direction == 'negative' || shapValue < 0;

  String get formattedValue {
    final prefix = shapValue > 0 ? '+' : '';
    return '$prefix${shapValue.toStringAsFixed(4)}';
  }

  String get humanFeatureName {
    switch (feature) {
      case 'oxygen_saturation':
        return 'Oxygen Saturation (SpO₂)';
      case 'heart_rate':
        return 'Heart Rate (bpm)';
      case 'systolic_bp':
        return 'Systolic BP (mmHg)';
      case 'diastolic_bp':
        return 'Diastolic BP (mmHg)';
      case 'temperature_c':
        return 'Body Temp (°C)';
      case 'breathlessness':
        return 'Breathlessness / Dyspnea';
      case 'chest_pain':
        return 'Chest Pain';
      case 'fever':
        return 'Fever';
      case 'vomiting':
        return 'Vomiting / Nausea';
      case 'bmi':
        return 'Body Mass Index (BMI)';
      case 'age':
        return 'Patient Age';
      default:
        return feature
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  factory FeatureContributionItem.fromJson(Map<String, dynamic> json) {
    return FeatureContributionItem(
      feature: json['feature'] as String? ?? 'unknown',
      shapValue: (json['shap_value'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction'] as String? ?? 'neutral',
      rawValue: (json['raw_value'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'feature': feature,
        'shap_value': shapValue,
        'direction': direction,
        if (rawValue != null) 'raw_value': rawValue,
      };
}

class EmergencySafetyInfo {
  final bool redFlagTriggered;
  final List<String> redFlags;
  final String clinicalAction;
  final bool independentOfMl;

  const EmergencySafetyInfo({
    required this.redFlagTriggered,
    required this.redFlags,
    required this.clinicalAction,
    this.independentOfMl = true,
  });

  factory EmergencySafetyInfo.fromJson(Map<String, dynamic> json) {
    return EmergencySafetyInfo(
      redFlagTriggered: json['red_flag_triggered'] as bool? ?? false,
      redFlags: (json['red_flags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      clinicalAction: json['clinical_action'] as String? ?? '',
      independentOfMl: json['independent_of_ml'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'red_flag_triggered': redFlagTriggered,
        'red_flags': redFlags,
        'clinical_action': clinicalAction,
        'independent_of_ml': independentOfMl,
      };
}

class ShapReportModel {
  final String status;
  final String predictedClass;
  final List<FeatureContributionItem> explanation;
  final double? baseValue;
  final String? targetClass;
  final String? outputScale;
  final double? predictionMargin;
  final Map<String, double> probabilities;
  final List<String> imputedFeatures;
  final List<String> unrecognizedFeatures;
  final EmergencySafetyInfo? emergencySafety;
  final String? safetyDisclaimer;
  final Map<String, dynamic>? patientFeaturesUsed;

  const ShapReportModel({
    required this.status,
    required this.predictedClass,
    required this.explanation,
    this.baseValue,
    this.targetClass,
    this.outputScale,
    this.predictionMargin,
    this.probabilities = const {},
    this.imputedFeatures = const [],
    this.unrecognizedFeatures = const [],
    this.emergencySafety,
    this.safetyDisclaimer,
    this.patientFeaturesUsed,
  });

  double get predictedProbability {
    final key = predictedClass;
    return probabilities[key] ??
        probabilities.entries
            .firstWhere(
              (e) => e.key.toLowerCase() == predictedClass.toLowerCase(),
              orElse: () => const MapEntry('', 1.0),
            )
            .value;
  }

  factory ShapReportModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? featuresUsed,
  }) {
    final probsMap = <String, double>{};
    if (json['probabilities'] is Map<String, dynamic>) {
      (json['probabilities'] as Map<String, dynamic>).forEach((k, v) {
        if (v is num) probsMap[k] = v.toDouble();
      });
    }

    final explList = (json['explanation'] as List<dynamic>?)
            ?.map((e) => FeatureContributionItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ShapReportModel(
      status: json['status'] as String? ?? 'success',
      predictedClass: json['predicted_class'] as String? ?? 'Standard',
      explanation: explList,
      baseValue: (json['base_value'] as num?)?.toDouble(),
      targetClass: json['target_class'] as String?,
      outputScale: json['output_scale'] as String? ?? 'raw_margin',
      predictionMargin: (json['prediction_margin'] as num?)?.toDouble(),
      probabilities: probsMap,
      imputedFeatures: (json['imputed_features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      unrecognizedFeatures: (json['unrecognized_features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      emergencySafety: json['emergency_safety'] is Map<String, dynamic>
          ? EmergencySafetyInfo.fromJson(json['emergency_safety'] as Map<String, dynamic>)
          : null,
      safetyDisclaimer: json['safety_disclaimer'] as String?,
      patientFeaturesUsed: featuresUsed,
    );
  }
}
