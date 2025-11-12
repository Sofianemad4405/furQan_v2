import 'dart:developer';

import 'package:furqan/core/di/get_it_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealTimeSubscription {
  RealTimeSubscription._();

  static final supabase = sl<SupabaseClient>();

  static RealtimeChannel subscribeToUserProgress({
    required void Function(Map<String, dynamic> newData) onUpdate,
  }) {
    final channel = supabase
        .channel('public:user_progress')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_progress',
          callback: (payload) {
            final data = payload.newRecord;
            if (data != null) {
              onUpdate(data);
            }
          },
        )
        .subscribe();

    return channel;
  }
}
