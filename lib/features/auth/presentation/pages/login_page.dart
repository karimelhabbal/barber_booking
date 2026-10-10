import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/utils/auth_error_mapper.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _obscure = true;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthCubit>();
    if (_registering) {
      await auth.registerWithEmail(name: _name.text, email: _email.text, password: _password.text);
    } else {
      await auth.loginCustomerWithEmail(email: _email.text, password: _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) context.go('/dashboard');
        if (state is AuthError) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.code.localizedMessage(loc))));
      },
      child: Scaffold(
        body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(28)), child: Column(children: [
              Icon(Icons.content_cut_rounded, size: 42, color: colors.onPrimary), const SizedBox(height: 12),
              Text('BARBER BOOKING', style: theme.textTheme.labelLarge?.copyWith(color: colors.onPrimary, letterSpacing: 2, fontWeight: FontWeight.bold)),
            ])),
            const SizedBox(height: 32),
            Text(_registering ? loc.createAccount : loc.authWelcome, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6), Text(loc.authSubtitle, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 24),
            _ProviderButton(label: 'Google', icon: Icons.g_mobiledata_rounded, onPressed: () => context.read<AuthCubit>().signInWithProvider('google')),
            const SizedBox(height: 10),
            _ProviderButton(label: 'Facebook', icon: Icons.facebook_rounded, onPressed: () => context.read<AuthCubit>().signInWithProvider('facebook')),
            const SizedBox(height: 10),
            _ProviderButton(label: 'Apple', icon: Icons.apple, onPressed: () => context.read<AuthCubit>().signInWithProvider('apple')),
            Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Row(children: [Expanded(child: Divider(color: colors.outlineVariant)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(loc.authOrEmail, style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant))), Expanded(child: Divider(color: colors.outlineVariant))])),
            Form(key: _formKey, child: Column(children: [
              if (_registering) ...[TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: loc.name, prefixIcon: const Icon(Icons.person_outline)), validator: (v) => (v == null || v.trim().isEmpty) ? loc.invalidName : null), const SizedBox(height: 12)],
              TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: InputDecoration(labelText: loc.emailAddress, prefixIcon: const Icon(Icons.mail_outline)), validator: (v) => (v == null || !v.contains('@')) ? loc.invalidEmail : null),
              const SizedBox(height: 12),
              TextFormField(controller: _password, obscureText: _obscure, autofillHints: [_registering ? AutofillHints.newPassword : AutofillHints.password], onFieldSubmitted: (_) => _submit(), decoration: InputDecoration(labelText: loc.password, prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => (v == null || v.length < 6) ? loc.passwordTooShort : null),
            ])),
            const SizedBox(height: 18),
            BlocBuilder<AuthCubit, AuthState>(builder: (context, state) => SizedBox(height: 54, child: FilledButton(onPressed: state is AuthLoading ? null : _submit, child: state is AuthLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_registering ? loc.createAccount : loc.signIn)))),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(() => _registering = !_registering), child: Text(_registering ? loc.hasAccountAction : loc.noAccountAction)),
            Align(alignment: Alignment.center, child: TextButton(onPressed: () => context.go('/barber-login'), child: Text(loc.barberSignIn))),
          ]),
        )))),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({required this.label, required this.icon, required this.onPressed});
  final String label; final IconData icon; final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(height: 50, child: OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))));
}
