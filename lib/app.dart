import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'core/theme/app_theme.dart';
import 'features/recording/shared_audio_providers.dart';

class SeniorNeedsApp extends ConsumerStatefulWidget {
  const SeniorNeedsApp({super.key, required this.router});

  final GoRouter router;

  @override
  ConsumerState<SeniorNeedsApp> createState() => _SeniorNeedsAppState();
}

class _SeniorNeedsAppState extends ConsumerState<SeniorNeedsApp> {
  static const _audioExtensions = [
    'm4a',
    'mp3',
    'wav',
    'aac',
    'amr',
    '3gp',
    'flac',
    'ogg',
    'caf',
  ];

  StreamSubscription<List<SharedMediaFile>>? _subscription;

  @override
  void initState() {
    super.initState();
    // 공유 시트로 오디오가 들어오면 통화 분석으로 흘린다. (모바일 전용)
    if (Platform.isIOS || Platform.isAndroid) {
      _setupSharing();
    }
  }

  void _setupSharing() {
    try {
      _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
        _handleShared,
        onError: (_) {},
      );
      ReceiveSharingIntent.instance.getInitialMedia().then((files) {
        _handleShared(files);
        ReceiveSharingIntent.instance.reset();
      });
    } on Object {
      // 공유 기능을 쓸 수 없는 환경은 조용히 무시한다.
    }
  }

  void _handleShared(List<SharedMediaFile> files) {
    final audio = files.where(_isAudio).toList();
    if (audio.isEmpty) return;
    ref.read(sharedAudioPathProvider.notifier).set(audio.first.path);
    widget.router.go('/call-analysis?shared=1');
  }

  bool _isAudio(SharedMediaFile file) {
    if (file.mimeType?.startsWith('audio') ?? false) return true;
    final lower = file.path.toLowerCase();
    return _audioExtensions.any((ext) => lower.endsWith('.$ext'));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '똥강아지',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: widget.router,
    );
  }
}
