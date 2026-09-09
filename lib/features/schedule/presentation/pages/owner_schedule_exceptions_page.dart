import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/features/schedule/domain/entities/schedule_exception.dart';
import 'package:barber_booking/features/schedule/domain/entities/weekly_schedule.dart';
import 'package:barber_booking/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OwnerScheduleExceptionsPage extends StatelessWidget {
  const OwnerScheduleExceptionsPage({
    super.key,
    required this.barberId,
    required this.barberName,
  });

  final String barberId;
  final String barberName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScheduleCubit>()
        ..loadScheduleExceptions(
          barberId: barberId,
          from: _startOfMonth(DateTime.now()),
          to: _endOfMonth(DateTime.now()),
        ),
      child: _OwnerScheduleExceptionsView(
        barberId: barberId,
        barberName: barberName,
      ),
    );
  }

  static DateTime _startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime _endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }
}

class _OwnerScheduleExceptionsView extends StatefulWidget {
  const _OwnerScheduleExceptionsView({
    required this.barberId,
    required this.barberName,
  });

  final String barberId;
  final String barberName;

  @override
  State<_OwnerScheduleExceptionsView> createState() =>
      _OwnerScheduleExceptionsViewState();
}

class _OwnerScheduleExceptionsViewState
    extends State<_OwnerScheduleExceptionsView> {
  late DateTime _selectedMonth;

  List<ScheduleException> _exceptions = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  DateTime get _monthStart {
    return DateTime(_selectedMonth.year, _selectedMonth.month, 1);
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

  Future<void> _loadExceptions() async {
    await context.read<ScheduleCubit>().loadScheduleExceptions(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete exception?'),
          content: Text(
            'Remove the exception for '
            '${DateFormat.yMMMd().format(exception.date)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
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
    return BlocListener<ScheduleCubit, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleExceptionsLoaded) {
          setState(() {
            _exceptions = List.of(state.exceptions);
          });
        }

        if (state is ScheduleExceptionCreated ||
            state is ScheduleExceptionUpdated ||
            state is ScheduleExceptionDeleted) {
          _loadExceptions();
        }

        if (state is ScheduleError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Exceptions - ${widget.barberName}')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _addException();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Exception'),
        ),
        body: BlocBuilder<ScheduleCubit, ScheduleState>(
          builder: (context, state) {
            final isLoading = state is ScheduleExceptionsLoading;

            if (isLoading && _exceptions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _MonthSelector(
                  month: _selectedMonth,
                  onPrevious: () {
                    _changeMonth(-1);
                  },
                  onNext: () {
                    _changeMonth(1);
                  },
                ),
                Expanded(
                  child: _exceptions.isEmpty
                      ? const Center(
                          child: Text('No schedule exceptions for this month.'),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadExceptions,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _exceptions.length,
                            separatorBuilder: (_, _) {
                              return const SizedBox(height: 12);
                            },
                            itemBuilder: (context, index) {
                              final exception = _exceptions[index];

                              return _ExceptionCard(
                                exception: exception,
                                onEdit: () {
                                  _editException(exception);
                                },
                                onDelete: () {
                                  _deleteException(exception);
                                },
                              );
                            },
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
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat.yMMMM().format(month),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
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
    final dateText = DateFormat.yMMMd().format(exception.date);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          child: Icon(exception.isWorking ? Icons.schedule : Icons.event_busy),
        ),
        title: Text(dateText, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exception.isWorking
                    ? '${exception.startTime} - '
                          '${exception.endTime}'
                    : 'Day off',
              ),
              if (exception.breaks.isNotEmpty)
                Text('${exception.breaks.length} break(s)'),
              if (exception.reason != null && exception.reason!.isNotEmpty)
                Text(exception.reason!),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            }

            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (_) {
            return const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ];
          },
        ),
      ),
    );
  }
}

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
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
    Navigator.of(context).pop(
      _ExceptionFormResult(
        date: DateTime(_date.year, _date.month, _date.day),
        isWorking: _isWorking,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        breaks: List.unmodifiable(_breaks),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
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
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialException != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Exception' : 'Add Exception',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat.yMMMMd().format(_date)),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Working day'),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectStartTime,
                        child: Text(
                          'Start: '
                          '${_formatTime(_startTime)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectEndTime,
                        child: Text(
                          'End: '
                          '${_formatTime(_endTime)}',
                        ),
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addBreak,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Break'),
                    ),
                  ],
                ),
                if (_breaks.isEmpty)
                  const Text('No breaks')
                else
                  ...List.generate(_breaks.length, (index) {
                    final breakItem = _breaks[index];

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.free_breakfast_outlined),
                      title: Text(
                        '${breakItem.startTime} - '
                        '${breakItem.endTime}',
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          _removeBreak(index);
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  }),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Optional reason for this exception',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(
                    isEditing ? 'Update Exception' : 'Save Exception',
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
