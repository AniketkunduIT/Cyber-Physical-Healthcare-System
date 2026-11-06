import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/emergency_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_screen_header.dart';
import '../../widgets/mock_map_background.dart';
import '../../widgets/primary_button.dart';

class ConfirmLocationScreen extends StatelessWidget {
  const ConfirmLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emergency = context.watch<EmergencyProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppScreenHeader(title: 'Confirm your location'),
              const SizedBox(height: 18),
              Expanded(
                child: MockMapBackground(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 40,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xF01C1F2A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'GPS shows you here.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Drag map to adjust if incorrect.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: AppColors.emergencyStart,
                        size: 46,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'CONFIRM & REQUEST',
                gradientColors: AppColors.emergencyGradient,
                onPressed: () {
                  emergency.updateConfirmedLocation(12.9352, 77.6146);
                  Navigator.of(context).pushReplacementNamed(
                    AppRoutes.ambulanceAssigned,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
