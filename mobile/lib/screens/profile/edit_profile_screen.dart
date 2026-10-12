import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Ubah profil penghuni. Email dan NIK bersifat tetap (tidak dapat
/// diubah dari aplikasi); field lain dapat diperbarui.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _birthDate = TextEditingController();
  final _address = TextEditingController();
  final _occupation = TextEditingController();
  final _guardianName = TextEditingController();
  final _guardianPhone = TextEditingController();

  bool _processing = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  DateTime get _maxBirthDate =>
      DateTime.now().subtract(const Duration(days: 365 * 18));

  @override
  void initState() {
    super.initState();

    // Praisi formulir dari profil aktif.
    final resident =
        context.read<AuthProvider>().user?.resident;

    _fullName.text = resident?.fullName ?? '';
    _phone.text = context.read<AuthProvider>().user?.phone ?? '';
    _birthDate.text = resident?.birthDate ?? '';
    _address.text = resident?.address ?? '';
    _occupation.text = resident?.occupation ?? '';
    _guardianName.text = resident?.guardianName ?? '';
    _guardianPhone.text = resident?.guardianPhone ?? '';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _birthDate.dispose();
    _address.dispose();
    _occupation.dispose();
    _guardianName.dispose();
    _guardianPhone.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final parsed = DateTime.tryParse(_birthDate.text);
    final initial = (parsed != null && parsed.isBefore(_maxBirthDate))
        ? parsed
        : _maxBirthDate.subtract(const Duration(days: 365 * 5));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: _maxBirthDate,
      helpText: 'Pilih tanggal lahir (usia minimal 18 tahun)',
    );

    if (picked != null) {
      setState(() {
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
      await context.read<AuthProvider>().updateProfile(
            fullName: _fullName.text.trim(),
            phone: _phone.text.trim(),
            birthDate: _birthDate.text,
            guardianPhone: _guardianPhone.text.trim(),
            address: _address.text.trim(),
            occupation: _occupation.text.trim(),
            guardianName: _guardianName.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _fieldErrors = {
          for (final entry in e.errors.entries)
            if (_controllers.containsKey(entry.key))
              entry.key: entry.value.first,
        };
      });
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Map<String, TextEditingController> get _controllers => {
        'full_name': _fullName,
        'phone': _phone,
        'birth_date': _birthDate,
        'address': _address,
        'occupation': _occupation,
        'guardian_name': _guardianName,
        'guardian_phone': _guardianPhone,
      };

  String? _fieldError(String key) => _fieldErrors[key];

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email ?? '';
    final nik =
        context.watch<AuthProvider>().user?.resident?.identityNumber ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Profil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // Data tetap
              _readOnlyField(label: 'Email (tidak dapat diubah)', value: email, icon: Icons.mail_outline),
              _readOnlyField(label: 'NIK (tidak dapat diubah)', value: nik, icon: Icons.badge_outlined),

              _sectionTitle('Identitas'),
              _field(
                controller: _fullName,
                label: 'Nama Lengkap',
                hint: 'Sesuai KTP/identitas',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                errorText: _fieldError('full_name'),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : 'Nama lengkap wajib diisi.',
              ),
              _field(
                controller: _phone,
                label: 'No. HP',
                hint: '+628123456789',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                errorText: _fieldError('phone'),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : 'Nomor HP wajib diisi.',
              ),
              _field(
                controller: _birthDate,
                label: 'Tanggal Lahir (usia minimal 18 tahun)',
                hint: 'Pilih tanggal',
                icon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickBirthDate,
                errorText: _fieldError('birth_date'),
                validator: (v) =>
                    v != null && v.isNotEmpty ? null : 'Tanggal lahir wajib diisi.',
              ),
              _field(
                controller: _occupation,
                label: 'Pekerjaan',
                hint: 'Mahasiswa / Karyawan / ...',
                icon: Icons.work_outline_rounded,
                textCapitalization: TextCapitalization.words,
                errorText: _fieldError('occupation'),
              ),
              _field(
                controller: _address,
                label: 'Alamat Asal',
                hint: 'Alamat domisili sebelum menyewa',
                icon: Icons.home_outlined,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                errorText: _fieldError('address'),
              ),

              _sectionTitle('Penanggung Jawab'),
              _field(
                controller: _guardianName,
                label: 'Nama Penanggung Jawab (opsional)',
                hint: 'Nama orang tua / wali',
                icon: Icons.family_restroom,
                textCapitalization: TextCapitalization.words,
                errorText: _fieldError('guardian_name'),
              ),
              _field(
                controller: _guardianPhone,
                label: 'No. HP Penanggung Jawab',
                hint: '+628123456789',
                icon: Icons.phone_in_talk_outlined,
                keyboardType: TextInputType.phone,
                errorText: _fieldError('guardian_phone'),
                validator: (v) => v != null && v.trim().isNotEmpty
                    ? null
                    : 'Nomor HP penanggung jawab wajib diisi.',
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
                    : const Text('Simpan Perubahan'),
              ),
              const SizedBox(height: 24),
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

  /// Field hanya-baca (email & NIK).
  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            readOnly: true,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textMuted),
              suffixIcon: const Icon(Icons.lock_outline_rounded,
                  size: 16, color: AppColors.textMuted),
            ),
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    String? errorText,
    TextInputType? keyboardType,
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
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              errorText: errorText,
            ),
          ),
        ],
      ),
    );
  }
}
