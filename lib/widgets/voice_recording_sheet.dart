import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/voice_note_model.dart';
import '../services/api_config.dart';
import '../services/audio_recorder_helper.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class VoiceRecordingSheet extends StatefulWidget {
  final ValueChanged<VoiceNoteModel>? onSaved;

  const VoiceRecordingSheet({super.key, this.onSaved});

  static Future<VoiceNoteModel?> show(BuildContext context) {
    return showModalBottomSheet<VoiceNoteModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const VoiceRecordingSheet(),
    );
  }

  @override
  State<VoiceRecordingSheet> createState() => _VoiceRecordingSheetState();
}

enum _RecordState { recording, paused, stopped }

class _VoiceRecordingSheetState extends State<VoiceRecordingSheet>
    with SingleTickerProviderStateMixin {
  _RecordState _recordState = _RecordState.recording;
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _animController;
  bool _isUploading = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordedFilePath;

  final List<double> _baseHeights = [
    8, 14, 22, 34, 46, 30, 18, 42, 52, 36, 24, 48,
    50, 26, 18, 38, 44, 28, 16, 32, 22, 14, 20, 10
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _initAndStartRecording();
  }

  Future<void> _initAndStartRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        String path = '';
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          path = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';
        }
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
          path: path,
        );
        _recordedFilePath = path;
      }
    } catch (e) {
      debugPrint('Real microphone recorder initialization: $e');
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_recordState == _RecordState.recording) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  Future<void> _togglePause() async {
    try {
      if (_recordState == _RecordState.recording) {
        await _audioRecorder.pause();
        setState(() {
          _recordState = _RecordState.paused;
          _animController.stop();
        });
      } else if (_recordState == _RecordState.paused) {
        await _audioRecorder.resume();
        setState(() {
          _recordState = _RecordState.recording;
          _animController.repeat(reverse: true);
        });
      }
    } catch (e) {
      debugPrint('Toggle pause error: $e');
      setState(() {
        if (_recordState == _RecordState.recording) {
          _recordState = _RecordState.paused;
          _animController.stop();
        } else if (_recordState == _RecordState.paused) {
          _recordState = _RecordState.recording;
          _animController.repeat(reverse: true);
        }
      });
    }
  }

  Future<void> _stop() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null && path.isNotEmpty) {
        _recordedFilePath = path;
      }
    } catch (e) {
      debugPrint('Stop audio recorder error: $e');
    }
    setState(() {
      _recordState = _RecordState.stopped;
      _animController.stop();
      _timer?.cancel();
    });
  }

  Future<void> _send() async {
    if (_isUploading) return;
    _timer?.cancel();
    setState(() => _isUploading = true);

    final safeDuration = max(1, _seconds);
    String audioId = 'vn_${DateTime.now().millisecondsSinceEpoch}';
    DateTime recordedTime = DateTime.now();

    try {
      // If still recording, stop to complete file writing
      if (await _audioRecorder.isRecording()) {
        final path = await _audioRecorder.stop();
        if (path != null && path.isNotEmpty) {
          _recordedFilePath = path;
        }
      }

      Uint8List? audioBytes;
      if (_recordedFilePath != null && _recordedFilePath!.isNotEmpty) {
        if (kIsWeb) {
          try {
            final res = await http.get(Uri.parse(_recordedFilePath!));
            if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
              audioBytes = res.bodyBytes;
            }
          } catch (e) {
            debugPrint('Error reading web blob: $e');
          }
        } else {
          try {
            final file = File(_recordedFilePath!);
            if (await file.exists()) {
              audioBytes = await file.readAsBytes();
            }
          } catch (e) {
            debugPrint('Error reading file from disk: $e');
          }
        }
      }

      // Fallback only if device has no microphone or mic was not accessible
      if (audioBytes == null || audioBytes.isEmpty) {
        audioBytes = AudioRecorderHelper.createRawWavFile(durationSeconds: safeDuration);
      }

      final uploadUri = Uri.parse('${ApiConfig.baseUrl}/api/audio/upload');
      final request = http.MultipartRequest('POST', uploadUri);

      if (ApiConfig.authToken != null && ApiConfig.authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${ApiConfig.authToken}';
      }

      request.fields['duration_seconds'] = safeDuration.toString();
      request.fields['patient_id'] = 'P7f8016c0';
      request.fields['store_as_mp3'] = 'true';

      final filename = 'voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: filename,
          contentType: MediaType('audio', 'wav'),
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        audioId = data['audio_id'] as String? ?? audioId;
        if (data['recorded_at'] != null) {
          recordedTime = DateTime.tryParse(data['recorded_at'] as String) ?? recordedTime;
        }
      }
    } catch (e) {
      debugPrint('Error uploading recorded voice note: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }

    final note = VoiceNoteModel(
      id: audioId,
      durationSeconds: safeDuration,
      recordedAt: recordedTime,
    );

    widget.onSaved?.call(note);
    if (mounted) {
      Navigator.of(context).pop(note);
    }
  }

  Future<void> _delete() async {
    _timer?.cancel();
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
      if (_recordedFilePath != null && !kIsWeb) {
        final file = File(_recordedFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  String get _formattedTime => Formatters.formatDuration(_seconds);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row: Status and Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _recordState == _RecordState.recording
                            ? const Color(0xFFE11D48)
                            : (_recordState == _RecordState.paused
                                ? AppColors.warning
                                : AppColors.textSecondary),
                        shape: BoxShape.circle,
                        boxShadow: _recordState == _RecordState.recording
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _recordState == _RecordState.recording
                          ? 'Recording...'
                          : (_recordState == _RecordState.paused
                              ? 'Paused'
                              : 'Stopped'),
                      style: TextStyle(
                        color: _recordState == _RecordState.recording
                            ? const Color(0xFFE11D48)
                            : (_recordState == _RecordState.paused
                                ? AppColors.warning
                                : AppColors.textSecondary),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Animated Audio Waveform
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_baseHeights.length, (index) {
                      final base = _baseHeights[index];
                      final factor = _recordState == _RecordState.recording
                          ? (0.5 + 0.5 * sin((index + _animController.value * 6)))
                          : (_recordState == _RecordState.paused ? 0.4 : 0.2);
                      final h = (base * factor).clamp(6.0, 52.0);

                      return Container(
                        width: 3.5,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Timer display
            Text(
              _formattedTime,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B4B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 28),

            // 3 Action Buttons Row: Pause/Resume, Stop/Delete, Save
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pause / Resume — hidden (but space preserved) when stopped
                Visibility(
                  visible: _recordState != _RecordState.stopped,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _buildActionButton(
                    onTap: _togglePause,
                    button: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: AppColors.lightPurple,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _recordState == _RecordState.paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: const Color(0xFF6D28D9),
                        size: 26,
                      ),
                    ),
                    label: _recordState == _RecordState.paused ? 'Resume' : 'Pause',
                  ),
                ),

                // Stop Button -> Delete Button after stopping
                _buildActionButton(
                  onTap: _recordState != _RecordState.stopped ? _stop : _delete,
                  button: Container(
                    width: 68,
                    height: 68,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _recordState == _RecordState.stopped
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFFE4E6),
                      border: Border.all(
                        color: _recordState == _RecordState.stopped
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFFECDD3),
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _recordState == _RecordState.stopped
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFE11D48),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _recordState == _RecordState.stopped
                              ? Icons.delete_rounded
                              : Icons.stop_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  label: _recordState == _RecordState.stopped ? 'Delete' : 'Stop',
                ),

                // Save Button (formerly Send)
                _buildActionButton(
                  onTap: (_seconds > 0 && !_isUploading) ? _send : null,
                  button: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPurple,
                      shape: BoxShape.circle,
                    ),
                    child: _isUploading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                  label: 'Save',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onTap,
    required Widget button,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
