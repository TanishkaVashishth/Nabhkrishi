import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';

enum AuthMode { signIn, signUp, forgotPassword }

class LoginPage extends ConsumerStatefulWidget {
  final String language;

  const LoginPage({super.key, required this.language});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  AuthMode _mode = AuthMode.signIn;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  String? _localError;

  bool get isHindi => widget.language.toLowerCase() == 'hindi' || widget.language.toLowerCase() == 'hi';

  String get title {
    if (_mode == AuthMode.signIn) {
      return AppLocalizations.get('welcome_title', widget.language);
    } else if (_mode == AuthMode.signUp) {
      return AppLocalizations.get('create_account', widget.language);
    } else {
      return AppLocalizations.get('reset_password', widget.language);
    }
  }

  String get subtitle {
    if (_mode == AuthMode.signIn) {
      return AppLocalizations.get('welcome_subtitle', widget.language);
    } else if (_mode == AuthMode.signUp) {
      return AppLocalizations.get('join_subtitle', widget.language);
    } else {
      return AppLocalizations.get('reset_subtitle', widget.language);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode newMode) {
    setState(() {
      _mode = newMode;
      _localError = null;
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
    ref.read(authNotifierProvider.notifier).reset();
  }

  bool _validateFields() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    // Email check
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _localError = 'error_invalid_email';
      });
      return false;
    }

    if (_mode == AuthMode.signUp) {
      // Name check
      if (name.isEmpty) {
        setState(() {
          final l = widget.language.toLowerCase();
          if (l.contains('pa') || l.contains('punjabi')) {
            _localError = 'ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਪੂਰਾ ਨਾਮ ਦਰਜ ਕਰੋ।';
          } else if (l.contains('bn') || l.contains('bengali')) {
            _localError = 'অনুগ্রহ করে আপনার পুরো নাম লিখুন।';
          } else if (l.contains('hr') || l.contains('haryanvi')) {
            _localError = 'अपना पूरा नाम लिखो जी।';
          } else if (l.contains('hinglish')) {
            _localError = 'Kripya apna poora naam darj karein.';
          } else if (l.contains('hi') || l.contains('hindi')) {
            _localError = 'कृपया अपना पूरा नाम दर्ज करें।';
          } else {
            _localError = 'Please enter your full name.';
          }
        });
        return false;
      }
    }

    if (_mode != AuthMode.forgotPassword) {
      // Password check
      if (password.isEmpty || password.length < 6) {
        setState(() {
          _localError = 'error_weak_password';
        });
        return false;
      }
    }

    if (_mode == AuthMode.signUp) {
      // Password match check
      if (password != confirm) {
        setState(() {
          _localError = 'error_passwords_mismatch';
        });
        return false;
      }
    }

