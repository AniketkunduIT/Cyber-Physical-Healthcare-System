import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/prescription_model.dart';
import '../../providers/medical_profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header_badge.dart';
import 'widgets/prescription_file_preview.dart';
import 'widgets/prescription_upload_picker.dart';

class AddPrescriptionScreen extends StatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorController = TextEditingController();
  final _dateController = TextEditingController();
  final _medicinesController = TextEditingController();

  final _doctorFocus = FocusNode();
  final _dateFocus = FocusNode();
  final _medicinesFocus = FocusNode();

  String? _uploadedFileName = 'prescription_01.jpg';
  int _uploadedFileSize = 1258291; // 1.2 MB
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd / MM / yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _dateController.dispose();
    _medicinesController.dispose();
    _doctorFocus.dispose();
    _dateFocus.dispose();
    _medicinesFocus.dispose();
    super.dispose();
  }

  void _simulateUpload(String fileName, int bytes) {
    setState(() {
      _isUploading = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _uploadedFileName = fileName;
          _uploadedFileSize = bytes;
          _isUploading = false;
        });
      }
    });
  }

  void _removeUploadedFile() {
    setState(() {
      _uploadedFileName = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandPurple,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dateController.text = DateFormat('dd / MM / yyyy').format(picked);
    }
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a prescription image or document.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final prescription = PrescriptionModel(
      id: 'pres_${DateTime.now().millisecondsSinceEpoch}',
      fileName: _uploadedFileName!,
      fileSizeBytes: _uploadedFileSize,
      doctorName: _doctorController.text.trim(),
      prescriptionDate: _dateController.text.trim(),
      medicinesNotes: _medicinesController.text.trim(),
      uploadedAt: DateTime.now(),
    );

    final provider = context.read<MedicalProfileProvider>();
    final success = await provider.addPrescription(prescription);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription saved successfully!')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save prescription.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SectionHeaderBadge(
                  title: 'C. Add Prescription',
                  subtitle:
                      'Upload your prescription so responders can see your medicines.',
                ),
                const SizedBox(height: 24),
                PrescriptionUploadPicker(
                  onUploadTap: () => _simulateUpload(
                    'prescription_${DateTime.now().second}.jpg',
                    1258291,
                  ),
                  onTakePhotoTap: () => _simulateUpload(
                    'camera_photo_${DateTime.now().millisecond}.jpg',
                    2097152,
                  ),
                  onGalleryTap: () => _simulateUpload(
                    'gallery_image_${DateTime.now().millisecond}.jpg',
                    1572864,
                  ),
                ),
                const SizedBox(height: 16),
                PrescriptionFilePreview(
                  isUploading: _isUploading,
                  fileName: _uploadedFileName,
                  fileSizeBytes: _uploadedFileSize,
                  onRemove: _removeUploadedFile,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: "Doctor's Name",
                  hint: "Doctor's name (e.g., Dr. Sharma)",
                  controller: _doctorController,
                  focusNode: _doctorFocus,
                  nextFocusNode: _dateFocus,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  child: IgnorePointer(
                    child: CustomTextField(
                      label: 'Prescription Date',
                      hint: 'DD / MM / yyyy',
                      controller: _dateController,
                      focusNode: _dateFocus,
                      nextFocusNode: _medicinesFocus,
                      prefixIcon: Icons.calendar_today_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Medicines / Notes',
                  hint: 'Medicines or notes (e.g., Metformin 500 mg, twice daily)',
                  controller: _medicinesController,
                  focusNode: _medicinesFocus,
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'SAVE PRESCRIPTION',
                  isLoading: _isSaving,
                  gradientColors: AppColors.brandPurpleGradient,
                  onPressed: _savePrescription,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
