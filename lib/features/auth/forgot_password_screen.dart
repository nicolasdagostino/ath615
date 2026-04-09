import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/supabase/auth_repository.dart';
import '../../shared/widgets/input_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../l10n/app_text.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authRepo = AuthRepository();
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailCtrl.dispose();
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

  Future<void> _sendReset() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await _authRepo.resetPassword(_emailCtrl.text.trim());
      setState(() {
        _success = 'Reset email sent. Check your inbox.';
      });
    } catch (e) {
      setState(() {
        _error = 'Could not send reset email';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _authInput() {
    return InputField(
      label: 'Email',
      hint: 'Enter email',
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      onChanged: (_) {
        if (!mounted) return;
        setState(() {
          if (_error != null) _error = null;
          if (_success != null) _success = null;
        });
      },
      onSubmitted: (_) {
        if (!_loading && _emailCtrl.text.trim().isNotEmpty) {
          _sendReset();
        }
      },
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
    final canSubmit = !_loading && _emailCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.25),
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 20),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 0),
                    padding: const EdgeInsets.fromLTRB(32, 18, 32, 24),
                    decoration: const BoxDecoration(
                      color: AppColors.authBackground,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 90,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(
                              Icons.close_rounded,
                              size: 34,
                              color: AppColors.authAccent,
                            ),
                          ),
                          const SizedBox(height: 56),
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
                          const SizedBox(height: 26),
                          Text(
                            context.appText.forgotPasswordTitle,
                            style: _font(
                              28,
                              weight: FontWeight.w800,
                              color: AppColors.authText,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.appText.forgotPasswordSubtitle,
                            style: _font(
                              16,
                              weight: FontWeight.w500,
                              color: AppColors.authText.withValues(alpha: 0.82),
                              height: 1.25,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 26),
                          _authInput(),
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
                              text: context.appText.restorePassword,
                              onPressed: canSubmit ? _sendReset : null,
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
                          const SizedBox(height: 42),
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text(
                                context.appText.back,
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
                          Center(
                            child: Row(
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
                            ),
                          ),
                        ],
                      ),
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
