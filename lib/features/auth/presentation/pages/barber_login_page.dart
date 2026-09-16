import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';

class BarberLoginPage extends StatefulWidget {
  const BarberLoginPage({super.key});

  @override
  State<BarberLoginPage> createState() => _BarberLoginPageState();
}

class _BarberLoginPageState extends State<BarberLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك أدخل البريد الإلكتروني وكلمة المرور'),
        ),
      );
      return;
    }

    await context.read<AuthCubit>().loginWithEmail(
      email: email,
      password: password,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/dashboard');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_errorMessage(state.code))));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('دخول الحلاق')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('دخول'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('العودة لتسجيل دخول العملاء'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _errorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';

      case 'invalid-password':
        return 'كلمة المرور مطلوبة';

      case 'invalid-credentials':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

      case 'user-disabled':
        return 'هذا الحساب معطل';

      case 'user-profile-not-found':
        return 'حساب الحلاق غير مهيأ في النظام';

      case 'barber-access-denied':
        return 'هذا الحساب ليس حساب حلاق';

      case 'network-request-failed':
        return 'تعذر الاتصال بالإنترنت';

      case 'too-many-requests':
        return 'محاولات كثيرة. حاول مرة أخرى لاحقًا';

      case 'operation-not-allowed':
        return 'تسجيل الدخول بالبريد الإلكتروني غير مفعل';

      default:
        return 'حدث خطأ أثناء تسجيل الدخول';
    }
  }
}
