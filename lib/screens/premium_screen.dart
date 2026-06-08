import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});
  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  bool _isProcessing = false;
  String? _selectedPlan; // 'monthly' or 'yearly'

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _subscribe(String planType) async {
    setState(() { _isProcessing = true; _selectedPlan = planType; });
    await Future.delayed(const Duration(milliseconds: 300));

    // Redirect ke WhatsApp untuk konfirmasi pembayaran
    final label = planType == 'yearly' ? 'Tahunan (Rp 79.000)' : '3 Bulan (Rp 10.000)';
    final message = Uri.encodeComponent(
      'Halo kak, saya mau berlangganan PlusSound Premium paket $label. '
      'Tolong konfirmasi cara pembayarannya. Terima kasih!',
    );
    final waUrl = Uri.parse('https://wa.me/6282297706541?text=$message');

    setState(() => _isProcessing = false);

    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp tidak tersedia. Hubungi: 082297706541'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<app_auth.AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.black, size: 18),
                            const SizedBox(width: 6),
                            Text('PLUSSOUND PREMIUM', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Nikmati Musik Tanpa Batas', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Tanpa iklan. Kualitas HD. Offline.', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_slideAnim),
              child: FadeTransition(
                opacity: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Fitur Premium
                      _buildFeatureCard('🎵', 'Audio Kualitas HD 320kbps', 'Dengar setiap detail suara dengan jernih'),
                      _buildFeatureCard('📥', 'Download Lagu Offline', 'Simpan lagu favorit & dengar tanpa internet'),
                      _buildFeatureCard('🚫', 'Tanpa Iklan', 'Dengarkan musik tanpa gangguan apapun'),
                      _buildFeatureCard('♾️', 'Skip Unlimited', 'Lewati lagu sesering yang Anda mau'),
                      _buildFeatureCard('📝', 'Lirik Real-time', 'Ikuti setiap bait lagu dengan lirik sinkron'),
                      const SizedBox(height: 32),
                      Text('Pilih Paket Anda', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      // Plan 3 Bulan
                      _buildPlanCard(
                        planType: 'quarterly',
                        label: '3 Bulan',
                        price: 'Rp 10.000',
                        period: '/ 3 bln',
                        badge: null,
                        isSelected: _selectedPlan == 'quarterly',
                        onTap: authProv.isPremium ? null : () => _subscribe('quarterly'),
                      ),
                      const SizedBox(height: 12),
                      // Plan tahunan (lebih hemat)
                      _buildPlanCard(
                        planType: 'yearly',
                        label: 'Tahunan',
                        price: 'Rp 79.000',
                        period: '/ tahun',
                        badge: 'Hemat 34%',
                        isSelected: _selectedPlan == 'yearly',
                        onTap: authProv.isPremium ? null : () => _subscribe('yearly'),
                      ),
                      const SizedBox(height: 24),
                      if (authProv.isPremium)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppTheme.primaryColor.withAlpha(50), AppTheme.primaryColor.withAlpha(20)]),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.primaryColor.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              Text('Anda sudah berlangganan Premium! 🎉', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 30),
                      // WhatsApp info — bisa diklik
                      GestureDetector(
                        onTap: () async {
                          final message = Uri.encodeComponent(
                            'Halo kak, saya mau berlangganan PlusSound Premium. '
                            'Tolong konfirmasi cara pembayarannya. Terima kasih!',
                          );
                          final waUrl = Uri.parse('https://wa.me/6282297706541?text=$message');
                          if (await canLaunchUrl(waUrl)) {
                            await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF25D366).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hubungi via WhatsApp', style: GoogleFonts.inter(color: const Color(0xFF25D366), fontSize: 11, fontWeight: FontWeight.w500)),
                                  Text('082297706541', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF25D366), size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Ketuk untuk langsung ke WhatsApp', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withAlpha(150),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planType,
    required String label,
    required String price,
    required String period,
    String? badge,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    final bool isActive = _isProcessing && _selectedPlan == planType;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: badge != null
              ? const LinearGradient(colors: [Color(0xFF1a6b3c), Color(0xFF0d4025)])
              : null,
          color: badge == null ? AppTheme.surfaceColor : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge != null ? AppTheme.primaryColor : Colors.white24,
            width: badge != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(badge, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(price, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                      const SizedBox(width: 4),
                      Text(period, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            isActive
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2))
                : ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: badge != null ? AppTheme.primaryColor : Colors.white24,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: Text(onTap == null ? 'Aktif' : 'Pilih', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}
