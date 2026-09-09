import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ScheduleExceptionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document, {
    required String barberId,
  }) {
    final data = document.data();

    if (data == null) {
      throw StateError(
        'Schedule exception document ${document.id} does not exist.',
      );
    }

    final rawBreaks = data['breaks'];

    final breaks = rawBreaks is List
        ? rawBreaks
              .whereType<Map<String, dynamic>>()
              .map(ScheduleBreakModel.fromMap)
              .toList()
        : <ScheduleBreakModel>[];

    final timestamp = data['date'];

    if (timestamp is! Timestamp) {
      throw StateError(
        'Schedule exception ${document.id} has an invalid date.',
      );
    }

    return ScheduleExceptionModel(
      id: document.id,
      barberId: barberId,
      date: timestamp.toDate(),
      isWorking: data['isWorking'] as bool? ?? false,
      startTime: data['startTime'] as String? ?? '09:00',
      endTime: data['endTime'] as String? ?? '17:00',
      breaks: breaks,
      reason: data['reason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'isWorking': isWorking,
      'startTime': startTime,
      'endTime': endTime,
      'breaks': breaks
          .map((item) => ScheduleBreakModel.fromEntity(item).toMap())
          .toList(),
      'reason': reason,
    };
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
