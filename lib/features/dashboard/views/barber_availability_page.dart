import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/schedule/domain/entities/schedule_exception.dart';
import 'package:barber_booking/features/schedule/domain/entities/weekly_schedule.dart';
import 'package:barber_booking/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

/// Availability section of the barber workspace.
///
/// Manages both the weekly schedule and the schedule exceptions (time off)
/// with the existing [ScheduleCubit]. All validation stays inside the cubit.
class BarberAvailabilityPage extends StatelessWidget {
  const BarberAvailabilityPage({super.key, required this.barberId});

  final String barberId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScheduleCubit>(),
      child: _BarberAvailabilityView(barberId: barberId),
    );
  }
}

class _BarberAvailabilityView extends StatefulWidget {
  const _BarberAvailabilityView({required this.barberId});

  final String barberId;

  @override
  State<_BarberAvailabilityView> createState() =>
      _BarberAvailabilityViewState();
}

class _BarberAvailabilityViewState extends State<_BarberAvailabilityView> {
  List<WeeklySchedule> _schedules = [];
  List<ScheduleException> _exceptions = [];
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(now.year, now.month);

    _loadAll();
  }

  DateTime get _monthStart {
    return DateTime(_selectedMonth.year, _selectedMonth.month);
  }

  DateTime get _monthEnd {
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
      23,
      59,
      59,
      999,
    );
  }

  Future<void> _loadAll() async {
    await _loadWeeklySchedule();
    await _loadExceptions();
  }

  Future<void> _loadWeeklySchedule() {
    return context.read<ScheduleCubit>().loadWeeklySchedule(
      barberId: widget.barberId,
    );
  }

  Future<void> _loadExceptions() {
    return context.read<ScheduleCubit>().loadScheduleExceptions(
      barberId: widget.barberId,
      from: _monthStart,
      to: _monthEnd,
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });

    _loadExceptions();
  }

  void _updateSchedule(int index, WeeklySchedule schedule) {
    setState(() {
      _schedules = [..._schedules]..[index] = schedule;
    });
  }

  Future<void> _saveWeeklySchedule() {
    return context.read<ScheduleCubit>().saveWeeklySchedule(
      schedules: _schedules,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _dayName(AppLocalizations loc, int dayOfWeek) {
    return [
      loc.monday,
      loc.tuesday,
      loc.wednesday,
      loc.thursday,
      loc.friday,
      loc.saturday,
      loc.sunday,
    ][dayOfWeek - 1];
  }

  Future<void> _addException() async {
    final result = await showModalBottomSheet<_ExceptionFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return const _ExceptionFormSheet();
      },
    );

    if (result == null || !mounted) {
      return;
    }

    await context.read<ScheduleCubit>().createScheduleException(
      barberId: widget.barberId,
      date: result.date,
      isWorking: result.isWorking,
      startTime: result.startTime,
      endTime: result.endTime,
      breaks: result.breaks,
      reason: result.reason,
    );
  }

  Future<void> _editException(ScheduleException exception) async {
    final result = await showModalBottomSheet<_ExceptionFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return _ExceptionFormSheet(initialException: exception);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    await context.read<ScheduleCubit>().updateScheduleException(
      exception: ScheduleException(
        id: exception.id,
        barberId: exception.barberId,
        date: result.date,
        isWorking: result.isWorking,
        startTime: result.startTime,
        endTime: result.endTime,
        breaks: result.breaks,
        reason: result.reason,
      ),
    );
  }

  Future<void> _deleteException(ScheduleException exception) async {
    final loc = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loc.deleteExceptionTitle),
          content: Text(
            '${loc.deleteExceptionMessage} '
            '${intl.DateFormat.yMMMd().format(exception.date)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<ScheduleCubit>().deleteScheduleException(
      barberId: widget.barberId,
      exceptionId: exception.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocListener<ScheduleCubit, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleLoaded) {
          setState(() {
            _schedules = List.of(state.schedules);
          });
          return;
        }

        if (state is ScheduleSaved) {
          setState(() {
            _schedules = List.of(state.schedules);
          });

          _showMessage(loc.scheduleSaved);
          return;
        }

        if (state is ScheduleExceptionsLoaded) {
          setState(() {
            _exceptions = List.of(state.exceptions);
          });
          return;
        }

        if (state is ScheduleExceptionCreated ||
            state is ScheduleExceptionUpdated ||
            state is ScheduleExceptionDeleted) {
          _loadExceptions();
          return;
        }

        if (state is ScheduleError) {
          _showMessage(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(loc.availability)),
        body: SafeArea(
          child: BlocBuilder<ScheduleCubit, ScheduleState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: _loadAll,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 32),
                  children: [
                    _SectionHeader(
                      icon: Icons.schedule_outlined,
                      title: loc.schedule,
                    ),
                    const SizedBox(height: 12),
                    ..._weeklySection(loc, state),
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),
                    ..._exceptionsSection(loc, state),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _weeklySection(AppLocalizations loc, ScheduleState state) {
    if (_schedules.isEmpty) {
      if (state is ScheduleError) {
        return [
          _InfoCard(
            icon: Icons.error_outline_rounded,
            title: state.message,
            action: FilledButton.icon(
              onPressed: _loadWeeklySchedule,
              icon: const Icon(Icons.refresh),
              label: Text(loc.retry),
            ),
          ),
        ];
      }

      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final isSaving = state is ScheduleSaving;

    final hasWorkingDay = _schedules.any((schedule) => schedule.isWorking);

    return [
      if (!hasWorkingDay) ...[
        _InfoCard(
          icon: Icons.event_available_outlined,
          title: loc.noWorkingDays,
          message: loc.noWorkingDaysHint,
        ),
        const SizedBox(height: 12),
      ],
      for (var index = 0; index < _schedules.length; index++) ...[
        _DayScheduleCard(
          dayName: _dayName(loc, _schedules[index].dayOfWeek),
          schedule: _schedules[index],
          loc: loc,
          onChanged: (schedule) => _updateSchedule(index, schedule),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: isSaving ? null : _saveWeeklySchedule,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(loc.saveSchedule),
        ),
      ),
    ];
  }

  List<Widget> _exceptionsSection(AppLocalizations loc, ScheduleState state) {
    final isBusy =
        state is ScheduleExceptionCreating ||
        state is ScheduleExceptionUpdating ||
        state is ScheduleExceptionDeleting;

    final children = <Widget>[
      _SectionHeader(
        icon: Icons.event_busy_outlined,
        title: loc.scheduleExceptions,
      ),
      const SizedBox(height: 12),
      _MonthSelector(
        month: _selectedMonth,
        onPrevious: () => _changeMonth(-1),
        onNext: () => _changeMonth(1),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isBusy ? null : _addException,
          icon: const Icon(Icons.add),
          label: Text(loc.addException),
        ),
      ),
      const SizedBox(height: 12),
    ];

    if (state is ScheduleExceptionsLoading && _exceptions.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      return children;
    }

    if (_exceptions.isEmpty) {
      children.add(
        _InfoCard(
          icon: Icons.beach_access_outlined,
          title: loc.noExceptionsThisMonth,
        ),
      );

      return children;
    }

    final sortedExceptions = [..._exceptions]
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final exception in sortedExceptions) {
      children.add(
        _ExceptionCard(
          exception: exception,
          onEdit: () => _editException(exception),
          onDelete: () => _deleteException(exception),
        ),
      );
      children.add(const SizedBox(height: 12));
    }

    return children;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = message;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            IconButton(
              tooltip: loc.previousMonth,
              onPressed: onPrevious,
              icon: Icon(isRtl ? Icons.chevron_right : Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  intl.DateFormat.yMMMM().format(month),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: loc.nextMonth,
              onPressed: onNext,
              icon: Icon(isRtl ? Icons.chevron_left : Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  const _DayScheduleCard({
    required this.dayName,
    required this.schedule,
    required this.loc,
    required this.onChanged,
  });

  final String dayName;
  final WeeklySchedule schedule;
  final AppLocalizations loc;
  final ValueChanged<WeeklySchedule> onChanged;

  WeeklySchedule _copyWith({
    bool? isWorking,
    String? startTime,
    String? endTime,
    List<ScheduleBreak>? breaks,
  }) {
    return WeeklySchedule(
      barberId: schedule.barberId,
      dayOfWeek: schedule.dayOfWeek,
      isWorking: isWorking ?? schedule.isWorking,
      startTime: startTime ?? schedule.startTime,
      endTime: endTime ?? schedule.endTime,
      breaks: breaks ?? schedule.breaks,
    );
  }

  Future<void> _selectTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _parseTime(isStart ? schedule.startTime : schedule.endTime),
    );

    if (selectedTime == null) {
      return;
    }

    final value = _formatTime(selectedTime);

    onChanged(
      _copyWith(
        startTime: isStart ? value : schedule.startTime,
        endTime: isStart ? schedule.endTime : value,
      ),
    );
  }

  Future<void> _addBreak(BuildContext context) async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 13, minute: 0),
    );

    if (startTime == null || !context.mounted) {
      return;
    }

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: startTime.hour < 23 ? startTime.hour + 1 : 23,
        minute: startTime.minute,
      ),
    );

    if (endTime == null) {
      return;
    }

    onChanged(
      _copyWith(
        breaks: [
          ...schedule.breaks,
          ScheduleBreak(
            startTime: _formatTime(startTime),
            endTime: _formatTime(endTime),
          ),
        ],
      ),
    );
  }

  void _removeBreak(int index) {
    onChanged(_copyWith(breaks: [...schedule.breaks]..removeAt(index)));
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  schedule.isWorking ? loc.workingDay : loc.dayOff,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Switch(
                  value: schedule.isWorking,
                  onChanged: (value) {
                    onChanged(
                      _copyWith(
                        isWorking: value,
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
                      onPressed: () => _selectTime(context, isStart: true),
                      child: Text(
                        '${loc.scheduleStart}: ${schedule.startTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(context, isStart: false),
                      child: Text(
                        '${loc.scheduleEnd}: ${schedule.endTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.breaks,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addBreak(context),
                    icon: const Icon(Icons.add),
                    label: Text(loc.addBreak),
                  ),
                ],
              ),
              if (schedule.breaks.isEmpty)
                Text(
                  loc.noBreaks,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (var index = 0; index < schedule.breaks.length; index++)
                  Row(
                    children: [
                      Icon(
                        Icons.free_breakfast_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${schedule.breaks[index].startTime} - '
                          '${schedule.breaks[index].endTime}',
                        ),
                      ),
                      IconButton(
                        tooltip: loc.removeBreak,
                        onPressed: () => _removeBreak(index),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                loc.dayOff,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExceptionCard extends StatelessWidget {
  const _ExceptionCard({
    required this.exception,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleException exception;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reason = exception.reason;

    final details = <String>[
      if (exception.isWorking)
        '${exception.startTime} - ${exception.endTime}',
      if (exception.breaks.isNotEmpty)
        loc.breaksCount(exception.breaks.length),
      if (reason != null && reason.isNotEmpty) reason,
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                exception.isWorking
                    ? Icons.schedule_outlined
                    : Icons.event_busy_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          intl.DateFormat.yMMMd().format(exception.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        exception.isWorking ? loc.working : loc.dayOff,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  for (final detail in details)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        detail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<_ExceptionAction>(
              tooltip: loc.edit,
              onSelected: (action) {
                switch (action) {
                  case _ExceptionAction.edit:
                    onEdit();
                    return;
                  case _ExceptionAction.delete:
                    onDelete();
                    return;
                }
              },
              itemBuilder: (_) {
                return [
                  PopupMenuItem(
                    value: _ExceptionAction.edit,
                    child: Text(loc.edit),
                  ),
                  PopupMenuItem(
                    value: _ExceptionAction.delete,
                    child: Text(loc.delete),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _ExceptionAction { edit, delete }

class _ExceptionFormResult {
  const _ExceptionFormResult({
    required this.date,
    required this.isWorking,
    required this.startTime,
    required this.endTime,
    required this.breaks,
    required this.reason,
  });

  final DateTime date;
  final bool isWorking;
  final String startTime;
  final String endTime;
  final List<ScheduleBreak> breaks;
  final String? reason;
}

class _ExceptionFormSheet extends StatefulWidget {
  const _ExceptionFormSheet({this.initialException});

  final ScheduleException? initialException;

  @override
  State<_ExceptionFormSheet> createState() => _ExceptionFormSheetState();
}

class _ExceptionFormSheetState extends State<_ExceptionFormSheet> {
  late DateTime _date;
  late bool _isWorking;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<ScheduleBreak> _breaks;

  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final exception = widget.initialException;

    _date = exception?.date ?? DateTime.now();
    _isWorking = exception?.isWorking ?? false;
    _startTime = _parseTime(exception?.startTime ?? '09:00');
    _endTime = _parseTime(exception?.endTime ?? '17:00');
    _breaks = List.of(exception?.breaks ?? const []);
    _reasonController.text = exception?.reason ?? '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _date = selectedDate;
    });
  }

  Future<void> _selectStartTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _startTime = selectedTime;
    });
  }

  Future<void> _selectEndTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _endTime = selectedTime;
    });
  }

  Future<void> _addBreak() async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 13, minute: 0),
    );

    if (startTime == null || !mounted) {
      return;
    }

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: startTime.hour < 23 ? startTime.hour + 1 : 23,
        minute: startTime.minute,
      ),
    );

    if (endTime == null) {
      return;
    }

    setState(() {
      _breaks.add(
        ScheduleBreak(
          startTime: _formatTime(startTime),
          endTime: _formatTime(endTime),
        ),
      );
    });
  }

  void _removeBreak(int index) {
    setState(() {
      _breaks.removeAt(index);
    });
  }

  void _submit() {
    final reason = _reasonController.text.trim();

    Navigator.of(context).pop(
      _ExceptionFormResult(
        date: DateTime(_date.year, _date.month, _date.day),
        isWorking: _isWorking,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        breaks: List.unmodifiable(_breaks),
        reason: reason.isEmpty ? null : reason,
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
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isEditing = widget.initialException != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 16,
          end: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? loc.editException : loc.addException,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(intl.DateFormat.yMMMMd().format(_date)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.workingDay),
                value: _isWorking,
                onChanged: (value) {
                  setState(() {
                    _isWorking = value;

                    if (!value) {
                      _breaks.clear();
                    }
                  });
                },
              ),
              if (_isWorking) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectStartTime,
                        child: Text(
                          '${loc.exceptionStartTime}: '
                          '${_formatTime(_startTime)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectEndTime,
                        child: Text(
                          '${loc.exceptionEndTime}: '
                          '${_formatTime(_endTime)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.breaks,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addBreak,
                      icon: const Icon(Icons.add),
                      label: Text(loc.addBreak),
                    ),
                  ],
                ),
                if (_breaks.isEmpty)
                  Text(
                    loc.noBreaks,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  for (var index = 0; index < _breaks.length; index++)
                    Row(
                      children: [
                        Icon(
                          Icons.free_breakfast_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_breaks[index].startTime} - '
                            '${_breaks[index].endTime}',
                          ),
                        ),
                        IconButton(
                          tooltip: loc.removeBreak,
                          onPressed: () => _removeBreak(index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: loc.reason,
                  hintText: loc.reasonHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(
                    isEditing ? loc.updateException : loc.saveException,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






