import 'package:flutter/material.dart';

import '../api.dart';
import '../brand.dart';
import '../notify.dart';
import 'admin_home.dart';
import 'faculty_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _remember = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.instance.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      final next =
          Session.instance.isAdmin ? const AdminHome() : const FacultyHome();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => next),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: Column(
        children: [
          // 1. Top Unified Dark Green Navigation Bar
          _buildTopNavBar(context, isDesktop: isDesktop),

          // 2. Main Content Area
          Expanded(
            child: isDesktop
                ? _buildDesktopBody(context)
                : _buildMobileBody(context),
          ),
        ],
      ),
    );
  }

  // ==================== TOP NAVIGATION BAR ====================

  Widget _buildTopNavBar(BuildContext context, {required bool isDesktop}) {
    return Container(
      height: 64,
      width: double.infinity,
      color: const Color(0xFF073E20), // CSUCC Deep Forest Green
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 36 : 16),
      child: Row(
        children: [
          // CSUCC Seal — clean transparent PNG, no white circle needed
          Image.asset(
            Brand.seal,
            width: 46,
            height: 46,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.school,
              size: 30,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 14),

          // Subtle Vertical Divider
          Container(
            width: 1.2,
            height: 30,
            color: Colors.white24,
          ),
          const SizedBox(width: 14),

          // Title & Office Text
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CARAGA STATE UNIVERSITY – CABADBARAN CAMPUS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isDesktop ? 13.5 : 11.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Office of Internationalization and Global Engagement (OIGE)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isDesktop ? 11.0 : 9.0,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFD1FAE5),
                  ),
                ),
              ],
            ),
          ),

          // Pushes the navigation links to the far right corner
          if (isDesktop) const Spacer(),

          // Right Navigation Items (Desktop only) placed on the right corner
          if (isDesktop) ...[
            _navItem(
              label: 'Home',
              icon: Icons.home,
              isActive: true,
            ),
            const SizedBox(width: 28),
            _navItem(label: 'About'),
            const SizedBox(width: 28),
            _navItem(label: 'Help'),
            const SizedBox(width: 28),
            _languageSelector(),
          ],
        ],
      ),
    );
  }

  Widget _navItem({
    required String label,
    IconData? icon,
    bool isActive = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        if (isActive) ...[
          const SizedBox(height: 4),
          Container(
            width: 42,
            height: 2.8,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }

  Widget _languageSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.public,
          size: 16,
          color: Colors.white.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 6),
        Text(
          'EN',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(width: 3),
        Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ],
    );
  }

  // ==================== DESKTOP LAYOUT ====================

  /// Full-bleed background — bg.png covers the entire screen edge-to-edge.
  /// Anchored to bottomCenter so the campus building is always visible.
  Widget _fullBackground() {
    return Image.asset(
      Brand.bg,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.bottomCenter,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF0FDF4)),
    );
  }

  Widget _buildDesktopBody(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-screen unified background (whole bg.png always visible)
        _fullBackground(),

        // 2. Main Content: Left Branding & Right Login Form
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Panel: SMARTTRACK branding + 4 Features
                // Pushed to upper area (y=-0.58) so building shows at bottom
                Expanded(
                  flex: 56,
                  child: Align(
                    alignment: const Alignment(0.05, -0.58),
                    child: _buildLeftBrandContent(context, isDesktop: true),
                  ),
                ),
                const SizedBox(width: 24),

                // Right Panel: Floating Login Card
                Expanded(
                  flex: 44,
                  child: Align(
                    alignment: const Alignment(0.35, -0.48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: _buildLoginCard(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== LEFT BRAND CONTENT ====================

  Widget _buildLeftBrandContent(BuildContext context, {required bool isDesktop}) {
    final logoSize = isDesktop ? 96.0 : 64.0;
    final smartFontSize = isDesktop ? 60.0 : 40.0;
    final subtitleFontSize = isDesktop ? 14.5 : 11.5;
    final taglineFontSize = isDesktop ? 14.5 : 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo Row: Globe Icon + SMARTTRACK
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                Brand.globe,
                width: logoSize,
                height: logoSize * 0.9,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.public,
                  size: logoSize * 0.85,
                  color: const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'SMART',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: smartFontSize,
                        letterSpacing: -1.8,
                        color: const Color(0xFF0D381E),
                      ),
                    ),
                    TextSpan(
                      text: 'TRACK',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: smartFontSize,
                        letterSpacing: -1.8,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'AI-BASED INTERNATIONAL TRAVEL MONITORING SYSTEM',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: isDesktop ? 1.6 : 0.8,
            color: const Color(0xFF0D381E),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 5),

        // Tagline
        Text(
          'Track. Manage. Ensure Global Opportunities.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: taglineFontSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        SizedBox(height: isDesktop ? 22 : 16),

        // 4 Feature Pills
        if (isDesktop)
          SizedBox(
            width: 540,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.flight,
                    label: 'Travel Records\nMonitoring',
                  ),
                ),
                _FeatureSep(),
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.description_outlined,
                    label: 'Document\nManagement',
                  ),
                ),
                _FeatureSep(),
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.insights,
                    label: 'AI-Powered\nInsights',
                  ),
                ),
                _FeatureSep(),
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.public,
                    label: 'Global\nOpportunities',
                  ),
                ),
              ],
            ),
          )
        else
          // Mobile feature items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: const [
                _FeatureItem(
                  icon: Icons.flight,
                  label: 'Travel Records\nMonitoring',
                  scale: 0.9,
                ),
                _FeatureItem(
                  icon: Icons.description_outlined,
                  label: 'Document\nManagement',
                  scale: 0.9,
                ),
                _FeatureItem(
                  icon: Icons.insights,
                  label: 'AI-Powered\nInsights',
                  scale: 0.9,
                ),
                _FeatureItem(
                  icon: Icons.public,
                  label: 'Global\nOpportunities',
                  scale: 0.9,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==================== LOGIN CARD ====================

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF073E20).withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Top-left emerald wave accent on the card
            Positioned(
              top: 0,
              left: 0,
              width: 58,
              height: 62,
              child: CustomPaint(
                painter: CardCornerWavePainter(),
              ),
            ),

            // Card Body Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Green Avatar Badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Heading
                  const Text(
                    'Access Your SmartTrack Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.2,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Subtitle
                  const Text(
                    'Sign in to your SmartTrack account',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email Input Field
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13.5,
                        ),
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          size: 18,
                          color: Color(0xFF15803D),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF16A34A),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password Input Field
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _password,
                      obscureText: _obscure,
                      onSubmitted: (_) => _login(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13.5,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: Color(0xFF15803D),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: const Color(0xFF15803D),
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF16A34A),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Remember me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _remember,
                              activeColor: const Color(0xFF15803D),
                              side: const BorderSide(
                                color: Color(0xFF15803D),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (v) =>
                                  setState(() => _remember = v ?? false),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Flexible(
                              child: Text(
                                'Remember me',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Notify.info(
                          'Please contact OIGE to reset your password.',
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Sign In Pill Button
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF15803D), Color(0xFF0D6832)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D6832)
                                  .withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Error notification if any
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 15,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // "or" Divider
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Authorized Users Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF8F1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFBBF7D0),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 22,
                          color: Color(0xFF15803D),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Authorized users only',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0D381E),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'This system is for CSUCC faculty and OIGE personnel.',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MOBILE / COMPACT BODY ====================

  Widget _buildMobileBody(BuildContext context) {
    return Stack(
      children: [
        // Background image (same full-visibility treatment as desktop)
        Positioned.fill(
          child: _fullBackground(),
        ),

        // Scrollable Content
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _buildLeftBrandContent(context, isDesktop: false),
                    const SizedBox(height: 20),
                    _buildLoginCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== SUPPORTING WIDGETS & PAINTERS ====================

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.label,
    this.scale = 1.0,
  });
  final IconData icon;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final circleSize = 50.0 * scale;
    final iconSize = 22.0 * scale;
    final fontSize = 11.5 * scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6EE),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: iconSize, color: const Color(0xFF15803D)),
        ),
        SizedBox(height: 6 * scale),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _FeatureSep extends StatelessWidget {
  const _FeatureSep();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: const Color(0xFFCBD5E1),
      margin: const EdgeInsets.symmetric(horizontal: 5),
    );
  }
}

/// Paints the decorative curved green wave in the top-left corner of the login card
class CardCornerWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF22C55E), Color(0xFF15803D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.25,
        size.width * 0.20,
        size.height * 0.65,
        0,
        size.height,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Highlight border line along the curve
    final strokePaint = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final strokePath = Path()
      ..moveTo(size.width, 0)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.25,
        size.width * 0.20,
        size.height * 0.65,
        0,
        size.height,
      );

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
