import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/shap_report_model.dart';
import '../../../theme/app_theme.dart';

class ShapWaterfallPlot extends StatelessWidget {
  final ShapReportModel report;

  const ShapWaterfallPlot({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final baseVal = report.baseValue ?? 0.0;
    final explanations = report.explanation;
    final targetClass = report.targetClass ?? report.predictedClass;

    // Calculate cumulative step points for the waterfall
    double runningTotal = baseVal;
    final steps = <_WaterfallStep>[];

    for (final item in explanations) {
      final start = runningTotal;
      runningTotal += item.shapValue;
      final end = runningTotal;
      steps.add(_WaterfallStep(
        feature: item,
        startVal: start,
        endVal: end,
      ));
    }

    final finalOutput = report.predictionMargin ?? runningTotal;

    // Determine scale bounds (min and max across baseline, all step totals, and final)
    double minVal = baseVal;
    double maxVal = baseVal;

    for (final step in steps) {
      minVal = min(minVal, min(step.startVal, step.endVal));
      maxVal = max(maxVal, max(step.startVal, step.endVal));
    }
    minVal = min(minVal, finalOutput);
    maxVal = max(maxVal, finalOutput);

    // Add 10% breathing room to left and right
    final span = max(0.6, maxVal - minVal);
    final plotMin = minVal - (span * 0.12);
    final plotMax = maxVal + (span * 0.12);

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.avatarBg,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.waterfall_chart_rounded,
                  color: AppColors.primaryStart,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SHAP Waterfall Plot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Individual patient contributions for class: $targetClass',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTargetBadge(targetClass),
            ],
          ),

          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLegendDot(const Color(0xFFEF4444), 'Pushes toward $targetClass (+)'),
              _buildLegendDot(const Color(0xFF3B82F6), 'Pushes away (-)'),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Baseline E[f(X)] Header Row
          _buildSpecialRow(
            label: 'E[f(X)] Baseline',
            subtitle: 'Model expected value',
            value: baseVal,
            plotMin: plotMin,
            plotMax: plotMax,
            color: const Color(0xFF6B7280),
            icon: Icons.flag_outlined,
          ),

          const SizedBox(height: 8),

          // Waterfall Bars
          ...steps.map((step) => _buildStepRow(
                step: step,
                plotMin: plotMin,
                plotMax: plotMax,
              )),

          const SizedBox(height: 8),

          // Final Output f(x) Row
          _buildSpecialRow(
            label: 'f(x) Final Margin',
            subtitle: 'Output before softmax',
            value: finalOutput,
            plotMin: plotMin,
            plotMax: plotMax,
            color: _getClassColor(targetClass),
            icon: Icons.check_circle_outline,
            isFinal: true,
          ),

          const SizedBox(height: 14),

          // Bottom Axis Guide
          _buildScaleAxis(plotMin, plotMax),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required _WaterfallStep step,
    required double plotMin,
    required double plotMax,
  }) {
    final item = step.feature;
    final isPos = item.isPositive;
    final barColor = isPos ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

    final leftFraction = ((min(step.startVal, step.endVal) - plotMin) / (plotMax - plotMin)).clamp(0.0, 1.0);
    final rightFraction = ((max(step.startVal, step.endVal) - plotMin) / (plotMax - plotMin)).clamp(0.0, 1.0);
    final widthFraction = max(0.015, rightFraction - leftFraction);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Feature Name Label
          SizedBox(
            width: 110,
            child: Text(
              item.humanFeatureName,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Waterfall Bar Track
          Expanded(
            child: SizedBox(
              height: 22,
              child: Stack(
                children: [
                  // Zero/Center Reference Line
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ZeroLinePainter(
                        zeroFraction: ((0.0 - plotMin) / (plotMax - plotMin)).clamp(0.0, 1.0),
                      ),
                    ),
                  ),

                  // Floating Waterfall Bar
                  Align(
                    alignment: Alignment(
                      (leftFraction * 2.0) - 1.0 + widthFraction,
                      0,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widthFraction,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.35),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Numeric SHAP value tag
          SizedBox(
            width: 60,
            child: Text(
              item.formattedValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: barColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialRow({
    required String label,
    required String subtitle,
    required double value,
    required double plotMin,
    required double plotMax,
    required Color color,
    required IconData icon,
    bool isFinal = false,
  }) {
    final fraction = ((value - plotMin) / (plotMax - plotMin)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: isFinal
          ? BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isFinal ? FontWeight.w800 : FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 20,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Dotted guide line across track
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  // Value marker pin
                  Positioned(
                    left: null,
                    right: null,
                    child: Align(
                      alignment: Alignment((fraction * 2.0) - 1.0, 0),
                      child: Container(
                        width: isFinal ? 12 : 8,
                        height: isFinal ? 12 : 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              value >= 0 ? '+${value.toStringAsFixed(4)}' : value.toStringAsFixed(4),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isFinal ? FontWeight.w800 : FontWeight.w700,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleAxis(double minVal, double maxVal) {
    return Column(
      children: [
        Container(
          height: 1,
          color: Colors.grey.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minVal.toStringAsFixed(1),
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            const Expanded(
              child: Text(
                'Output Space (Log-Odds Margin)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
            Text(
              maxVal.toStringAsFixed(1),
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetBadge(String targetClass) {
    final color = _getClassColor(targetClass);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        targetClass.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
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

class _WaterfallStep {
  final FeatureContributionItem feature;
  final double startVal;
  final double endVal;

  _WaterfallStep({
    required this.feature,
    required this.startVal,
    required this.endVal,
  });
}

class _ZeroLinePainter extends CustomPainter {
  final double zeroFraction;

  _ZeroLinePainter({required this.zeroFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    final x = size.width * zeroFraction;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(_ZeroLinePainter oldDelegate) =>
      oldDelegate.zeroFraction != zeroFraction;
}
