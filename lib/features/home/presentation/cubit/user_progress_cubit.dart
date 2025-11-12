import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:furqan/core/services/prefs.dart';
import 'package:furqan/core/supabase/real_time_subsctiption.dart';
import 'package:furqan/features/user_data/controller/user_data_controller.dart';
import 'package:furqan/features/user_data/models/daily_challenge_model.dart';
import 'package:furqan/features/user_data/models/user_daily_challenge.dart';
import 'package:furqan/features/user_data/models/user_progress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_progress_state.dart';

class UserProgressCubit extends Cubit<UserProgresState> {
  UserProgressCubit(this._userDataController, this.prefs)
    : userId = prefs.userId,
      super(UserProgressInitial()) {
    init();
  }

  final UserDataController _userDataController;
  final Prefs prefs;
  final String? userId;
  Timer? _debounceTimer;
  RealtimeChannel? _progressChannel;
  bool _isLoading = false;

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    // Unsubscribe realtime channel if any
    try {
      _progressChannel?.unsubscribe();
    } catch (_) {}
    _progressChannel = null;
    return super.close();
  }

  void init() {
    if (userId == null) {
      emit(const UserProgressError(message: 'User ID is not available'));
      return;
    }
    loadUserProgress();
    initRealtime(userId!);
  }

  String get getuserId => prefs.userId!;

  Future<UserProgress> getUserProgress() async {
    if (userId == null) {
      throw Exception('User ID is not available');
    }
    return await _userDataController.getUserProgress(userId!);
  }

  Future<void> loadUserProgress() async {
    if (_isLoading) return;
    _isLoading = true;
    emit(UserProgressLoading());

    try {
      log('Loading user progress for userId: $userId');

      final userProgress = await _userDataController.getUserProgress(userId!);
      log("UserProgress Loaded: $userProgress");

      final dailyChallengesRaw = await _userDataController.getDailyChallenges();
      log("Daily Challenges Raw: ${dailyChallengesRaw[0].description}");
      final todayChallenges = dailyChallengesRaw.cast<DailyChallengeModel>();
      final userDailyRaw = await _userDataController
          .getUserDailyChallengesProgress(userId!);
      log("User Daily Progress Raw: $userDailyRaw");
      final userDailyChallengesProgress = userDailyRaw.toList();

      emit(
        UserProgressLoaded(
          userProgress: userProgress,
          todayChallenges: todayChallenges,
          userDailyChallenges: userDailyChallengesProgress,
        ),
      );
    } catch (e, stack) {
      log('Error in loadUserProgress: $e', error: e, stackTrace: stack);
      emit(UserProgressError(message: 'Failed to load user progress: $e'));
      throw Exception('Failed to load user progress: $e');
    } finally {
      _isLoading = false;
    }
  }

  void initRealtime(String userId) {
    _progressChannel = RealTimeSubscription.subscribeToUserProgress(
      onUpdate: (newData) {
        final currentState = state;

        final updatedProgress = UserProgress.fromJson(newData);

        if (currentState is UserProgressLoaded) {
          emit(
            UserProgressLoaded(
              userProgress: updatedProgress,
              todayChallenges: currentState.todayChallenges,
              userDailyChallenges: currentState.userDailyChallenges,
            ),
          );
        }
      },
    );
  }

  Future<void> updateUserData(Map<String, dynamic> updates) async {
    if (userId == null) return;

    // Cancel any pending update
    _debounceTimer?.cancel();

    // Start a new timer - will wait 500ms before executing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      // This code only runs after 500ms of no new updates
      try {
        if (state is! UserProgressLoaded) return;
        final currentState = state as UserProgressLoaded;

        // Optimistically update the state
        final updatedUser = _getUpdatedUserProgress(
          currentState.userProgress,
          updates,
        );
        emit(
          UserProgressLoaded(
            userProgress: updatedUser,
            todayChallenges: currentState.todayChallenges,
            userDailyChallenges: currentState.userDailyChallenges,
          ),
        );

        // Perform the actual update
        await _userDataController.updateUserProgress(userId!, updates);
      } catch (e, stack) {
        log('Error updating user data', error: e, stackTrace: stack);
        emit(UserProgressError(message: 'Failed to update: $e'));
        // Reload data on error to ensure consistency
        loadUserProgress();
      }
    });
  }

  UserProgress _getUpdatedUserProgress(
    UserProgress current,
    Map<String, dynamic> updates,
  ) {
    return current.copyWith(
      totalHassanat: updates['total_hassanat'] ?? current.totalHassanat,
      surahsRead: updates['surahs_read'] ?? current.surahsRead,
      readingMinutes: updates['reading_minutes'] ?? current.readingMinutes,
      duasRecited: updates['duas_recited'] ?? current.duasRecited,
      zikrCount: updates['zikr_count'] ?? current.zikrCount,
      ayahsRead: updates['ayahs_read'] ?? current.ayahsRead,
      currentStreak: updates['current_streak'] ?? current.currentStreak,
      bestStreak: updates['best_streak'] ?? current.bestStreak,
      dailyChallenges: updates['daily_challenges'] ?? current.dailyChallenges,
      surahsReadIds: updates['surahs_read_ids'] ?? current.surahsReadIds,
      likedAyahs: updates['liked_ayahs'] ?? current.likedAyahs,
      weeklyHassanat: updates['weekly_hassanat'] ?? current.weeklyHassanat,
      updatedAt: DateTime.now(),
    );
  }

  void toggleAyahLike(int surah, int ayah) {
    final currentState = state;

    if (currentState is! UserProgressLoaded) return;

    final progress = currentState.userProgress;

    final newLikes = Map<String, dynamic>.from(progress.likedAyahs);

    final surahKey = surah.toString();
    final list = List<int>.from(newLikes[surahKey] ?? []);

    if (list.contains(ayah)) {
      list.remove(ayah);
    } else {
      list.add(ayah);
    }

    newLikes[surahKey] = list;

    final newProgress = progress.copyWith(likedAyahs: newLikes);

    emit(
      UserProgressLoaded(
        userProgress: newProgress,
        todayChallenges: currentState.todayChallenges,
        userDailyChallenges: currentState.userDailyChallenges,
      ),
    );
  }

  Future<List<DailyChallengeModel>> getDailyChallenges() async {
    return await _userDataController.getDailyChallenges();
  }

  Future<List<UserDailyChallenge>> getUserDailyChallengesProgress() async {
    return await _userDataController.getUserDailyChallengesProgress(userId!);
  }
}
