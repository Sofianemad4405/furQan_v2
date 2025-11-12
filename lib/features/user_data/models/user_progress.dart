class UserProgress {
  final String userId;
  final int totalHassanat;
  final int surahsRead;
  final int readingMinutes;
  final int duasRecited;
  final int zikrCount;
  final int ayahsRead;
  final int currentStreak;
  final int bestStreak;
  final List<int> surahsReadIds;
  final Map<String, Map<String, int>> dailyChallenges;
  final Map<String, Map<String, dynamic>> weeklyHassanat;
  final Map<String, dynamic> likedAyahs;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProgress({
    this.userId = "",
    this.totalHassanat = 0,
    this.surahsRead = 0,
    this.readingMinutes = 0,
    this.duasRecited = 0,
    this.zikrCount = 0,
    this.ayahsRead = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.surahsReadIds = const [],
    this.dailyChallenges = const {},
    this.weeklyHassanat = const {},
    this.likedAyahs = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  UserProgress copyWith({
    String? userId,
    int? totalHassanat,
    int? surahsRead,
    int? readingMinutes,
    int? duasRecited,
    int? zikrCount,
    int? ayahsRead,
    int? currentStreak,
    int? bestStreak,
    List<int>? surahsReadIds,
    Map<String, Map<String, int>>? dailyChallenges,
    Map<String, Map<String, dynamic>>? weeklyHassanat,
    Map<String, dynamic>? likedAyahs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      totalHassanat: totalHassanat ?? this.totalHassanat,
      surahsRead: surahsRead ?? this.surahsRead,
      readingMinutes: readingMinutes ?? this.readingMinutes,
      duasRecited: duasRecited ?? this.duasRecited,
      zikrCount: zikrCount ?? this.zikrCount,
      ayahsRead: ayahsRead ?? this.ayahsRead,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      surahsReadIds: surahsReadIds ?? this.surahsReadIds,
      dailyChallenges: dailyChallenges ?? this.dailyChallenges,
      weeklyHassanat: weeklyHassanat ?? this.weeklyHassanat,
      likedAyahs: likedAyahs ?? this.likedAyahs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    // helper: parse map-like dynamic to Map<String, Map<String,int>>
    Map<String, Map<String, int>> _parseDaily(dynamic raw) {
      final Map<String, Map<String, int>> out = {};
      if (raw is Map) {
        raw.forEach((k, v) {
          if (v is Map) {
            out[k.toString()] = v.map<String, int>((ik, iv) {
              final intVal = (iv is num)
                  ? iv.toInt()
                  : int.tryParse(iv?.toString() ?? '') ?? 0;
              return MapEntry(ik.toString(), intVal);
            });
          }
        });
      } else if (raw is List) {
        for (var item in raw) {
          if (item is Map) {
            // common shapes: { "name": "...", "count": 3 } or { "challengeId": count }
            if (item.containsKey('name') && item.containsKey('completed')) {
              final name = item['name'].toString();
              final completed = (item['completed'] is num)
                  ? (item['completed'] as num).toInt()
                  : int.tryParse(item['completed']?.toString() ?? '') ?? 0;
              out[name] = {'completed': completed};
            } else if (item.length == 1) {
              final k = item.keys.first.toString();
              final v = item.values.first;
              final intVal = (v is num)
                  ? v.toInt()
                  : int.tryParse(v?.toString() ?? '') ?? 0;
              out[k] = {'count': intVal};
            }
          }
        }
      }
      return out;
    }

    Map<String, Map<String, dynamic>> _parseWeekly(dynamic raw) {
      final Map<String, Map<String, dynamic>> out = {};
      if (raw is Map) {
        raw.forEach((k, v) {
          if (v is Map) {
            out[k.toString()] = Map<String, dynamic>.from(v);
          } else {
            out[k.toString()] = {'value': v};
          }
        });
      } else if (raw is List) {
        for (var item in raw) {
          if (item is Map) {
            if (item.containsKey('day')) {
              final key = item['day'].toString();
              out[key] = Map<String, dynamic>.from(item);
            } else if (item.length == 1) {
              final k = item.keys.first.toString();
              out[k] = {'value': item.values.first};
            }
          }
        }
      }
      return out;
    }

    DateTime _parseDate(dynamic raw, DateTime fallback) {
      if (raw == null) return fallback;
      try {
        return DateTime.parse(raw.toString());
      } catch (_) {
        return fallback;
      }
    }

    return UserProgress(
      userId: (json['user_id'] ?? '').toString(),
      totalHassanat: (json['total_hassanat'] is num)
          ? (json['total_hassanat'] as num).toInt()
          : int.tryParse((json['total_hassanat'] ?? '0').toString()) ?? 0,
      surahsRead: (json['surahs_read'] is num)
          ? (json['surahs_read'] as num).toInt()
          : int.tryParse((json['surahs_read'] ?? '0').toString()) ?? 0,
      readingMinutes: (json['reading_minutes'] is num)
          ? (json['reading_minutes'] as num).toInt()
          : int.tryParse((json['reading_minutes'] ?? '0').toString()) ?? 0,
      duasRecited: (json['duas_recited'] is num)
          ? (json['duas_recited'] as num).toInt()
          : int.tryParse((json['duas_recited'] ?? '0').toString()) ?? 0,
      zikrCount: (json['zikr_count'] is num)
          ? (json['zikr_count'] as num).toInt()
          : int.tryParse((json['zikr_count'] ?? '0').toString()) ?? 0,
      ayahsRead: (json['ayahs_read'] is num)
          ? (json['ayahs_read'] as num).toInt()
          : int.tryParse((json['ayahs_read'] ?? '0').toString()) ?? 0,
      currentStreak: (json['current_streak'] is num)
          ? (json['current_streak'] as num).toInt()
          : int.tryParse((json['current_streak'] ?? '0').toString()) ?? 0,
      bestStreak: (json['best_streak'] is num)
          ? (json['best_streak'] as num).toInt()
          : int.tryParse((json['best_streak'] ?? '0').toString()) ?? 0,
      surahsReadIds:
          (json['surahs_read_ids'] as List<dynamic>?)
              ?.map(
                (e) => (e is num)
                    ? e.toInt()
                    : int.tryParse(e?.toString() ?? '') ?? 0,
              )
              .toList() ??
          [],
      dailyChallenges: _parseDaily(json['today_challenges']),
      weeklyHassanat: _parseWeekly(json['weekly_hassanat']),
      likedAyahs: Map<String, dynamic>.from(json['liked_ayahs'] ?? {}),
      createdAt: _parseDate(json['created_at'], DateTime.now()),
      updatedAt: _parseDate(json['updated_at'], DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_hassanat': totalHassanat,
      'surahs_read': surahsRead,
      'reading_minutes': readingMinutes,
      'duas_recited': duasRecited,
      'zikr_count': zikrCount,
      'ayahs_read': ayahsRead,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'surahs_read_ids': surahsReadIds,
      'today_challenges': dailyChallenges.map(
        (k, v) => MapEntry(k, v.map((ik, iv) => MapEntry(ik.toString(), iv))),
      ),
      'weekly_hassanat': weeklyHassanat.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v)),
      ),
      'liked_ayahs': likedAyahs,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
