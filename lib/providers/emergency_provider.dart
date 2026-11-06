import 'package:flutter/foundation.dart';

import '../models/ambulance_model.dart';
import '../models/hospital_model.dart';
import '../services/ambulance_repository.dart';
import 'view_state.dart';

class EmergencyProvider extends ChangeNotifier {
  EmergencyProvider({AmbulanceRepository? repository})
      : _repository = repository ?? AmbulanceRepository();

  final AmbulanceRepository _repository;

  double confirmedLat = 12.9352;
  double confirmedLng = 77.6146;
  String? selectedEmergencyTypeId;

  ViewState<AmbulanceModel> _ambulanceState = const ViewState.initial();
  ViewState<AmbulanceModel> get ambulanceState => _ambulanceState;

  ViewState<List<HospitalModel>> _hospitalsState = const ViewState.initial();
  ViewState<List<HospitalModel>> get hospitalsState => _hospitalsState;

  void setEmergencyType(String typeId) {
    selectedEmergencyTypeId = typeId;
    notifyListeners();
  }

  void updateConfirmedLocation(double lat, double lng) {
    confirmedLat = lat;
    confirmedLng = lng;
    notifyListeners();
  }

  Future<void> requestAmbulance() async {
    _ambulanceState = const ViewState.loading();
    notifyListeners();
    try {
      final ambulance = await _repository.requestAmbulance(
        latitude: confirmedLat,
        longitude: confirmedLng,
        emergencyTypeId: selectedEmergencyTypeId ?? 'unspecified',
      );
      _ambulanceState = ViewState.success(ambulance);
    } catch (e) {
      _ambulanceState =
          ViewState.error(e.toString().replaceFirst('Exception: ', ''));
    }
    notifyListeners();
  }

  void cancelRequest() {
    _ambulanceState = const ViewState.initial();
    notifyListeners();
  }

  Future<void> loadNearbyHospitals() async {
    _hospitalsState = const ViewState.loading();
    notifyListeners();
    try {
      final hospitals = await _repository.fetchNearbyHospitals();
      _hospitalsState = hospitals.isEmpty
          ? const ViewState.empty()
          : ViewState.success(hospitals);
    } catch (e) {
      _hospitalsState =
          ViewState.error(e.toString().replaceFirst('Exception: ', ''));
    }
    notifyListeners();
  }
}
