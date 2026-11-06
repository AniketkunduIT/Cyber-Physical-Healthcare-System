import '../utils/formatters.dart';

class PrescriptionModel {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final String doctorName;
  final String prescriptionDate;
  final String medicinesNotes;
  final DateTime uploadedAt;
  final bool isUploaded;

  const PrescriptionModel({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    required this.doctorName,
    required this.prescriptionDate,
    required this.medicinesNotes,
    required this.uploadedAt,
    this.isUploaded = true,
  });

  String get formattedSize => Formatters.formatFileSize(fileSizeBytes);

  PrescriptionModel copyWith({
    String? id,
    String? fileName,
    int? fileSizeBytes,
    String? doctorName,
    String? prescriptionDate,
    String? medicinesNotes,
    DateTime? uploadedAt,
    bool? isUploaded,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      doctorName: doctorName ?? this.doctorName,
      prescriptionDate: prescriptionDate ?? this.prescriptionDate,
      medicinesNotes: medicinesNotes ?? this.medicinesNotes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String? ?? 'prescription.jpg',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      doctorName: json['doctorName'] as String? ?? '',
      prescriptionDate: json['prescriptionDate'] as String? ?? '',
      medicinesNotes: json['medicinesNotes'] as String? ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : DateTime.now(),
      isUploaded: json['isUploaded'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'doctorName': doctorName,
        'prescriptionDate': prescriptionDate,
        'medicinesNotes': medicinesNotes,
        'uploadedAt': uploadedAt.toIso8601String(),
        'isUploaded': isUploaded,
      };
}
