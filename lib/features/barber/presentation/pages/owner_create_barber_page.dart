import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/barber/domain/entities/barber_candidate.dart';
import 'package:barber_booking/features/barber/presentation/cubit/barber_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerCreateBarberPage extends StatefulWidget {
  const OwnerCreateBarberPage({super.key, required this.barberShopId});

  final String barberShopId;

  @override
  State<OwnerCreateBarberPage> createState() => _OwnerCreateBarberPageState();
}

class _OwnerCreateBarberPageState extends State<OwnerCreateBarberPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  BarberCandidate? _selectedCandidate;

  List<BarberCandidate> _candidates = const [];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _createBarber(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final candidate = _selectedCandidate;

    if (candidate == null) {
      final loc = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.selectBarber)));
      return;
    }

    context.read<BarberCubit>().createBarber(
      userId: candidate.id,
      barberShopId: widget.barberShopId,
      name: _nameController.text,
      phone: _phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => getIt<BarberCubit>()..loadBarberCandidates(),
      child: Builder(
        builder: (context) {
          return BlocListener<BarberCubit, BarberState>(
            listener: (context, state) {
              if (state is BarberCreated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.barberCreatedSuccessfully)),
                );

                Navigator.of(context).pop(state.barber);
              }

              if (state is BarberCandidatesLoaded) {
                setState(() {
                  _candidates = state.candidates;
                });
              }

              if (state is BarberError) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            child: Scaffold(
              appBar: AppBar(title: Text(loc.addBarber)),
              body: SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      BlocBuilder<BarberCubit, BarberState>(
                        builder: (context, state) {
                          if (state is BarberCandidatesLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (state is BarberError && _candidates.isEmpty) {
                            return Text(state.message);
                          }

                          if (state is BarberCandidatesLoaded &&
                              _candidates.isEmpty) {
                            return Text(loc.noBarberUsersAvailable);
                          }

                          if (_candidates.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return DropdownButtonFormField<BarberCandidate>(
                            initialValue: _selectedCandidate,
                            decoration: InputDecoration(
                              labelText: loc.selectBarber,
                              border: const OutlineInputBorder(),
                            ),
                            items: _candidates.map((candidate) {
                              final phone = candidate.phone;

                              return DropdownMenuItem<BarberCandidate>(
                                value: candidate,
                                child: Text(
                                  phone == null || phone.isEmpty
                                      ? candidate.name
                                      : '${candidate.name} - $phone',
                                ),
                              );
                            }).toList(),
                            onChanged: (candidate) {
                              setState(() {
                                _selectedCandidate = candidate;

                                if (candidate != null) {
                                  _nameController.text = candidate.name;
                                  _phoneController.text = candidate.phone ?? '';
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return loc.pleaseSelectBarber;
                              }

                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: loc.barberName,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.barberNameRequired;
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: loc.phone,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<BarberCubit, BarberState>(
                        builder: (context, state) {
                          final isCreating = state is BarberCreating;

                          return SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isCreating
                                  ? null
                                  : () => _createBarber(context),
                              child: isCreating
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(loc.addBarber),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
