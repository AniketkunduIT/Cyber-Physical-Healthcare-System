import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shap_report_model.dart';
import '../../providers/medical_profile_provider.dart';
import '../../providers/shap_provider.dart';
import '../../providers/view_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/state_views.dart';
import 'widgets/shap_feature_bars.dart';
import 'widgets/shap_waterfall_plot.dart';

class ShapReportScreen extends StatefulWidget {
  const ShapReportScreen({super.key});

  @override
  State<ShapReportScreen> createState() => _ShapReportScreenState();
}

class _ShapReportScreenState extends State<ShapReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<MedicalProfileProvider>().draft;
      final shap = context.read<ShapProvider>();
      if (shap.isDemoMode) {
        shap.generateReport(customOverrides: ShapProvider.syntheticHighConcernDemoFeatures);
      } else {
        shap.generateReport(profile: profile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shap = context.watch<ShapProvider>();
    final state = shap.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual SHAP Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Explanation',
            onPressed: () {
              final profile = context.read<MedicalProfileProvider>().draft;
              if (shap.isDemoMode) {
                shap.generateReport(customOverrides: ShapProvider.syntheticHighConcernDemoFeatures);
              } else {
                shap.generateReport(profile: profile);
              }
            },
          ),
        ],
      ),
      body: Builder(
        builder: (_) {
          if (state.status == ViewStatus.loading) {
            return const LoadingView(
              message: 'Generating live clinical SHAP report…',
            );
          }

          if (state.isError) {
            return ErrorView(
              message: state.errorMessage ?? 'Failed to compute SHAP explanation.',
              onRetry: () => shap.retry(),
            );
          }

          final report = state.data;
          if (report == null || report.explanation.isEmpty) {
            return EmptyView(
              message: 'No explanation data returned by the model.',
              icon: Icons.analytics_outlined,
              actionLabel: 'Try Again',
              onAction: () {
                final profile = context.read<MedicalProfileProvider>().draft;
                shap.generateReport(profile: profile);
              },
            );
          }

          return _buildReportContent(context, report, shap);
        },
      ),
    );
  }

  Widget _buildReportContent(
    BuildContext context,
    ShapReportModel report,
    ShapProvider shap,
  ) {
    final safety = report.emergencySafety;
    final redFlagTriggered = safety?.redFlagTriggered ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SCENARIO SELECTOR (Active Profile vs Synthetic Demo Scenario)
          _buildScenarioSelector(shap),
          const SizedBox(height: 12),

          // 2. SYNTHETIC DEMO NOTICE BANNER (if in demo mode)
          if (shap.isDemoMode) ...[
            _buildSyntheticDemoBanner(),
            const SizedBox(height: 14),
          ],

          // 3. EMERGENCY RED FLAG WARNING BANNER (High Visibility)
          if (redFlagTriggered) ...[
            _buildEmergencyAlertBanner(safety!),
            const SizedBox(height: 16),
          ],

          // 4. IMPROVED PATIENT SUMMARY CARD
          _buildPatientSummaryCard(report),
          const SizedBox(height: 16),

          // 5. SIMPLE EXPLANATION FOR USERS (Plain-Language AI Clinical Narrative)
          _buildPlainLanguageExplanation(report),
          const SizedBox(height: 16),

          // 6. MAIN VISUALIZATION: SIMPLE FEATURE IMPACT CHART
          ShapFeatureBars(
            items: report.explanation,
            targetClass: report.targetClass ?? report.predictedClass,
            patientMeasurements: report.patientFeaturesUsed,
          ),
          const SizedBox(height: 16),

          // 7. COLLAPSIBLE ADVANCED VIEW: SHAP WATERFALL PLOT & AUDIT TRANSPARENCY
          _buildAdvancedCollapsibleSection(report),
          const SizedBox(height: 16),

          // 8. EMERGENCY DISPATCH SHORTCUT
          if (redFlagTriggered)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              icon: const Icon(Icons.emergency_outlined),
              label: const Text(
                'DISPATCH AMBULANCE NOW',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.confirmLocation),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Scenario Switcher between Active Patient Profile and Synthetic High-Concern Demo
  Widget _buildScenarioSelector(ShapProvider shap) {
    final isDemo = shap.isDemoMode;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: isDemo
                  ? () {
                      final profile = context.read<MedicalProfileProvider>().draft;
                      shap.switchScenario(isDemo: false, profile: profile);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !isDemo ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: !isDemo
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Active Patient Profile',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: !isDemo ? FontWeight.w800 : FontWeight.w600,
                        color: !isDemo ? AppColors.primaryStart : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: !isDemo
                  ? () {
                      shap.switchScenario(isDemo: true);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isDemo ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: isDemo
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.science_outlined, size: 14, color: AppColors.emergencyStart),
                        const SizedBox(width: 4),
                        Text(
                          'Demo High-Concern',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isDemo ? FontWeight.w800 : FontWeight.w600,
                            color: isDemo ? AppColors.emergencyStart : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Labelled Synthetic Demonstration Scenario Notice Banner
  Widget _buildSyntheticDemoBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      padding: const EdgeInsets.all(12),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.biotech_outlined, color: Color(0xFF1D4ED8), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIMULATED HIGH-CONCERN PATIENT SCENARIO',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'This simulated scenario (Age: 68, BP: 180/110, HR: 138 bpm, SpO₂: 84%, Chest Pain & Dyspnea) is for clinical demonstration only. Predictions and SHAP contributions are computed live by the FastAPI XGBoost pipeline.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1E3A8A),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Emergency Red Flag Warning Banner
  Widget _buildEmergencyAlertBanner(EmergencySafetyInfo safety) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CRITICAL CLINICAL RED FLAG DETECTED',
                      style: TextStyle(
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(color: const Color(0xFFF87171)),
                      ),
                      child: const Text(
                        'OPERATES INDEPENDENT OF AI PREDICTION',
                        style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...safety.redFlags.map(
            (rf) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      rf,
                      style: const TextStyle(
                        color: Color(0xFF7F1D1D),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services_outlined, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    safety.clinicalAction,
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Improved Patient Summary with Clean Healthcare Hierarchy & Patient Measurements
  Widget _buildPatientSummaryCard(ShapReportModel report) {
    final predClass = report.predictedClass;
    final color = _getClassColor(predClass);
    final probPercent = (report.predictedProbability * 100).toStringAsFixed(1);
    final measurements = report.patientFeaturesUsed;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'Patient Triage Assessment',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$probPercent% PROBABILITY',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Large Category Label & Target Class Indicator
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                predClass.toUpperCase(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Explaining target class "${report.targetClass ?? predClass}"',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Probabilities distribution pills
          if (report.probabilities.isNotEmpty) ...[
            const Text(
              'Model Probability Distribution:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: report.probabilities.entries.map((entry) {
                final isTop = entry.key.toLowerCase() == predClass.toLowerCase();
                final pillColor = _getClassColor(entry.key);
                final val = (entry.value * 100).toStringAsFixed(1);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTop ? pillColor.withValues(alpha: 0.15) : AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: isTop ? Border.all(color: pillColor, width: 1.5) : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${entry.key}: $val%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isTop ? FontWeight.w800 : FontWeight.w500,
                      color: isTop ? pillColor : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Patient Measurements Summary Chips (where available)
          if (measurements != null && measurements.isNotEmpty) ...[
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Text(
              'Patient Measurements Evaluated:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (measurements.containsKey('oxygen_saturation'))
                  _buildVitalChip('SpO₂', '${measurements['oxygen_saturation']}%', isAlert: (measurements['oxygen_saturation'] as num) < 92),
                if (measurements.containsKey('systolic_bp') && measurements.containsKey('diastolic_bp'))
                  _buildVitalChip('BP', '${measurements['systolic_bp']}/${measurements['diastolic_bp']}', isAlert: (measurements['systolic_bp'] as num) >= 160),
                if (measurements.containsKey('heart_rate'))
                  _buildVitalChip('Heart Rate', '${measurements['heart_rate']} bpm', isAlert: (measurements['heart_rate'] as num) >= 120),
                if (measurements.containsKey('temperature_c'))
                  _buildVitalChip('Temp', '${measurements['temperature_c']}°C', isAlert: (measurements['temperature_c'] as num) >= 38.5),
                if (measurements.containsKey('breathlessness'))
                  _buildVitalChip('Dyspnea', measurements['breathlessness'] == 1 ? 'Yes' : 'No', isAlert: measurements['breathlessness'] == 1),
                if (measurements.containsKey('chest_pain'))
                  _buildVitalChip('Chest Pain', measurements['chest_pain'] == 1 ? 'Yes' : 'No', isAlert: measurements['chest_pain'] == 1),
                if (measurements.containsKey('age'))
                  _buildVitalChip('Age', '${measurements['age']} yrs'),
                if (measurements.containsKey('bmi'))
                  _buildVitalChip('BMI', '${measurements['bmi']}'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalChip(String label, String value, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFFEF2F2) : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: isAlert ? const Color(0xFFFCA5A5) : AppColors.border,
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: isAlert ? FontWeight.w800 : FontWeight.w600,
          color: isAlert ? const Color(0xFFB91C1C) : AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Simple Plain-Language Explanation for Users
  Widget _buildPlainLanguageExplanation(ShapReportModel report) {
    final predClass = report.predictedClass;
    final narrative = _generatePlainLanguageNarrative(report);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.avatarBg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.brandPurple, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plain-Language Summary: $predClass Prediction',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandPurpleDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  narrative,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: SHAP feature contributions reflect mathematical decision attributions by the model relative to baseline. They assist clinical decision-making and do not assert biological causality.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Synthesizes a clinically readable, plain-language narrative from actual SHAP contributions
  String _generatePlainLanguageNarrative(ShapReportModel report) {
    final predClass = report.predictedClass;
    final sorted = List<FeatureContributionItem>.from(report.explanation)
      ..sort((a, b) => b.shapValue.abs().compareTo(a.shapValue.abs()));

    final positiveItems = sorted.where((e) => e.isPositive && e.shapValue > 0.005).take(3).toList();
    final negativeItems = sorted.where((e) => e.isNegative && e.shapValue < -0.005).take(2).toList();

    final posNames = positiveItems.map((e) => _simplifiedFeatureName(e.feature)).toList();
    final negNames = negativeItems.map((e) => _simplifiedFeatureName(e.feature)).toList();

    final buffer = StringBuffer();
    buffer.write("The model's $predClass prediction was influenced most strongly by ");

    if (posNames.isNotEmpty) {
      if (posNames.length == 1) {
        buffer.write(posNames.first);
      } else {
        final last = posNames.removeLast();
        buffer.write('${posNames.join(", ")} and $last');
      }
      buffer.write(' (pushing towards $predClass)');
    } else {
      buffer.write('baseline demographic factors');
    }

    if (negNames.isNotEmpty) {
      buffer.write(', while ');
      if (negNames.length == 1) {
        buffer.write('${negNames.first} pushed away from $predClass');
      } else {
        final last = negNames.removeLast();
        buffer.write('${negNames.join(", ")} and $last pushed away from $predClass');
      }
    }
    buffer.write('.');

    return buffer.toString();
  }

  String _simplifiedFeatureName(String feature) {
    switch (feature) {
      case 'oxygen_saturation':
        return 'low oxygen saturation';
      case 'heart_rate':
        return 'elevated heart rate';
      case 'systolic_bp':
        return 'high blood pressure';
      case 'diastolic_bp':
        return 'diastolic blood pressure';
      case 'temperature_c':
        return 'elevated temperature';
      case 'breathlessness':
        return 'breathlessness';
      case 'chest_pain':
        return 'chest pain';
      case 'fever':
        return 'fever';
      case 'vomiting':
        return 'vomiting';
      case 'bmi':
        return 'body mass index';
      case 'age':
        return 'patient age';
      default:
        return feature.replaceAll('_', ' ');
    }
  }

  /// Collapsible Advanced SHAP Explanation Section (Original Waterfall Plot & Parameters)
  Widget _buildAdvancedCollapsibleSection(ShapReportModel report) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.galleryBg,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: const Icon(
                Icons.waterfall_chart_rounded,
                color: AppColors.hospitalEnd,
                size: 20,
              ),
            ),
            title: const Text(
              'Advanced SHAP Explanation',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Original waterfall plot & log-odds margin decomposition',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Text(
                'This advanced chart shows how individual features move the model output from its baseline towards the final prediction.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Original SHAP Waterfall Plot
              ShapWaterfallPlot(report: report),
              const SizedBox(height: 14),

              // Audit Parameters & Margin Decomposition
              _buildTransparencyCard(report),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransparencyCard(ShapReportModel report) {
    final imputed = report.imputedFeatures;
    final hasImputed = imputed.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_outlined, size: 16, color: AppColors.primaryStart),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Model Margin & Audit Parameters',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasImputed) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Omitted features populated using population defaults: ${imputed.join(", ")}.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Baseline Expected Value E[f(X)]:', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              Text(
                report.baseValue != null ? '${report.baseValue! >= 0 ? "+" : ""}${report.baseValue!.toStringAsFixed(4)}' : 'N/A',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Final Prediction Margin f(x):', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              Text(
                report.predictionMargin != null ? '${report.predictionMargin! >= 0 ? "+" : ""}${report.predictionMargin!.toStringAsFixed(4)}' : 'N/A',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Output Scale:', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              Text(
                report.outputScale ?? 'raw_margin',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getClassColor(String className) {
    switch (className.toLowerCase()) {
      case 'urgent':
        return AppColors.emergencyStart;
      case 'priority':
        return AppColors.warning;
      case 'standard':
      default:
        return AppColors.profileStart;
    }
  }
}
