import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:furqan/core/services/prefs.dart';
import 'package:furqan/features/stats/data/models/achievement.dart';
import 'package:furqan/features/stats/data/models/user_achievement.dart';
import 'package:furqan/features/user_data/controller/user_data_controller.dart';

part 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._userDataController, this.prefs)
    : userId = prefs.userId,
      super(StatsInitial());
  final UserDataController _userDataController;
  final Prefs prefs;
  String? userId;

  void loadAchievements() async {
    emit(StatsLoading());
    try {
      final achievements = await _userDataController.getAchievementsMetaData();
      final userAchievements = await _userDataController.getUserAchievements(
        userId!,
      );
      emit(
        StatsLoaded(
          userAchievements: userAchievements,
          achievements: achievements,
        ),
      );
    } catch (e) {
      emit(StatsError(error: "ususus ${e.toString()}"));
    }
  }
}
