import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Nama tidak boleh kosong.');
      return;
    }
    final authProv = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final ok = await authProv.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
    );
    if (!ok && mounted) {
      _showError(authProv.errorMessage);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<app_auth.AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Buat Akun', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryColor, size: 38),
            ),
            const SizedBox(height: 16),
            Text('Bergabung Gratis', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Daftarkan akun PlusSound Anda', style: GoogleFonts.inter(color: AppTheme.secondaryTextColor, fontSize: 13)),
            const SizedBox(height: 32),
            _buildField(controller: _nameController, label: 'Nama Tampilan', icon: Icons.badge_outlined),
            const SizedBox(height: 14),
            _buildField(controller: _emailController, label: 'Email', icon: Icons.email_outlined, inputType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _buildField(
              controller: _passwordController,
              label: 'Kata Sandi (min. 6 karakter)',
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.secondaryTextColor),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: authProv.isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: authProv.isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Daftar Sekarang', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ATAU', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                ),
                const Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: authProv.isLoading ? null : () async {
                  final ok = await authProv.loginWithGoogle();
                  if (!ok && mounted && authProv.errorMessage.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(authProv.errorMessage), backgroundColor: Colors.redAccent),
                    );
                  } else if (ok && mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                  height: 24,
                ),
                label: Text('Daftar dengan Google', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sudah punya akun? ', style: GoogleFonts.inter(color: AppTheme.secondaryTextColor)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Masuk', style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.secondaryTextColor),
        prefixIcon: Icon(icon, color: AppTheme.secondaryTextColor),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
