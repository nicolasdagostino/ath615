import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'register_screen.dart';

class NoAccountInfoScreen extends StatelessWidget {
  const NoAccountInfoScreen({super.key});

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

  void _openRegister(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.25),
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
                      color: Colors.white.withOpacity(0.82),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(32, 18, 32, 24),
                    decoration: const BoxDecoration(
                      color: AppColors.authBackground,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
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
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x16000000),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: AspectRatio(
                              aspectRatio: 1.12,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    'assets/images/auth/auth_no_account_hero.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.10),
                                          Colors.black.withOpacity(0.18),
                                          Colors.black.withOpacity(0.48),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 16,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.30),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.20),
                                        ),
                                      ),
                                      child: Text(
                                        'ATH615',
                                        style: _font(
                                          14,
                                          weight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 18,
                                    right: 18,
                                    bottom: 18,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'ATHLETE LAB',
                                          style: _font(
                                            26,
                                            weight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'LIFT • SQUAT • PULL • PUSH',
                                          style: _font(
                                            15,
                                            weight: FontWeight.w700,
                                            color: Colors.white.withOpacity(
                                              0.96,
                                            ),
                                            letterSpacing: 0.8,
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
                        const SizedBox(height: 28),
                        Text(
                          "DON'T HAVE AN ACCOUNT?",
                          style: _font(
                            28,
                            weight: FontWeight.w800,
                            color: AppColors.authText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'ATH615 access is designed for athletes registered in one of our training programs.',
                          style: _font(
                            16,
                            weight: FontWeight.w500,
                            color: AppColors.authText.withOpacity(0.84),
                            height: 1.28,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'You can request access or create your account to start booking classes, following workouts and using the full Athlete Lab experience.',
                          style: _font(
                            16,
                            weight: FontWeight.w500,
                            color: AppColors.authText.withOpacity(0.84),
                            height: 1.28,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: 'CREATE ACCOUNT',
                            onPressed: () => _openRegister(context),
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
                        const SizedBox(height: 26),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text(
                              'BACK',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
