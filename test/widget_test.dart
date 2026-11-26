// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:medirescue/app.dart';
import 'package:medirescue/models/shap_report_model.dart';
import 'package:medirescue/providers/auth_provider.dart';
import 'package:medirescue/providers/emergency_provider.dart';
import 'package:medirescue/providers/medical_profile_provider.dart';
import 'package:medirescue/providers/shap_provider.dart';
import 'package:medirescue/screens/home/home_screen.dart';
import 'package:medirescue/screens/medical_profile/add_prescription_screen.dart';
import 'package:medirescue/screens/medical_profile/medical_profile_screen.dart';
import 'package:medirescue/screens/shap/widgets/shap_feature_bars.dart';
import 'package:medirescue/screens/shap/widgets/shap_waterfall_plot.dart';
import 'package:medirescue/widgets/voice_recording_sheet.dart';

void main() {
  testWidgets('App renders login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MediRescueApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('MedicalProfileScreen renders floating actions for voice and prescription',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MedicalProfileProvider()),
        ],
        child: const MaterialApp(
          home: MedicalProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A. Demographics'), findsOneWidget);
    expect(find.text('B. Emergency Type'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('AddPrescriptionScreen renders upload card, options, and form fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MedicalProfileProvider()),
        ],
        child: const MaterialApp(
          home: AddPrescriptionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('C. Add Prescription'), findsOneWidget);
    expect(find.text('Tap to upload prescription'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('prescription_01.jpg'), findsOneWidget);
    expect(find.text("Doctor's Name"), findsOneWidget);
    expect(find.text('Prescription Date'), findsOneWidget);
    expect(find.text('Medicines / Notes'), findsOneWidget);
    expect(find.text('SAVE PRESCRIPTION'), findsOneWidget);
  });

  testWidgets('VoiceRecordingSheet renders recording controls and timer',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VoiceRecordingSheet(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Recording...'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('HomeScreen renders SHAP Report button immediately below Nearby Hospitals',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MedicalProfileProvider()),
          ChangeNotifierProvider(create: (_) => EmergencyProvider()),
          ChangeNotifierProvider(create: (_) => ShapProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EMERGENCY'), findsOneWidget);
    expect(find.text('My Medical Profile'), findsOneWidget);
    expect(find.text('Nearby Hospitals'), findsOneWidget);
    expect(find.text('SHAP Report'), findsOneWidget);
    expect(find.text('Individual patient explainability & risk analysis'), findsOneWidget);
    expect(find.byIcon(Icons.auto_graph_rounded), findsOneWidget);
  });

  testWidgets('ShapWaterfallPlot renders baseline, feature steps, and final output',
      (WidgetTester tester) async {
    const report = ShapReportModel(
      status: 'success',
      predictedClass: 'Urgent',
      baseValue: 0.0676,
      targetClass: 'Urgent',
      outputScale: 'raw_margin',
      predictionMargin: 2.6239,
      probabilities: {'Standard': 0.008, 'Priority': 0.0207, 'Urgent': 0.9712},
      explanation: [
        FeatureContributionItem(feature: 'breathlessness', shapValue: 0.4829, direction: 'positive'),
        FeatureContributionItem(feature: 'chest_pain', shapValue: 0.4648, direction: 'positive'),
        FeatureContributionItem(feature: 'oxygen_saturation', shapValue: 0.4633, direction: 'positive'),
        FeatureContributionItem(feature: 'vomiting', shapValue: -0.0008, direction: 'negative'),
      ],
      emergencySafety: EmergencySafetyInfo(
        redFlagTriggered: true,
        redFlags: ['Critical Hypoxia: SpO2 < 90%'],
        clinicalAction: 'Immediate triage required.',
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShapWaterfallPlot(report: report),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SHAP Waterfall Plot'), findsOneWidget);
    expect(find.text('E[f(X)] Baseline'), findsOneWidget);
    expect(find.text('f(x) Final Margin'), findsOneWidget);
    expect(find.text('Breathlessness / Dyspnea'), findsOneWidget);
    expect(find.text('Chest Pain'), findsOneWidget);
    expect(find.text('Oxygen Saturation (SpO₂)'), findsOneWidget);
    expect(find.text('+0.4829'), findsOneWidget);
    expect(find.text('-0.0008'), findsOneWidget);
  });

  testWidgets('ShapFeatureBars renders title, diverging bars, and legend',
      (WidgetTester tester) async {
    const items = [
      FeatureContributionItem(feature: 'breathlessness', shapValue: 0.4807, direction: 'positive'),
      FeatureContributionItem(feature: 'oxygen_saturation', shapValue: 0.4773, direction: 'positive'),
      FeatureContributionItem(feature: 'chest_pain', shapValue: 0.4626, direction: 'positive'),
      FeatureContributionItem(feature: 'heart_rate', shapValue: 0.4569, direction: 'positive'),
      FeatureContributionItem(feature: 'systolic_bp', shapValue: 0.3648, direction: 'positive'),
      FeatureContributionItem(feature: 'vomiting', shapValue: -0.1250, direction: 'negative'),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShapFeatureBars(
              items: items,
              targetClass: 'Urgent',
              patientMeasurements: {
                'oxygen_saturation': 84.0,
                'heart_rate': 138,
                'systolic_bp': 180,
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Which factors influenced this prediction?'), findsOneWidget);
    expect(find.text('0.0 Reference'), findsOneWidget);
    expect(find.text('Breathlessness / Dyspnea'), findsOneWidget);
    expect(find.text('Show All 6 Factors'), findsOneWidget);
    expect(find.text('Model Contribution Magnitude Legend'), findsOneWidget);

    // Tap to expand all factors
    await tester.tap(find.text('Show All 6 Factors'));
    await tester.pumpAndSettle();

    expect(find.text('Show Top 5 Factors'), findsOneWidget);
    expect(find.text('Vomiting / Nausea'), findsOneWidget);
    expect(find.text('-0.1250'), findsOneWidget);
  });
}
