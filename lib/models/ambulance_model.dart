class AmbulanceModel {
  final String driverName;
  final String vehicleNumber;
  final int etaMinutes;
  final List<String> equipment;
  final String driverPhone;
  final String medicalTeamPhone;

  const AmbulanceModel({
    required this.driverName,
    required this.vehicleNumber,
    required this.etaMinutes,
    required this.equipment,
    required this.driverPhone,
    required this.medicalTeamPhone,
  });

  factory AmbulanceModel.fromJson(Map<String, dynamic> json) {
    return AmbulanceModel(
      driverName: json['driverName'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      etaMinutes: json['etaMinutes'] as int,
      equipment: List<String>.from(json['equipment'] as List),
      driverPhone: json['driverPhone'] as String,
      medicalTeamPhone: json['medicalTeamPhone'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'driverName': driverName,
        'vehicleNumber': vehicleNumber,
        'etaMinutes': etaMinutes,
        'equipment': equipment,
        'driverPhone': driverPhone,
        'medicalTeamPhone': medicalTeamPhone,
      };
}
