import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/utils/auth_error_mapper.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';

class BarberLoginPage extends StatefulWidget {
  const BarberLoginPage({super.key});
  @override
  State<BarberLoginPage> createState() => _BarberLoginPageState();
}

class _BarberLoginPageState extends State<BarberLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    final loc = AppLocalizations.of(context)!;
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.invalidCredentials)));
      return;
    }
    await context.read<AuthCubit>().loginWithEmail(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) context.go('/dashboard');
        if (state is AuthError) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.code.localizedMessage(loc))));
      },
      child: Scaffold(appBar: AppBar(title: Text(loc.barberSignIn)), body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.content_cut_rounded, size: 48, color: theme.colorScheme.primary), const SizedBox(height: 24),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: loc.emailAddress, prefixIcon: const Icon(Icons.mail_outline))),
          const SizedBox(height: 16),
          TextField(controller: _password, obscureText: _obscure, textInputAction: TextInputAction.done, onSubmitted: (_) => _login(), decoration: InputDecoration(labelText: loc.password, prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
          const SizedBox(height: 24),
          BlocBuilder<AuthCubit, AuthState>(builder: (context, state) => SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: state is AuthLoading ? null : _login, child: state is AuthLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(loc.signIn)))),
          const SizedBox(height: 12), TextButton(onPressed: () => context.go('/login'), child: Text(loc.customerSignIn)),
        ]),
      ))))),
    );
  }
}
