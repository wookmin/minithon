import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/functions/functions_client.dart';
import 'audio_transcription_service.dart';

final audioTranscriptionServiceProvider = Provider<AudioTranscriptionService>(
  (ref) =>
      AudioTranscriptionService(invoke: ref.watch(callableInvokerProvider)),
);
