import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../classification/classification_providers.dart';
import 'audio_transcription_service.dart';

final audioTranscriptionServiceProvider = Provider<AudioTranscriptionService>(
  (ref) =>
      AudioTranscriptionService(config: ref.watch(geminiApiConfigProvider)),
);
