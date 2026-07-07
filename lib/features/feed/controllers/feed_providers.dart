import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/context_engine_service.dart';
import '../../learning/models/lesson_model.dart';
import '../../learning/repositories/learning_repository.dart';
import '../../auth/repositaries/auth_repository.dart';

// Provides the singleton ContextEngineService, disposed when no longer watched
final contextEngineProvider = Provider.autoDispose<ContextEngineService>((ref) {
  final service = ContextEngineService();
  // ContextEngineService does not expose a public dispose(); it stops listening when the last listener cancels.
  ref.onDispose(() {});
  return service;
});

// StreamProvider that exposes the live UserContextState from the engine
final contextStateStreamProvider = StreamProvider<UserContextState>((ref) {
  final engine = ref.watch(contextEngineProvider);
  return engine.contextStream;
});

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(Supabase.instance.client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// FutureProvider.family that fetches filtered lessons given a UserContextState
final adaptiveLessonFeedProvider =
    FutureProvider.family.autoDispose<List<LessonModel>, UserContextState>(
        (ref, contextState) async {
  final repo = ref.watch(learningRepositoryProvider);
  final userUuid = Supabase.instance.client.auth.currentUser?.id;
  if (userUuid == null) return <LessonModel>[];

  final adaptive = await repo.fetchAdaptiveViewportFeed(
    userUuid: userUuid,
    ambientContext: contextState,
  );

  if (adaptive.isNotEmpty) return adaptive;
  return repo.fetchAvailableLessonsPreview();
});


