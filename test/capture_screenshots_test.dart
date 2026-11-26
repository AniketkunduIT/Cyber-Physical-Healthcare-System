import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:medirescue/models/medical_profile_model.dart';
import 'package:medirescue/models/shap_report_model.dart';
import 'package:medirescue/providers/auth_provider.dart';
import 'package:medirescue/providers/emergency_provider.dart';
import 'package:medirescue/providers/medical_profile_provider.dart';
import 'package:medirescue/providers/shap_provider.dart';
import 'package:medirescue/providers/view_state.dart';
import 'package:medirescue/screens/home/home_screen.dart';
import 'package:medirescue/screens/shap/shap_report_screen.dart';
import 'package:medirescue/theme/app_theme.dart';

class MockShapProvider extends ShapProvider {
  MockShapProvider(ShapReportModel mockReport) {
    injectReport(mockReport);
  }

  void injectReport(ShapReportModel report) {
    // ignore: invalid_use_of_protected_member
    _state = ViewState.success(report);
  }

  ViewState<ShapReportModel> _state = const ViewState.initial();
  @override
  ViewState<ShapReportModel> get state => _state;

  @override
  Future<void> generateReport({
    MedicalProfileModel? profile,
    Map<String, dynamic>? customOverrides,
    String? targetClass,
  }) async {
    // Mock: preserve injected report without HTTP call
  }

  @override
  Future<void> switchScenario({
    required bool isDemo,
    MedicalProfileModel? profile,
  }) async {
    // Mock: preserve injected report without HTTP call
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Capture Home Page and SHAP Report Screenshots', (tester) async {
    // 1. Setup screen size (Mobile portrait: 390x844)
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;

    final homeKey = GlobalKey();

    // 2. Render Home Page
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MedicalProfileProvider()),
          ChangeNotifierProvider(create: (_) => EmergencyProvider()),
          ChangeNotifierProvider(create: (_) => ShapProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          home: Scaffold(
            body: RepaintBoundary(
              key: homeKey,
              child: const HomeScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = homeKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final file = File('test/screenshots/home_page.png');
      await file.writeAsBytes(pngBytes);
    });

    // 3. Render SHAP Report Screen with sample Urgent patient
    final shapKey = GlobalKey();
    const mockReport = ShapReportModel(
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
        FeatureContributionItem(feature: 'heart_rate', shapValue: 0.4591, direction: 'positive'),
        FeatureContributionItem(feature: 'systolic_bp', shapValue: 0.3648, direction: 'positive'),
        FeatureContributionItem(feature: 'temperature_c', shapValue: 0.1223, direction: 'positive'),
        FeatureContributionItem(feature: 'age', shapValue: 0.1038, direction: 'positive'),
        FeatureContributionItem(feature: 'diastolic_bp', shapValue: 0.084, direction: 'positive'),
        FeatureContributionItem(feature: 'bmi', shapValue: 0.0121, direction: 'positive'),
        FeatureContributionItem(feature: 'vomiting', shapValue: -0.0008, direction: 'negative'),
        FeatureContributionItem(feature: 'fever', shapValue: 0.0, direction: 'neutral'),
      ],
      emergencySafety: EmergencySafetyInfo(
        redFlagTriggered: true,
        redFlags: [
          'Critical Hypoxia: SpO2 86.0% is below 90.0% (Risk of respiratory failure).',
          'Acute Cardiopulmonary Distress: Concomitant chest pain and breathlessness (Suspected ACS/PE).'
        ],
        clinicalAction: 'EMERGENCY PROTOCOL REQUIRED: Immediate clinical evaluation and triage escalation needed.',
        independentOfMl: true,
      ),
      safetyDisclaimer: 'Clinical Decision Support Only. SHAP values indicate model feature contributions relative to population baseline.',
    );

    final mockProvider = MockShapProvider(mockReport);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MedicalProfileProvider()),
          ChangeNotifierProvider<ShapProvider>.value(value: mockProvider),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          home: RepaintBoundary(
            key: shapKey,
            child: const ShapReportScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = shapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final file = File('test/screenshots/shap_report.png');
      await file.writeAsBytes(pngBytes);
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
