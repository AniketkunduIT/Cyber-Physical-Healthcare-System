import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/emergency_provider.dart';
import 'providers/medical_profile_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class MediRescueApp extends StatelessWidget {
  const MediRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MedicalProfileProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
      ],
      child: MaterialApp(
        title: 'MediRescue',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
