import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/emergency/ambulance_assigned_screen.dart';
import '../screens/emergency/confirm_location_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/hospitals/nearby_hospitals_screen.dart';
import '../screens/medical_profile/add_prescription_screen.dart';
import '../screens/medical_profile/medical_profile_screen.dart';

/// Centralized named route identifiers to prevent typos across navigation calls.
class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String medicalProfile = '/medical-profile';
  static const String addPrescription = '/add-prescription';
  static const String confirmLocation = '/confirm-location';
  static const String ambulanceAssigned = '/ambulance-assigned';
  static const String hospitals = '/hospitals';
}

/// Simple named-route generator with a shared slide+fade transition.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builders = <String, WidgetBuilder>{
      AppRoutes.root: (_) => const LoginScreen(),
      AppRoutes.login: (_) => const LoginScreen(),
      AppRoutes.signup: (_) => const SignupScreen(),
      AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
      AppRoutes.home: (_) => const HomeScreen(),
      AppRoutes.medicalProfile: (_) => const MedicalProfileScreen(),
      AppRoutes.addPrescription: (_) => const AddPrescriptionScreen(),
      AppRoutes.confirmLocation: (_) => const ConfirmLocationScreen(),
      AppRoutes.ambulanceAssigned: (_) => const AmbulanceAssignedScreen(),
      AppRoutes.hospitals: (_) => const NearbyHospitalsScreen(),
    };

    final builder = builders[settings.name] ?? (_) => const LoginScreen();

    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
