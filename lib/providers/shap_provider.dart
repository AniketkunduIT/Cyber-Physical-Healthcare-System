import 'package:flutter/foundation.dart';
import '../models/medical_profile_model.dart';
import '../models/shap_report_model.dart';
import '../services/shap_repository.dart';
import 'view_state.dart';

class ShapProvider extends ChangeNotifier {
  ShapProvider({ShapRepository? repository})
      : _repository = repository ?? ShapRepository();

  final ShapRepository _repository;

  ViewState<ShapReportModel> _state = const ViewState.initial();
  ViewState<ShapReportModel> get state => _state;

  bool get isLoading => _state.status == ViewStatus.loading;
  ShapReportModel? get report => _state.data;

  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  /// Synthetic high-concern patient scenario for demonstration purposes only.
  static const Map<String, dynamic> syntheticHighConcernDemoFeatures = {
    'age': 68,
    'bmi': 31.5,
    'heart_rate': 138,
    'systolic_bp': 180,
    'diastolic_bp': 110,
    'oxygen_saturation': 84.0,
    'temperature_c': 39.5,
    'breathlessness': 1,
    'chest_pain': 1,
    'fever': 1,
    'vomiting': 1,
  };

  MedicalProfileModel? _lastProfile;
  Map<String, dynamic>? _lastOverrides;
  String? _lastTargetClass;

  Future<void> generateReport({
    MedicalProfileModel? profile,
    Map<String, dynamic>? customOverrides,
    String? targetClass,
  }) async {
    if (isLoading) return; // Prevent duplicate concurrent clicks

    _lastProfile = profile;
    _lastOverrides = customOverrides;
    _lastTargetClass = targetClass;

    _state = const ViewState.loading();
    notifyListeners();

    try {
      final features = customOverrides ?? _repository.buildPatientFeatures(profile);
      final result = await _repository.fetchExplanation(
        features: features,
        targetClass: targetClass,
        allowDefaults: true,
      );
      _state = ViewState.success(result);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _state = ViewState.error(msg);
    }

    notifyListeners();
  }

  Future<void> switchScenario({
    required bool isDemo,
    MedicalProfileModel? profile,
  }) async {
    _isDemoMode = isDemo;
    if (isDemo) {
      await generateReport(customOverrides: syntheticHighConcernDemoFeatures);
    } else {
      await generateReport(profile: profile);
    }
  }

  Future<void> retry() async {
    if (_isDemoMode) {
      await generateReport(customOverrides: syntheticHighConcernDemoFeatures);
    } else {
      await generateReport(
        profile: _lastProfile,
        customOverrides: _lastOverrides,
        targetClass: _lastTargetClass,
      );
    }
  }

  void reset() {
    _state = const ViewState.initial();
    _isDemoMode = false;
    notifyListeners();
  }
}
