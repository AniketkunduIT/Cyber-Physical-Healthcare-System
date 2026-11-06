import 'package:flutter/material.dart';

import '../../../models/emergency_type_model.dart';
import '../../../widgets/emergency_type_card.dart';

/// Grid catalogue displaying selectable emergency categories.
class EmergencyTypeGridSection extends StatelessWidget {
  final String? selectedEmergencyTypeId;
  final ValueChanged<String> onSelectType;

  const EmergencyTypeGridSection({
    super.key,
    required this.selectedEmergencyTypeId,
    required this.onSelectType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(
          child: Text(
            'B. Emergency Type',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14161F),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: EmergencyTypes.all.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (context, index) {
            final type = EmergencyTypes.all[index];
            return EmergencyTypeCard(
              type: type,
              selected: selectedEmergencyTypeId == type.id,
              onTap: () => onSelectType(type.id),
            );
          },
        ),
      ],
    );
  }
}
