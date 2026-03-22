import 'package:flutter/material.dart';
import '../../core/auth/user_session.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;

  const RoleGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (UserSession().isAdmin) {
      return child;
    }

    return const SizedBox();
  }
}
