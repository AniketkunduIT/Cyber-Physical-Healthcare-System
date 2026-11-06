class HospitalModel {
  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final String phone;
  final bool hasEmergencyBeds;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.phone,
    required this.hasEmergencyBeds,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      phone: json['phone'] as String,
      hasEmergencyBeds: json['hasEmergencyBeds'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'distanceKm': distanceKm,
        'phone': phone,
        'hasEmergencyBeds': hasEmergencyBeds,
      };
}
