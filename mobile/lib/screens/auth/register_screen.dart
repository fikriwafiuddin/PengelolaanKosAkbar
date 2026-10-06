import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Registrasi calon penghuni: data akun + profil identitas
/// (mengikuti activity diagram "Apakah sudah punya akun?" -> registrasi).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  final _fullName = TextEditingController();
  final _identityNumber = TextEditingController();
  final _phone = TextEditingController();
  final _birthDate = TextEditingController();
  final _address = TextEditingController();
  final _occupation = TextEditingController();

  bool _obscurePassword = true;
  bool _processing = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    _fullName.dispose();
    _identityNumber.dispose();
    _phone.dispose();
    _birthDate.dispose();
    _address.dispose();
    _occupation.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
    );

    if (picked != null) {
      setState(() {
        // Format YYYY-MM-DD sesuai ekspektasi API.
        final month = picked.month.toString().padLeft(2, '0');
        final day = picked.day.toString().padLeft(2, '0');
        _birthDate.text = '${picked.year}-$month-$day';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
      _fieldErrors = const {};
    });

    try {
      await context.read<AuthProvider>().register(
            email: _email.text.trim(),
            password: _password.text,
            passwordConfirmation: _passwordConfirmation.text,
            fullName: _fullName.text.trim(),
            identityNumber: _identityNumber.text.trim(),
            phone: _phone.text.trim(),
            birthDate: _birthDate.text,
            address: _address.text.trim(),
            occupation: _occupation.text.trim(),
          );

      // Registrasi berhasil -> status loggedIn; buang halaman registrasi
      // dari tumpukan agar MainShell (halaman dasar) terlihat.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _fieldErrors = {
          for (final entry in e.errors.entries)
            if (_controllers.containsKey(entry.key)) entry.key: entry.value.first,
        };
      });
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Map<String, TextEditingController> get _controllers => {
        'email': _email,
        'password': _password,
        'full_name': _fullName,
        'identity_number': _identityNumber,
        'phone': _phone,
        'address': _address,
        'occupation': _occupation,
      };

  String? _fieldError(String key) => _fieldErrors[key];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Penghuni')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              _sectionTitle('Data Akun'),
              _textFormField(
                controller: _email,
                label: 'Email',
                hint: 'nama@email.com',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                errorText: _fieldError('email'),
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Format email tidak valid.',
              ),
              _textFormField(
                controller: _password,
                label: 'Kata Sandi',
                hint: 'Minimal 8 karakter',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                toggleObscure: true,
                errorText: _fieldError('password'),
                validator: (v) =>
                    v != null && v.length >= 8 ? null : 'Kata sandi minimal 8 karakter.',
              ),
              _textFormField(
                controller: _passwordConfirmation,
                label: 'Ulangi Kata Sandi',
                hint: 'Ketik ulang kata sandi',
                icon: Icons.lock_outline_rounded,
                obscure: true,
                validator: (v) =>
                    v == _password.text ? null : 'Konfirmasi kata sandi tidak cocok.',
              ),

              _sectionTitle('Identitas Penghuni'),
              _textFormField(
                controller: _fullName,
                label: 'Nama Lengkap',
                hint: 'Sesuai KTP/identitas',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                errorText: _fieldError('full_name'),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : 'Nama lengkap wajib diisi.',
              ),
              _textFormField(
                controller: _identityNumber,
                label: 'Nomor Identitas (NIK)',
                hint: '16 digit NIK KTP',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                errorText: _fieldError('identity_number'),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : 'NIK wajib diisi.',
              ),
              _textFormField(
                controller: _phone,
                label: 'No. HP',
                hint: '+628123456789',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                errorText: _fieldError('phone'),
              ),
              _textFormField(
                controller: _birthDate,
                label: 'Tanggal Lahir',
                hint: 'Pilih tanggal',
                icon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickBirthDate,
              ),
              _textFormField(
                controller: _occupation,
                label: 'Pekerjaan',
                hint: 'Mahasiswa / Karyawan / ...',
                icon: Icons.work_outline_rounded,
                textCapitalization: TextCapitalization.words,
                errorText: _fieldError('occupation'),
              ),
              _textFormField(
                controller: _address,
                label: 'Alamat Asal',
                hint: 'Alamat domisili sebelum menyewa',
                icon: Icons.home_outlined,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                errorText: _fieldError('address'),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],

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
                    : const Text('Daftar Sekarang'),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 12),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AppColors.terracotta,
          ),
        ),
      );

  Widget _textFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    String? errorText,
    TextInputType? keyboardType,
    bool obscure = false,
    bool toggleObscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscure,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: obscure ? 1 : maxLines,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              errorText: errorText,
              suffixIcon: toggleObscure
                  ? IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
