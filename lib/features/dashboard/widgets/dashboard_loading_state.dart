import 'package:flutter/material.dart';

class DashboardLoadingState extends StatelessWidget {
  const DashboardLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
