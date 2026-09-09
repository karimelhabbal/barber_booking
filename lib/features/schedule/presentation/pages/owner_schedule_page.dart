import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/features/schedule/domain/entities/weekly_schedule.dart';
import 'package:barber_booking/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'owner_schedule_exceptions_page.dart';

class OwnerSchedulePage extends StatelessWidget {
  const OwnerSchedulePage({
    super.key,
    required this.barberId,
    required this.barberName,
  });

  final String barberId;
  final String barberName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ScheduleCubit>()..loadWeeklySchedule(barberId: barberId),
      child: _OwnerScheduleView(barberId: barberId, barberName: barberName),
    );
  }
}

class _OwnerScheduleView extends StatefulWidget {
  const _OwnerScheduleView({required this.barberName, required this.barberId});

  final String barberId;
  final String barberName;

  @override
  State<_OwnerScheduleView> createState() => _OwnerScheduleViewState();
}

class _OwnerScheduleViewState extends State<_OwnerScheduleView> {
  List<WeeklySchedule> _schedules = [];

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleCubit, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleLoaded) {
          setState(() {
            _schedules = List.of(state.schedules);
          });
        }

        if (state is ScheduleSaved) {
          setState(() {
            _schedules = List.of(state.schedules);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule saved successfully.')),
          );
        }

        if (state is ScheduleError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Schedule - ${widget.barberName}'),
          actions: [
            IconButton(
              tooltip: 'Schedule Exceptions',
              icon: const Icon(Icons.event_busy_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OwnerScheduleExceptionsPage(
                      barberId: widget.barberId,
                      barberName: widget.barberName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<ScheduleCubit, ScheduleState>(
          builder: (context, state) {
            if (state is ScheduleLoading && _schedules.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ScheduleError && _schedules.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(state.message),
                ),
              );
            }

            if (_schedules.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final isSaving = state is ScheduleSaving;

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schedules.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 12);
                    },
                    itemBuilder: (context, index) {
                      final schedule = _schedules[index];

                      return _DayScheduleCard(
                        dayName: _dayNames[schedule.dayOfWeek - 1],
                        schedule: schedule,
                        onChanged: (updatedSchedule) {
                          setState(() {
                            _schedules[index] = updatedSchedule;
                          });
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () {
                              context.read<ScheduleCubit>().saveWeeklySchedule(
                                schedules: _schedules,
                              );
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Schedule'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  const _DayScheduleCard({
    required this.dayName,
    required this.schedule,
    required this.onChanged,
  });

  final String dayName;
  final WeeklySchedule schedule;
  final ValueChanged<WeeklySchedule> onChanged;

  Future<void> _selectTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    final initialTime = _parseTime(
      isStart ? schedule.startTime : schedule.endTime,
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime == null) {
      return;
    }

    final value = _formatTime(selectedTime);

    onChanged(
      WeeklySchedule(
        barberId: schedule.barberId,
        dayOfWeek: schedule.dayOfWeek,
        isWorking: schedule.isWorking,
        startTime: isStart ? value : schedule.startTime,
        endTime: isStart ? schedule.endTime : value,
        breaks: schedule.breaks,
      ),
    );
  }

  Future<void> _addBreak(BuildContext context) async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 13, minute: 0),
    );

    if (startTime == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: startTime.hour + 1 > 23 ? 23 : startTime.hour + 1,
        minute: startTime.minute,
      ),
    );

    if (endTime == null) {
      return;
    }

    final newBreak = ScheduleBreak(
      startTime: _formatTime(startTime),
      endTime: _formatTime(endTime),
    );

    final updatedBreaks = [...schedule.breaks, newBreak];

    onChanged(
      WeeklySchedule(
        barberId: schedule.barberId,
        dayOfWeek: schedule.dayOfWeek,
        isWorking: schedule.isWorking,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        breaks: updatedBreaks,
      ),
    );
  }

  void _removeBreak(int index) {
    final updatedBreaks = [...schedule.breaks]..removeAt(index);

    onChanged(
      WeeklySchedule(
        barberId: schedule.barberId,
        dayOfWeek: schedule.dayOfWeek,
        isWorking: schedule.isWorking,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        breaks: updatedBreaks,
      ),
    );
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: schedule.isWorking,
                  onChanged: (value) {
                    onChanged(
                      WeeklySchedule(
                        barberId: schedule.barberId,
                        dayOfWeek: schedule.dayOfWeek,
                        isWorking: value,
                        startTime: schedule.startTime,
                        endTime: schedule.endTime,
                        breaks: value ? schedule.breaks : const [],
                      ),
                    );
                  },
                ),
              ],
            ),
            if (schedule.isWorking) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _selectTime(context, isStart: true);
                      },
                      child: Text('Start: ${schedule.startTime}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _selectTime(context, isStart: false);
                      },
                      child: Text('End: ${schedule.endTime}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Breaks',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _addBreak(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Break'),
                  ),
                ],
              ),
              if (schedule.breaks.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('No breaks'),
                )
              else
                ...List.generate(schedule.breaks.length, (index) {
                  final breakItem = schedule.breaks[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.free_breakfast_outlined),
                    title: Text(
                      '${breakItem.startTime} - '
                      '${breakItem.endTime}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove break',
                      onPressed: () {
                        _removeBreak(index);
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                }),
            ] else ...[
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Day off'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
