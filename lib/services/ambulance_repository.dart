import '../models/ambulance_model.dart';
import '../models/hospital_model.dart';

class AmbulanceRepository {
  Future<AmbulanceModel> requestAmbulance({
    required double latitude,
    required double longitude,
    required String emergencyTypeId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1400));

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
    await Future.delayed(const Duration(milliseconds: 800));
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
