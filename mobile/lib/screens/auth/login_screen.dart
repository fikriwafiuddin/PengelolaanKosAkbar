import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'register_screen.dart';

/// Halaman login penghuni (desain: kartu putih di atas latar krem).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kop aplikasi
                  const Text(
                    'KOST AKBAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Silakan masuk menggunakan akun yang terdaftar\n di Kost Akbar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
                  ),

                  const SizedBox(height: 28),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email wajib diisi.';
                              }
                              if (!value.contains('@')) {
                                return 'Format email tidak valid.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Kata sandi',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi wajib diisi.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          FilledButton(
                            onPressed: _processing ? null : _submit,
                            child: _processing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Masuk Sekarang'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text(
                          'Daftar di sini',
                          style: TextStyle(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.field,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Akun demo: dimaspratama@kostakbar.id / password',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
