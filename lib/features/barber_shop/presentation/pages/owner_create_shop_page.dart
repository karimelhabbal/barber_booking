import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:barber_booking/features/barber_shop/presentation/cubit/barber_shop_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/domain/entities/user.dart';

class OwnerCreateShopPage extends StatefulWidget {
  const OwnerCreateShopPage({required this.authCubit, super.key});
  final AuthCubit authCubit;

  @override
  State<OwnerCreateShopPage> createState() => _OwnerCreateShopPageState();
}

class _OwnerCreateShopPageState extends State<OwnerCreateShopPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createShop(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User session is not available.')),
      );
      return;
    }

    final user = authState.user;

    if (user.role != UserRole.owner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only an owner can create a barber shop.'),
        ),
      );
      return;
    }

    context.read<BarberShopCubit>().createShop(
      ownerId: user.id,
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      description: _descriptionController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.authCubit,
      child: BlocProvider(
        create: (_) => getIt<BarberShopCubit>(),
        child: Builder(
          builder: (context) {
            return BlocListener<BarberShopCubit, BarberShopState>(
              listener: (context, state) {
                if (state is BarberShopCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Barber shop created successfully.'),
                    ),
                  );

                  Navigator.of(context).pop(state.shop);
                }

                if (state is BarberShopError) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              child: Scaffold(
                appBar: AppBar(title: const Text('Create Barber Shop')),
                body: SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Shop name',
                            hintText: 'Enter barber shop name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Shop name is required.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _addressController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        BlocBuilder<BarberShopCubit, BarberShopState>(
                          builder: (context, state) {
                            final isCreating = state is BarberShopCreating;

                            return SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isCreating
                                    ? null
                                    : () => _createShop(context),
                                child: isCreating
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Create Shop'),
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
      ),
    );
  }
}
