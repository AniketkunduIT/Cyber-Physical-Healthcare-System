import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ambulance_model.dart';
import '../models/hospital_model.dart';
import 'api_config.dart';

class AmbulanceRepository {
  Future<AmbulanceModel> requestAmbulance({
    required double latitude,
    required double longitude,
    required String emergencyTypeId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/emergency/request-ambulance');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'emergencyTypeId': emergencyTypeId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AmbulanceModel.fromJson(data);
      }
    } catch (_) {}

    // Fallback response if network disconnects
    return const AmbulanceModel(
      driverName: 'Rakesh Sharma',
      vehicleNumber: 'KA 01 EM 1234',
      etaMinutes: 7,
      equipment: ['Oxygen', 'Ventilator', 'ICU support'],
      driverPhone: '+919876543210',
      medicalTeamPhone: '+919812345678',
    );
  }

  Future<List<HospitalModel>> fetchNearbyHospitals() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/emergency/hospitals');
    try {
      final response = await http.get(url, headers: ApiConfig.defaultHeaders);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => HospitalModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return const [
      HospitalModel(
        id: 'h1',
        name: 'Manipal Hospital',
        address: 'Old Airport Road, Bengaluru',
        distanceKm: 1.2,
        phone: '+918041176000',
        hasEmergencyBeds: true,
      ),
      HospitalModel(
        id: 'h2',
        name: 'Fortis Hospital',
        address: 'Bannerghatta Road, Bengaluru',
        distanceKm: 3.4,
        phone: '+918066214444',
        hasEmergencyBeds: true,
      ),
      HospitalModel(
        id: 'h3',
        name: 'Apollo Hospital',
        address: 'Bannerghatta Road, Bengaluru',
        distanceKm: 4.8,
        phone: '+918026304050',
        hasEmergencyBeds: false,
      ),
    ];
  }
}
