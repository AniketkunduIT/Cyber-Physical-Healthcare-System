import 'package:flutter/material.dart';

import '../../../models/voice_note_model.dart';
import '../../../widgets/voice_note_card.dart';

/// List of recorded voice notes with playback waveform snapshot and deletion option.
class VoiceNotesListSection extends StatelessWidget {
  final List<VoiceNoteModel> voiceNotes;
  final ValueChanged<String> onDeleteVoiceNote;

  const VoiceNotesListSection({
    super.key,
    required this.voiceNotes,
    required this.onDeleteVoiceNote,
  });

  @override
  Widget build(BuildContext context) {
    if (voiceNotes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Voice notes',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14161F),
          ),
        ),
        const SizedBox(height: 10),
        ...voiceNotes.map(
          (note) => VoiceNoteCard(
            key: ValueKey(note.id),
            note: note,
            onDelete: () => onDeleteVoiceNote(note.id),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
