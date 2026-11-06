import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hospital_model.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/view_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/url_launcher_helper.dart';
import '../../widgets/state_views.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyProvider>().loadNearbyHospitals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final emergency = context.watch<EmergencyProvider>();
    final state = emergency.hospitalsState;

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Hospitals')),
      body: Builder(builder: (_) {
        if (state.status == ViewStatus.loading) {
          return const LoadingView(message: 'Finding hospitals near you…');
        }
        if (state.isError) {
          return ErrorView(
            message: state.errorMessage ?? 'Could not load hospitals.',
            onRetry: () => emergency.loadNearbyHospitals(),
          );
        }
        if (state.isEmpty || (state.data?.isEmpty ?? true)) {
          return const EmptyView(
            message: 'No hospitals found nearby.',
            icon: Icons.local_hospital_outlined,
          );
        }

        final hospitals = state.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: hospitals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final hospital = hospitals[index];
            return _HospitalCard(
              hospital: hospital,
              onCall: () => UrlLauncherHelper.makePhoneCall(hospital.phone),
            );
          },
        );
      }),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final HospitalModel hospital;
  final VoidCallback onCall;

  const _HospitalCard({
    required this.hospital,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: hospital.hasEmergencyBeds
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEE2E2),
            child: Icon(
              Icons.local_hospital,
              color: hospital.hasEmergencyBeds
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  hospital.address,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${hospital.distanceKm} km away · ${hospital.hasEmergencyBeds ? "Beds available" : "No beds reported"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: hospital.hasEmergencyBeds
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCall,
            icon: const Icon(Icons.call, color: AppColors.primaryStart),
          ),
        ],
      ),
    );
  }
}
