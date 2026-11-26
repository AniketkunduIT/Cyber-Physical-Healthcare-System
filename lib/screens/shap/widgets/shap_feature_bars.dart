import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/shap_report_model.dart';
import '../../../theme/app_theme.dart';

/// Primary Visualization: Simple Horizontal Diverging Feature Contribution Chart
/// Title: "Which factors influenced this prediction?"
class ShapFeatureBars extends StatefulWidget {
  final List<FeatureContributionItem> items;
  final String targetClass;
  final Map<String, dynamic>? patientMeasurements;

  const ShapFeatureBars({
    super.key,
    required this.items,
    required this.targetClass,
    this.patientMeasurements,
  });

  @override
  State<ShapFeatureBars> createState() => _ShapFeatureBarsState();
}

class _ShapFeatureBarsState extends State<ShapFeatureBars> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    // Sort by absolute SHAP value descending
    final sorted = List<FeatureContributionItem>.from(widget.items)
      ..sort((a, b) => b.shapValue.abs().compareTo(a.shapValue.abs()));

    final displayedItems = _showAll ? sorted : sorted.take(5).toList();

    // Max absolute SHAP value for scaling bars relative to actual contributions
    final maxAbs = sorted.fold<double>(
      0.0001,
      (prev, elem) => max(prev, elem.shapValue.abs()),
    );

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
          // Section Title & Clinical Subtitle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Icon(
                  Icons.balance_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Which factors influenced this prediction?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _showAll
                          ? 'Displaying all ${sorted.length} physiological features'
                          : 'Displaying top 5 most influential factors for ${widget.targetClass}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Common Zero Reference Axis Header
          _buildAxisGuide(),
          const SizedBox(height: 12),

          // Diverging Feature Contribution Bars
          ...displayedItems.map((item) => _buildDivergingBarRow(item, maxAbs)),

          const SizedBox(height: 10),

          // Expand / Collapse Toggle Button
          if (sorted.length > 5)
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryStart,
                  side: BorderSide(color: AppColors.primaryStart.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
                icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more, size: 18),
                label: Text(
                  _showAll ? 'Show Top 5 Factors' : 'Show All ${sorted.length} Factors',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                onPressed: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
              ),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Simple Contribution Scale & Legend
          _buildScaleLegend(),
        ],
      ),
    );
  }

  Widget _buildAxisGuide() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded, size: 13, color: Color(0xFFEA580C)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Pushes away from ${widget.targetClass}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEA580C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '0.0 Reference',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Pushes towards ${widget.targetClass}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF059669)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivergingBarRow(FeatureContributionItem item, double maxAbs) {
    final shapVal = item.shapValue;
    final isPos = shapVal > 0.0001;
    final isNeg = shapVal < -0.0001;
    final barColor = isPos
        ? const Color(0xFF10B981) // Green for positive contribution
        : isNeg
            ? const Color(0xFFEA580C) // Orange/Red for negative contribution
            : Colors.grey;

    final ratio = (shapVal.abs() / maxAbs).clamp(0.0, 1.0);
    final measurementText = _getMeasurementText(item.feature);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature Name & Actual SHAP Value
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.humanFeatureName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (measurementText.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        measurementText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.formattedValue,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Diverging Track with Common Center Zero Reference Line
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 14,
              width: double.infinity,
              color: Colors.grey.withValues(alpha: 0.08),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final halfWidth = totalWidth / 2;
                  final barWidth = halfWidth * ratio;

                  return Stack(
                    children: [
                      // Common Zero Reference Line in Exact Horizontal Center
                      Positioned(
                        left: halfWidth - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                      ),

                      // Negative Bar (extends left from center line)
                      if (isNeg && barWidth > 0)
                        Positioned(
                          right: halfWidth,
                          top: 1.5,
                          bottom: 1.5,
                          width: barWidth,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFEA580C),
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(3)),
                            ),
                          ),
                        ),

                      // Positive Bar (extends right from center line)
                      if (isPos && barWidth > 0)
                        Positioned(
                          left: halfWidth,
                          top: 1.5,
                          bottom: 1.5,
                          width: barWidth,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(3)),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Model Contribution Magnitude Legend',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendRow(
            color: const Color(0xFF10B981),
            title: 'Positive contribution (Green)',
            desc: 'Pushes prediction towards ${widget.targetClass}.',
          ),
          const SizedBox(height: 5),
          _buildLegendRow(
            color: const Color(0xFFEA580C),
            title: 'Negative contribution (Orange)',
            desc: 'Pushes prediction away from ${widget.targetClass}.',
          ),
          const SizedBox(height: 5),
          _buildLegendRow(
            color: Colors.grey,
            title: 'Near-zero contribution (Neutral)',
            desc: 'Little or no influence on this prediction.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Values represent additive feature contributions (|φᵢ|) in model margin space. They explain AI attribution and do not denote clinical risk percentages or disease causality.',
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow({
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 3, right: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '$title: ',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: desc,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMeasurementText(String feature) {
    final measurements = widget.patientMeasurements;
    if (measurements == null || !measurements.containsKey(feature)) return '';

    final val = measurements[feature];
    if (val == null) return '';

    switch (feature) {
      case 'oxygen_saturation':
        return '($val%)';
      case 'heart_rate':
        return '($val bpm)';
      case 'systolic_bp':
        return '($val mmHg)';
      case 'diastolic_bp':
        return '($val mmHg)';
      case 'temperature_c':
        return '($val°C)';
      case 'breathlessness':
      case 'chest_pain':
      case 'fever':
      case 'vomiting':
        return val == 1 ? '(Present)' : '(Absent)';
      case 'bmi':
        return '($val)';
      case 'age':
        return '($val yrs)';
      default:
        return '($val)';
    }
  }
}
