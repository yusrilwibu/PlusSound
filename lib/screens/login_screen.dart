import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../theme.dart';
import 'register_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final authProv = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final ok = await authProv.login(_emailController.text.trim(), _passwordController.text.trim());
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProv.errorMessage), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<app_auth.AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.music_note_rounded, color: AppTheme.primaryColor, size: 44),
                ),
                const SizedBox(height: 20),
                Text('Masuk ke PlusSound',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Musik tanpa batas kapan saja',
                    style: GoogleFonts.inter(color: AppTheme.secondaryTextColor, fontSize: 14)),
                const SizedBox(height: 40),
                _buildField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _passwordController,
                  label: 'Kata Sandi',
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
                    onPressed: authProv.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: authProv.isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text('Masuk', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                    label: Text('Masuk dengan Google', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Belum punya akun? ', style: GoogleFonts.inter(color: AppTheme.secondaryTextColor)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: Text('Daftar', style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Lewati untuk sekarang', style: GoogleFonts.inter(color: AppTheme.secondaryTextColor, fontSize: 13)),
                ),
              ],
            ),
          ),
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
