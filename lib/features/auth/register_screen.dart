import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/supabase/auth_repository.dart';
import '../../shared/widgets/input_field.dart';
import '../../shared/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authRepo = AuthRepository();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nameCtrl.dispose();
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

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await _authRepo.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _success = 'Account created. Check your email to confirm your account.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not create account';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
    TextInputAction? textInputAction,
  }) {
    return InputField(
      label: label,
      hint: hint,
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
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

  Widget _statusCard(String text, {required bool success}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: success ? AppColors.successBg : AppColors.authErrorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: success ? const Color(0xFF166534) : AppColors.authErrorText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        !_loading &&
        _nameCtrl.text.trim().isNotEmpty &&
        _emailCtrl.text.trim().isNotEmpty &&
        _passwordCtrl.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 22, 32, 28),
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
                'CREATE ACCOUNT',
                style: _font(
                  28,
                  weight: FontWeight.w800,
                  color: AppColors.authText,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Join Athlete Lab and start your training journey.',
                style: _font(
                  16,
                  weight: FontWeight.w500,
                  color: AppColors.authText.withValues(alpha: 0.82),
                  height: 1.25,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 26),
              _authInput(
                label: 'Full Name',
                hint: 'Enter full name',
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              _authInput(
                label: 'Email',
                hint: 'Enter email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              _authInput(
                label: 'Password',
                hint: 'Create password',
                controller: _passwordCtrl,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.done,
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
                _statusCard(_error!, success: false),
              ],
              if (_success != null) ...[
                const SizedBox(height: 14),
                _statusCard(_success!, success: true),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: _loading ? 'CREATING ACCOUNT...' : 'CREATE ACCOUNT',
                  onPressed: canSubmit ? _signUp : null,
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
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 15,
                        height: 1.25,
                        color: AppColors.authText.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        const TextSpan(text: 'ALREADY HAVE AN ACCOUNT? '),
                        TextSpan(
                          text: 'SIGN IN',
                          style: GoogleFonts.barlowCondensed(
                            color: AppColors.authAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
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
    );
  }
}
