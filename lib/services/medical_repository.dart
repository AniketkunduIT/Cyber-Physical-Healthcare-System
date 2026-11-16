import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medical_profile_model.dart';
import '../models/prescription_model.dart';
import '../models/voice_note_model.dart';
import 'api_config.dart';

class MedicalRepository {
  MedicalProfileModel? _cached;

  Future<MedicalProfileModel?> fetchProfile() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/medical/profile');
    try {
      final response = await http.get(url, headers: ApiConfig.defaultHeaders);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cached = MedicalProfileModel.fromJson(data);
        return _cached;
      } else {
        return _cached;
      }
    } catch (_) {
      // Fallback to cached if offline
      return _cached;
    }
  }

  Future<MedicalProfileModel> saveProfile(MedicalProfileModel profile) async {
    if (profile.age == null || profile.age! <= 0 || profile.age! > 120) {
      throw Exception('Please enter a valid age.');
    }
    if (profile.gender == null) {
      throw Exception('Please select a gender.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/medical/profile');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'age': profile.age,
          'weightKg': profile.weightKg,
          'gender': profile.gender?.name,
          'knownDiseases': profile.knownDiseases,
          'allergies': profile.allergies,
          'selectedEmergencyTypeId': profile.selectedEmergencyTypeId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cached = MedicalProfileModel.fromJson(data);
        return _cached!;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['detail'] ?? 'Failed to save medical profile.');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('Failed host lookup') && !e.toString().contains('Connection refused')) {
        rethrow;
      }
      _cached = profile;
      return profile;
    }
  }

  Future<PrescriptionModel> savePrescription(PrescriptionModel prescription) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/medical/prescriptions');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'id': prescription.id,
          'fileName': prescription.fileName,
          'fileSizeBytes': prescription.fileSizeBytes,
          'doctorName': prescription.doctorName,
          'prescriptionDate': prescription.prescriptionDate,
          'medicinesNotes': prescription.medicinesNotes,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final saved = PrescriptionModel.fromJson(data);
        if (_cached != null) {
          final updatedList = List<PrescriptionModel>.from(_cached!.prescriptions)
            ..removeWhere((p) => p.id == saved.id)
            ..insert(0, saved);
          _cached = _cached!.copyWith(prescriptions: updatedList);
        }
        return saved;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['detail'] ?? 'Failed to save prescription.');
      }
    } catch (e) {
      if (_cached != null) {
        final updatedList = List<PrescriptionModel>.from(_cached!.prescriptions)
          ..removeWhere((p) => p.id == prescription.id)
          ..insert(0, prescription);
        _cached = _cached!.copyWith(prescriptions: updatedList);
      }
      return prescription;
    }
  }

  Future<void> deletePrescription(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/medical/prescriptions/$id');
    try {
      await http.delete(url, headers: ApiConfig.defaultHeaders);
    } catch (_) {}

    if (_cached != null) {
      final updatedList = List<PrescriptionModel>.from(_cached!.prescriptions)
        ..removeWhere((p) => p.id == id);
      _cached = _cached!.copyWith(prescriptions: updatedList);
    }
  }

  Future<VoiceNoteModel> saveVoiceNote(VoiceNoteModel note) async {
    if (_cached != null) {
      final updatedList = List<VoiceNoteModel>.from(_cached!.voiceNotes)
        ..removeWhere((v) => v.id == note.id)
        ..insert(0, note);
      _cached = _cached!.copyWith(voiceNotes: updatedList);
    }
    return note;
  }
}
