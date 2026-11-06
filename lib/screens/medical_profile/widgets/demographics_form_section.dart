import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/medical_profile_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_text_field.dart';

/// Form fields for demographics: Age, Weight, BMI display, Gender, Known Diseases, Allergies.
class DemographicsFormSection extends StatelessWidget {
  final MedicalProfileModel draft;
  final TextEditingController ageController;
  final TextEditingController weightController;
  final TextEditingController diseasesController;
  final TextEditingController allergiesController;
  final FocusNode ageFocus;
  final FocusNode weightFocus;
  final FocusNode diseasesFocus;
  final FocusNode allergiesFocus;
  final void Function(MedicalProfileModel Function(MedicalProfileModel))
      onUpdateDraft;

  const DemographicsFormSection({
    super.key,
    required this.draft,
    required this.ageController,
    required this.weightController,
    required this.diseasesController,
    required this.allergiesController,
    required this.ageFocus,
    required this.weightFocus,
    required this.diseasesFocus,
    required this.allergiesFocus,
    required this.onUpdateDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Age',
                hint: 'Age',
                controller: ageController,
                focusNode: ageFocus,
                nextFocusNode: weightFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
                onChanged: (v) => onUpdateDraft(
                  (p) => p.copyWith(age: int.tryParse(v)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: CustomTextField(
                label: 'Weight',
                hint: 'Weight in kg',
                controller: weightController,
                focusNode: weightFocus,
                nextFocusNode: diseasesFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (v) => onUpdateDraft(
                  (p) => p.copyWith(weightKg: double.tryParse(v)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BMI', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      draft.bmi?.toString() ?? 'BMI (Calculated)',
                      style: TextStyle(
                        color: draft.bmi == null
                            ? const Color(0xFF9AA1AC)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Gender>(
                    initialValue: draft.gender,
                    decoration: const InputDecoration(),
                    hint: const Text('Select Gender'),
                    items: Gender.values
                        .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                        .toList(),
                    onChanged: (g) => onUpdateDraft((p) => p.copyWith(gender: g)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Known Disease',
          hint: 'Known Diseases (e.g., Diabetes, Hypertension)',
          controller: diseasesController,
          focusNode: diseasesFocus,
          nextFocusNode: allergiesFocus,
          onChanged: (v) => onUpdateDraft((p) => p.copyWith(knownDiseases: v)),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Allergies',
          hint: 'Allergies (e.g., Peanuts, Penicillin)',
          controller: allergiesController,
          focusNode: allergiesFocus,
          textInputAction: TextInputAction.done,
          onChanged: (v) => onUpdateDraft((p) => p.copyWith(allergies: v)),
        ),
      ],
    );
  }
}
