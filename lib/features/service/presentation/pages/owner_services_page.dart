import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/service/domain/entities/service.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_cubit.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerServicesPage extends StatelessWidget {
  const OwnerServicesPage({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ServiceCubit>()..loadShopServices(shopId: shopId),
      child: _OwnerServicesView(shopId: shopId),
    );
  }
}

class _OwnerServicesView extends StatelessWidget {
  const _OwnerServicesView({required this.shopId});

  final String shopId;

  Future<void> _refresh(BuildContext context) {
    return context.read<ServiceCubit>().loadShopServices(shopId: shopId);
  }

  Future<void> _showForm(BuildContext context, {Service? service}) async {
    final draft = await showDialog<_ServiceDraft>(
      context: context,
      builder: (_) => _ServiceFormDialog(service: service),
    );

    if (draft == null || !context.mounted) {
      return;
    }

    final cubit = context.read<ServiceCubit>();

    if (service == null) {
      await cubit.createService(
        shopId: shopId,
        name: draft.name,
        description: draft.description,
        durationMinutes: draft.durationMinutes,
        price: draft.price,
      );
      return;
    }

    await cubit.updateService(
      Service(
        id: service.id,
        barberShopId: service.barberShopId,
        name: draft.name,
        description: draft.description,
        durationMinutes: draft.durationMinutes,
        price: draft.price,
        isActive: service.isActive,
        createdAt: service.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _deleteService(BuildContext context, Service service) async {
    final loc = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loc.deleteServiceTitle),
          content: Text(loc.deleteServiceMessage(service.name)),
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
      await context.read<ServiceCubit>().deleteService(
        shopId: shopId,
        serviceId: service.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.manageServices)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ServiceCubit, ServiceState>(
        listener: (context, state) {
          if (state is ServiceCreated ||
              state is ServiceUpdated ||
              state is ServiceDeleted) {
            _refresh(context);
          }
        },
        builder: (context, state) {
          if (state is ServiceLoading ||
              state is ServiceCreating ||
              state is ServiceUpdating ||
              state is ServiceDeleting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ServiceError) {
            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  Text(state.message, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          if (state is ServiceLoaded) {
            if (state.services.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 160),
                    Center(child: Text(loc.noServicesYet)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: state.services.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final service = state.services[index];

                  return Card(
                    child: ListTile(
                      title: Text(service.name),
                      subtitle: Text(
                        '${service.durationMinutes} min | '
                        '${service.price.toStringAsFixed(2)} EGP',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                _showForm(context, service: service),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: loc.editService,
                          ),
                          IconButton(
                            onPressed: () => _deleteService(context, service),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: loc.delete,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ServiceDraft {
  const _ServiceDraft({
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
  });

  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
}

class _ServiceFormDialog extends StatefulWidget {
  const _ServiceFormDialog({this.service});

  final Service? service;

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController = TextEditingController(text: service?.name ?? '');
    _descriptionController = TextEditingController(
      text: service?.description ?? '',
    );
    _durationController = TextEditingController(
      text: service?.durationMinutes.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: service?.price.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final loc = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final duration = int.tryParse(_durationController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty) {
      setState(() => _error = loc.serviceNameRequired);
      return;
    }

    if (duration == null || duration <= 0 || duration % 5 != 0) {
      setState(() => _error = loc.invalidDuration);
      return;
    }

    if (price == null || price < 0) {
      setState(() => _error = loc.invalidPrice);
      return;
    }

    final description = _descriptionController.text.trim();

    Navigator.of(context).pop(
      _ServiceDraft(
        name: name,
        description: description.isEmpty ? null : description,
        durationMinutes: duration,
        price: price,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.service == null ? loc.addService : loc.editService),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: loc.name),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: loc.description),
            ),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: loc.durationMinutes),
            ),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: loc.price),
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
