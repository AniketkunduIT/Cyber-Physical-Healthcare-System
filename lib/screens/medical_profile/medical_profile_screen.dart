import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/medical_profile_model.dart';
import '../../providers/medical_profile_provider.dart';
import '../../providers/view_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_profile_floating_actions.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header_badge.dart';
import '../../widgets/state_views.dart';
import '../../widgets/voice_recording_sheet.dart';
import 'widgets/demographics_form_section.dart';
import 'widgets/emergency_type_grid_section.dart';
import 'widgets/voice_notes_list_section.dart';

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _diseasesController = TextEditingController();
  final _allergiesController = TextEditingController();

  final _ageFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _diseasesFocus = FocusNode();
  final _allergiesFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MedicalProfileProvider>();
      await provider.loadProfile();
      _syncControllersFromDraft(provider.draft);
    });
  }

  void _syncControllersFromDraft(MedicalProfileModel profile) {
    _ageController.text = profile.age?.toString() ?? '';
    _weightController.text = profile.weightKg?.toString() ?? '';
    _diseasesController.text = profile.knownDiseases;
    _allergiesController.text = profile.allergies;
  }

  Future<void> _openVoiceRecorder(MedicalProfileProvider provider) async {
    final note = await VoiceRecordingSheet.show(context);
    if (!mounted || note == null) return;
    await provider.addVoiceNote(note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice note recorded (${note.formattedDuration})'),
        backgroundColor: AppColors.brandPurple,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _ageController,
      _weightController,
      _diseasesController,
      _allergiesController,
    ]) {
      c.dispose();
    }
    for (final f in [
      _ageFocus,
      _weightFocus,
      _diseasesFocus,
      _allergiesFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicalProfileProvider>();
    final status = provider.state.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Builder(
          builder: (_) {
            if (status == ViewStatus.loading && provider.state.data == null) {
              return const LoadingView(message: 'Loading your profile…');
            }
            if (status == ViewStatus.error) {
              return ErrorView(
                message: provider.state.errorMessage ?? 'Something went wrong.',
                onRetry: () => provider.loadProfile(),
              );
            }
            return _buildForm(context, provider);
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, MedicalProfileProvider provider) {
    final draft = provider.draft;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: SectionHeaderBadge(
                    title: 'A. Demographics',
                    subtitle:
                        'Update your personal details for a complete profile.',
                  ),
                ),
                const SizedBox(height: 20),
                DemographicsFormSection(
                  draft: draft,
                  ageController: _ageController,
                  weightController: _weightController,
                  diseasesController: _diseasesController,
                  allergiesController: _allergiesController,
                  ageFocus: _ageFocus,
                  weightFocus: _weightFocus,
                  diseasesFocus: _diseasesFocus,
                  allergiesFocus: _allergiesFocus,
                  onUpdateDraft: provider.updateDraft,
                ),
                const SizedBox(height: 24),
                EmergencyTypeGridSection(
                  selectedEmergencyTypeId: draft.selectedEmergencyTypeId,
                  onSelectType: (id) => provider.updateDraft(
                    (p) => p.copyWith(selectedEmergencyTypeId: id),
                  ),
                ),
                const SizedBox(height: 28),
                VoiceNotesListSection(
                  voiceNotes: draft.voiceNotes,
                  onDeleteVoiceNote: provider.removeVoiceNote,
                ),
                PrimaryButton(
                  label: 'SAVE PROFILE',
                  isLoading: provider.state.status == ViewStatus.loading,
                  gradientColors: AppColors.brandPurpleGradient,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final ok = await provider.saveProfile();
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile saved successfully.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 18,
          bottom: 96,
          child: MedicalProfileFloatingActions(
            onAddPrescription: () =>
                Navigator.of(context).pushNamed(AppRoutes.addPrescription),
            onVoiceRecord: () => _openVoiceRecorder(provider),
          ),
        ),
      ],
    );
  }
}
