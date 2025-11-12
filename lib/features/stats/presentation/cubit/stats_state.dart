part of 'stats_cubit.dart';

sealed class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object> get props => [];
}

final class StatsInitial extends StatsState {}

final class StatsLoading extends StatsState {}

final class StatsLoaded extends StatsState {
  final List<UserAchievement> userAchievements;
  final List<Achievement> achievements;

  const StatsLoaded({
    required this.userAchievements,
    required this.achievements,
  });
}

final class StatsError extends StatsState {
  final String error;

  StatsError({required this.error});
}
