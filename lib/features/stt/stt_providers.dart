import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'speech_transcription_service.dart';

final speechTranscriptionServiceProvider = Provider<SpeechTranscriptionService>(
  (ref) => SpeechTranscriptionService(),
);