    setState(() {
      _localError = null;
    });
    return true;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_validateFields()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (_mode == AuthMode.signIn) {
      ref.read(authNotifierProvider.notifier).loginWithEmailAndPassword(
            email: email,
            password: password,
          );
    } else if (_mode == AuthMode.signUp) {
      ref.read(authNotifierProvider.notifier).signUpWithEmailAndPassword(
            email: email,
            password: password,
            name: name,
          );
    } else if (_mode == AuthMode.forgotPassword) {
      ref.read(authNotifierProvider.notifier).resetPassword(email: email);
    }
  }

  void _googleLogin() {
    FocusScope.of(context).unfocus();
    ref.read(authNotifierProvider.notifier).loginWithGoogle();
  }

  String? _getLocalizedError(String? errorKey) {
    if (errorKey == null) return null;
    if (errorKey.startsWith('error_')) {
      return context.translate(errorKey, widget.language);
    }
    return errorKey;
  }

  void _showSuccess() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3150).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF6AE8BE).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF5DE2B0).withValues(alpha: 0.14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5DE2B0).withValues(alpha: 0.22),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF72F0C1),
                            size: 40,
                          ),
                        ).animate().scale(
                          duration: 500.ms,
                          curve: Curves.easeOutBack,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          isHindi ? 'सत्यापन सफल!' : 'Verification successful!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isHindi ? 'लॉगिन पूरा हो गया है।' : 'Your login is complete.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6AE8BE),
                              foregroundColor: const Color(0xFF063B2D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              context.translate('confirm_farm_area', widget.language), // Fallback text
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      setState(() {
        _loading = next.isLoading;
      });

      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        _showSuccess();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final currentLoading = _loading || authState.isLoading;
    final rawError = _localError ?? authState.errorMessage;
    final resolvedError = _getLocalizedError(rawError);

    return Scaffold(
      backgroundColor: const Color(0xFF04172F),
      body: Stack(
        children: [
          const _LoginBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onPressed: () {
                    if (_mode != AuthMode.signIn) {
                      _switchMode(AuthMode.signIn);
                    } else {
                      Navigator.pop(context);
                    }
                  }),
                  const SizedBox(height: 24),
                  Center(
                    child: const _MiniLeaf()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          end: const Offset(1, 1),
                          duration: 650.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Column(
                      key: ValueKey(_mode),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_mode == AuthMode.signUp) ...[
                          _GlassTextField(
                            controller: _nameController,
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 20),
                            hint: context.translate('name_label', widget.language),
                            keyboardType: TextInputType.name,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _GlassTextField(
                          controller: _emailController,
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70, size: 20),
                          hint: context.translate('email_label', widget.language),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        if (_mode != AuthMode.forgotPassword) ...[
                          const SizedBox(height: 16),
                          _GlassTextField(
                            controller: _passwordController,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 20),
                            hint: context.translate('password_label', widget.language),
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white38,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ],
                        if (_mode == AuthMode.signUp) ...[
                          const SizedBox(height: 16),
                          _GlassTextField(
                            controller: _confirmPasswordController,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 20),
                            hint: context.translate('confirm_password_label', widget.language),
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white38,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ],
                        if (_mode == AuthMode.signIn) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _switchMode(AuthMode.forgotPassword),
                              child: Text(
                                context.translate('forgot_password', widget.language),
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF6AE8BE),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 18),
                        ],
                        if (resolvedError != null) ...[
                          Text(
                            resolvedError,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFFA7A7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (_mode == AuthMode.forgotPassword && authState.isResetEmailSent) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF39C793).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF39C793).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              isHindi
                                  ? 'पासवर्ड रीसेट लिंक आपके ईमेल पर भेज दिया गया है।'
                                  : 'Password reset link has been sent to your email.',
                              style: GoogleFonts.poppins(color: const Color(0xFF6CE6B6), fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _GlowButton(
                          text: _mode == AuthMode.signIn
                              ? context.translate('sign_in', widget.language)
                              : (_mode == AuthMode.signUp
                                  ? context.translate('create_account', widget.language)
                                  : (isHindi ? 'पासवर्ड रीसेट करें' : 'Reset Password')),
                          loading: currentLoading,
                          onPressed: _submit,
                        ),
                        if (_mode == AuthMode.signIn) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  isHindi ? 'या' : 'OR',
                                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _GoogleButton(isHindi: isHindi, loading: currentLoading, onPressed: _googleLogin),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _mode == AuthMode.signIn
                                  ? context.translate('dont_have_account', widget.language)
                                  : context.translate('already_have_account', widget.language),
                              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12.5),
                            ),
                            TextButton(
                              onPressed: () {
                                _switchMode(_mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn);
                              },
                              child: Text(
                                _mode == AuthMode.signIn
                                    ? context.translate('create_account', widget.language)
                                    : context.translate('sign_in', widget.language),
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF6AE8BE),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TEXT FIELD COMPONENT
// -----------------------------------------------------------------------------

class _GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;

  const _GlassTextField({
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  State<_GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<_GlassTextField> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        setState(() {
          focused = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: focused
                ? const Color(0xFF6AE8BE).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.10),
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF5DE2B0).withValues(alpha: 0.12),
                    blurRadius: 28,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            if (widget.prefixIcon != null) ...[
              widget.prefixIcon!,
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 18,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                obscureText: widget.obscureText,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14.5,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.32),
                    fontSize: 14.5,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (widget.suffixIcon != null) widget.suffixIcon!,
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BUTTONS
// -----------------------------------------------------------------------------

class _GlowButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback onPressed;

  const _GlowButton({
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5DE2B0).withValues(alpha: 0.20),
              blurRadius: 25,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6AE8BE),
            disabledBackgroundColor: const Color(0xFF6AE8BE).withValues(alpha: 0.55),
            foregroundColor: const Color(0xFF063B2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: loading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF063B2D),
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isHindi;
  final bool loading;
  final VoidCallback onPressed;

  const _GoogleButton({
    required this.isHindi,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.13)),
          backgroundColor: Colors.white.withValues(alpha: 0.045),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isHindi ? 'Google से जारी रखें' : 'Continue with Google',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.white70,
        size: 18,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.055),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

class _MiniLeaf extends StatelessWidget {
  const _MiniLeaf();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(54, 54), painter: _LeafPainter());
  }
}

// -----------------------------------------------------------------------------
// BACKGROUND
// -----------------------------------------------------------------------------

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF04152F),
                Color(0xFF082D4A),
                Color(0xFF063E3B),
                Color(0xFF041C2A),
              ],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _AmbientGlow(size: 320, color: const Color(0xFF45D9A4)),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: _AmbientGlow(size: 360, color: const Color(0xFF1479A8)),
        ),
        CustomPaint(painter: _FieldLinesPainter()),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.13),
              blurRadius: 120,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAINTERS
// -----------------------------------------------------------------------------

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8BFFD2), Color(0xFF2DBF8A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.88)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.72,
        size.width * 0.15,
        size.height * 0.30,
        size.width * 0.52,
        size.height * 0.12,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.24,
        size.width * 0.84,
        size.height * 0.58,
        size.width * 0.5,
        size.height * 0.88,
      )
      ..close();

    canvas.drawPath(path, paint);

    final vein = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.82),
      Offset(size.width * 0.5, size.height * 0.22),
      vein,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _FieldLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7AE9C4).withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = -3; i < 9; i++) {
      final path = Path();
      path.moveTo(size.width * 0.05, size.height * (0.25 + i * 0.10));
      path.cubicTo(
        size.width * 0.35,
        size.height * (0.10 + i * 0.10),
        size.width * 0.65,
        size.height * (0.38 + i * 0.10),
        size.width * 1.05,
        size.height * (0.22 + i * 0.10),
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
