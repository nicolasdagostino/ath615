import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/supabase/auth_repository.dart';
import '../../shared/widgets/input_field.dart';
import '../../shared/widgets/primary_button.dart';
import 'forgot_password_screen.dart';
import 'no_account_info_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authRepo = AuthRepository();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  TextStyle _font(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.authText,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.barlowCondensed(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authRepo.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      setState(() {
        _error = 'Invalid email or password';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => const ForgotPasswordScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _openNoAccountInfo() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => const NoAccountInfoScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _poweredBy() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'POWERED BY',
          style: _font(
            14,
            weight: FontWeight.w700,
            color: const Color(0xFF171923),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'ATH615',
          style: _font(
            28,
            weight: FontWeight.w800,
            color: const Color(0xFF171923),
            letterSpacing: 1.2,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _authInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return InputField(
      label: label,
      hint: hint,
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      suffixIcon: suffixIcon,
      fillColor: Colors.white,
      borderColor: AppColors.authBorder,
      focusedBorderColor: AppColors.authAccent,
      radius: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      labelStyle: GoogleFonts.barlowCondensed(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.authText,
      ),
      hintStyle: GoogleFonts.barlowCondensed(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.authPlaceholder,
      ),
      textStyle: GoogleFonts.barlowCondensed(
        fontSize: 16,
        color: AppColors.authText,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        !_loading &&
        _emailCtrl.text.trim().isNotEmpty &&
        _passwordCtrl.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 22, 32, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 70,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),
                Center(
                  child: Text(
                    'ATHLETE LAB',
                    style: _font(
                      40,
                      weight: FontWeight.w800,
                      color: AppColors.authText,
                      letterSpacing: -0.8,
                      height: 0.95,
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                Text(
                  'ATHLETE LOGIN',
                  style: _font(
                    28,
                    weight: FontWeight.w800,
                    color: AppColors.authText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Lift. Squat. Pull. Push.',
                  style: _font(
                    16,
                    weight: FontWeight.w500,
                    color: AppColors.authText.withOpacity(0.82),
                    height: 1.25,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 26),
                _authInput(
                  label: 'Email',
                  hint: 'Enter email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                _authInput(
                  label: 'Password',
                  hint: 'Enter password',
                  controller: _passwordCtrl,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    splashRadius: 18,
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: AppColors.authIcon,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.authErrorBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.authErrorText,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: _loading ? 'ATHLETE LOGIN' : 'ATHLETE LOGIN',
                    onPressed: canSubmit ? _signIn : null,
                    height: 56,
                    radius: 16,
                    backgroundColor: AppColors.authAccent,
                    pressedColor: AppColors.authAccentDark,
                    disabledColor: AppColors.authButtonDisabled,
                    textColor: Colors.white,
                    textStyle: _font(
                      18,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                    boxShadow: const [],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: _openForgotPassword,
                    child: Text(
                      'FORGOT PASSWORD?',
                      style: _font(
                        15,
                        weight: FontWeight.w800,
                        color: AppColors.authAccent,
                        letterSpacing: -0.05,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 56),
                Center(
                  child: GestureDetector(
                    onTap: _openNoAccountInfo,
                    child: Text(
                      "DON'T HAVE AN ACCOUNT?",
                      textAlign: TextAlign.center,
                      style: _font(
                        15,
                        weight: FontWeight.w800,
                        color: AppColors.authAccent,
                        letterSpacing: -0.05,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 72),
                Center(child: _poweredBy()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
