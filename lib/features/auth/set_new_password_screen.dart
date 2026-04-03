import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../../shared/widgets/input_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../l10n/app_text.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (pass.length < 6) {
      setState(() {
        _loading = false;
        _error = 'Password must be at least 6 characters';
      });
      return;
    }

    if (pass != confirm) {
      setState(() {
        _loading = false;
        _error = 'Passwords do not match';
      });
      return;
    }

    try {
      await sb.auth.updateUser(UserAttributes(password: pass));

      if (!mounted) return;
      setState(() {
        _success = 'Password updated successfully.';
      });

      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not update password';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _authInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return InputField(
      label: label,
      hint: hint,
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
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
      suffixIcon: IconButton(
        onPressed: onToggle,
        splashRadius: 20,
        icon: Icon(
          obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: AppColors.authAccent,
          size: 22,
        ),
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
        _passCtrl.text.trim().isNotEmpty &&
        _confirmCtrl.text.trim().isNotEmpty;

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
              mainAxisSize: MainAxisSize.min,
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
                  context.appText.setNewPasswordTitle,
                  style: _font(
                    28,
                    weight: FontWeight.w800,
                    color: AppColors.authText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.appText.setNewPasswordSubtitle,
                  style: _font(
                    16,
                    weight: FontWeight.w500,
                    color: AppColors.authText.withValues(alpha: 0.82),
                    height: 1.25,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 28),
                _authInput(
                  label: context.appText.newPassword,
                  hint: context.appText.enterNewPassword,
                  controller: _passCtrl,
                  obscure: _obscurePassword,
                  onToggle: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _authInput(
                  label: context.appText.confirmPasswordLabel,
                  hint: context.appText.repeatNewPassword,
                  controller: _confirmCtrl,
                  obscure: _obscureConfirm,
                  onToggle: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 14),
                Text(
                  context.appText.useAtLeast6Chars,
                  style: _font(
                    14,
                    weight: FontWeight.w500,
                    color: AppColors.authPlaceholder,
                    height: 1.2,
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
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: context.appText.updatePasswordCta,
                    onPressed: canSubmit ? _save : null,
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
                const SizedBox(height: 56),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
