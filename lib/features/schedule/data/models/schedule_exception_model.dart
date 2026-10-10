import '../../domain/entities/schedule_exception.dart';
import 'weekly_schedule_model.dart';

class ScheduleExceptionModel extends ScheduleException {
  const ScheduleExceptionModel({
    required super.id,
    required super.barberId,
    required super.date,
    required super.isWorking,
    required super.startTime,
    required super.endTime,
    required super.breaks,
    super.reason,
  });

  factory ScheduleExceptionModel.fromSupabaseJson(Map<String, dynamic> row) {
    final rawBreaks = row['breaks'];

    final breaks = rawBreaks is List
        ? rawBreaks
              .whereType<Map>()
              .map(
                (item) =>
                    ScheduleBreakModel.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <ScheduleBreakModel>[];

    return ScheduleExceptionModel(
      id: row['id'] as String,
      barberId: row['barber_id'] as String,
      date: _parseDate(row['date']),
      isWorking: row['is_working'] as bool? ?? false,
      startTime: row['start_time'] as String? ?? '09:00',
      endTime: row['end_time'] as String? ?? '17:00',
      breaks: breaks,
      reason: row['reason'] as String?,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'barber_id': barberId,
      'date': _formatDate(date),
      'is_working': isWorking,
      'start_time': startTime,
      'end_time': endTime,
      'breaks': breaks
          .map((item) => ScheduleBreakModel.fromEntity(item).toMap())
          .toList(),
      'reason': reason,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Supabase returns `date` columns as `yyyy-MM-dd` strings.
  static DateTime _parseDate(Object? value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }

    if (value is String) {
      final parts = value.split('-');

      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }

      final parsed = DateTime.tryParse(value);

      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    throw StateError('Schedule exception has an invalid date: $value.');
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  factory ScheduleExceptionModel.fromEntity(ScheduleException exception) {
    return ScheduleExceptionModel(
      id: exception.id,
      barberId: exception.barberId,
      date: exception.date,
      isWorking: exception.isWorking,
      startTime: exception.startTime,
      endTime: exception.endTime,
      breaks: exception.breaks,
      reason: exception.reason,
    );
  }
}
