import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medical_profile_model.dart';
import '../models/shap_report_model.dart';
import 'api_config.dart';

class ShapRepository {
  /// Builds a complete 11-feature patient map from the current MedicalProfile.
  Map<String, dynamic> buildPatientFeatures(
    MedicalProfileModel? profile, {
    Map<String, dynamic>? overrides,
  }) {
    final age = profile?.age ?? 40;
    final bmi = profile?.bmi ?? 23.5;

    // Baseline physiological parameters
    int heartRate = 75;
    int systolicBp = 120;
    int diastolicBp = 80;
    double oxygenSaturation = 98.0;
    double temperatureC = 37.0;
    int breathlessness = 0;
    int chestPain = 0;
    int fever = 0;
    int vomiting = 0;

    // Derive acute symptoms from patient's emergency context & disease profile
    final emergencyType = profile?.selectedEmergencyTypeId?.toLowerCase() ?? '';
    final diseases = profile?.knownDiseases.toLowerCase() ?? '';

    if (emergencyType.contains('cardiac')) {
      chestPain = 1;
      breathlessness = 1;
      heartRate = 125;
      systolicBp = 160;
      diastolicBp = 100;
      oxygenSaturation = 91.0;
    } else if (emergencyType.contains('respiratory')) {
      breathlessness = 1;
      oxygenSaturation = 88.0;
      heartRate = 115;
    } else if (emergencyType.contains('stroke')) {
      systolicBp = 175;
      diastolicBp = 105;
      heartRate = 95;
    } else if (emergencyType.contains('poisoning')) {
      vomiting = 1;
      heartRate = 105;
    } else if (emergencyType.contains('trauma') || emergencyType.contains('accident')) {
      heartRate = 110;
      systolicBp = 135;
      diastolicBp = 88;
    }

    if (diseases.contains('fever') || diseases.contains('infection')) {
      fever = 1;
      temperatureC = 38.6;
    }
    if (diseases.contains('hypertension') || diseases.contains('high bp') || diseases.contains('blood pressure')) {
      systolicBp = systolicBp < 145 ? 148 : systolicBp;
      diastolicBp = diastolicBp < 92 ? 94 : diastolicBp;
    }
    if (diseases.contains('asthma') || diseases.contains('copd')) {
      breathlessness = 1;
      oxygenSaturation = oxygenSaturation > 93.0 ? 92.5 : oxygenSaturation;
    }

    final features = <String, dynamic>{
      'age': age,
      'bmi': bmi,
      'heart_rate': heartRate,
      'systolic_bp': systolicBp,
      'diastolic_bp': diastolicBp,
      'oxygen_saturation': oxygenSaturation,
      'temperature_c': temperatureC,
      'breathlessness': breathlessness,
      'chest_pain': chestPain,
      'fever': fever,
      'vomiting': vomiting,
    };

    // Apply any explicit clinical overrides
    if (overrides != null) {
      features.addAll(overrides);
    }

    return features;
  }

  /// Sends patient features to the FastAPI endpoint: POST /api/shap/explain
  Future<ShapReportModel> fetchExplanation({
    required Map<String, dynamic> features,
    String? targetClass,
    bool allowDefaults = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/shap/explain');

    final body = jsonEncode({
      'features': features,
      if (targetClass != null) 'target_class': targetClass,
      'allow_defaults': allowDefaults,
    });

    try {
      final response = await http
          .post(url, headers: ApiConfig.defaultHeaders, body: body)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ShapReportModel.fromJson(data, featuresUsed: features);
      } else {
        String errorMessage = 'Failed to generate SHAP report.';
        try {
          final errJson = jsonDecode(response.body);
          if (errJson is Map && errJson['detail'] != null) {
            final detail = errJson['detail'];
            if (detail is Map && detail['message'] != null) {
              errorMessage = detail['message'].toString();
            } else if (detail is String) {
              errorMessage = detail;
            }
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('Failed to generate SHAP report') && !e.toString().contains('ModelSchemaMismatch')) {
        if (e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection refused') ||
            e.toString().contains('SocketException')) {
          throw Exception(
            'Cannot reach the backend server at ${ApiConfig.baseUrl}. Please verify the FastAPI backend is running.',
          );
        }
      }
      rethrow;
    }
  }
}
