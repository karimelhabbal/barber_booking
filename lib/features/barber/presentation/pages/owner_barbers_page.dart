import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/barber/presentation/cubit/barber_cubit.dart';
import 'package:barber_booking/features/barber/presentation/pages/owner_create_barber_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../schedule/presentation/pages/owner_schedule_page.dart';
import '../../domain/entities/barber.dart';

enum _BarberAction { edit, delete }

class OwnerBarbersPage extends StatelessWidget {
  const OwnerBarbersPage({super.key, required this.barberShopId});

  final String barberShopId;

  Future<void> _refresh(BuildContext context) {
    return context.read<BarberCubit>().loadShopBarbers(
      barberShopId: barberShopId,
    );
  }

  Future<void> _setBarberActive(
    BuildContext context,
    Barber barber,
    bool isActive,
  ) {
    return context.read<BarberCubit>().updateBarber(
      Barber(
        id: barber.id,
        userId: barber.userId,
        barberShopId: barber.barberShopId,
        name: barber.name,
        phone: barber.phone,
        imageUrl: barber.imageUrl,
        isActive: isActive,
        createdAt: barber.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _editBarber(BuildContext context, Barber barber) async {
    final draft = await showDialog<_BarberDraft>(
      context: context,
      builder: (_) => _BarberFormDialog(barber: barber),
    );

    if (draft == null || !context.mounted) {
      return;
    }

    await context.read<BarberCubit>().updateBarber(
      Barber(
        id: barber.id,
        userId: barber.userId,
        barberShopId: barber.barberShopId,
        name: draft.name,
        phone: draft.phone,
        imageUrl: barber.imageUrl,
        isActive: barber.isActive,
        createdAt: barber.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _deleteBarber(BuildContext context, Barber barber) async {
    final loc = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loc.deleteBarberTitle),
          content: Text(loc.deleteBarberMessage(barber.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.keep),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      await context.read<BarberCubit>().deleteBarber(barberId: barber.id);
    }
  }

  void _openSchedule(BuildContext context, Barber barber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OwnerSchedulePage(barberId: barber.id, barberName: barber.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<BarberCubit>()..loadShopBarbers(barberShopId: barberShopId),
      child: Builder(
        builder: (context) {
          final loc = AppLocalizations.of(context)!;

          return Scaffold(
            appBar: AppBar(
              title: Text(loc.barbers),
              actions: [
                IconButton(
                  onPressed: () => _refresh(context),
                  icon: const Icon(Icons.refresh),
                  tooltip: loc.refresh,
                ),
              ],
            ),
            body: BlocBuilder<BarberCubit, BarberState>(
              builder: (context, state) {
                if (state is BarberLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is BarberError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _refresh(context),
                            child: Text(loc.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is BarberLoaded) {
                  if (state.barbers.isEmpty) {
                    return Center(child: Text(loc.noBarbersYet));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.barbers.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (context, index) {
                      final barber = state.barbers[index];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              barber.name.isNotEmpty
                                  ? barber.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(barber.name),
                          subtitle: Text(barber.phone ?? loc.noPhone),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: barber.isActive,
                                onChanged: (value) {
                                  _setBarberActive(context, barber, value);
                                },
                              ),
                              PopupMenuButton<_BarberAction>(
                                tooltip: loc.manageBarbers,
                                onSelected: (action) {
                                  if (action == _BarberAction.edit) {
                                    _editBarber(context, barber);
                                    return;
                                  }

                                  _deleteBarber(context, barber);
                                },
                                itemBuilder: (context) {
                                  return [
                                    PopupMenuItem(
                                      value: _BarberAction.edit,
                                      child: Text(loc.editBarber),
                                    ),
                                    PopupMenuItem(
                                      value: _BarberAction.delete,
                                      child: Text(loc.delete),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            _openSchedule(context, barber);
                          },
                        ),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final createdBarber = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        OwnerCreateBarberPage(barberShopId: barberShopId),
                  ),
                );

                if (!context.mounted) {
                  return;
                }

                if (createdBarber != null) {
                  await context.read<BarberCubit>().loadShopBarbers(
                    barberShopId: barberShopId,
                  );
                }
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}

class _BarberDraft {
  const _BarberDraft({required this.name, required this.phone});

  final String name;
  final String? phone;
}

class _BarberFormDialog extends StatefulWidget {
  const _BarberFormDialog({required this.barber});

  final Barber barber;

  @override
  State<_BarberFormDialog> createState() => _BarberFormDialogState();
}

class _BarberFormDialogState extends State<_BarberFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.barber.name);
    _phoneController = TextEditingController(text: widget.barber.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final loc = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = loc.barberNameRequired);
      return;
    }

    final phone = _phoneController.text.trim();

    Navigator.of(context)
        .pop(_BarberDraft(name: name, phone: phone.isEmpty ? null : phone));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.editBarber),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: loc.name),
            ),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: loc.phone),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(onPressed: _submit, child: Text(loc.save)),
      ],
    );
  }
}
