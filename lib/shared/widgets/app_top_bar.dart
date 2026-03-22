import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const AppTopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  Size get preferredSize => Size.zero;
}
