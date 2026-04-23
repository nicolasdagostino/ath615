import 'package:flutter/material.dart';

class ProgramsTab extends StatelessWidget {
  final List<Map<String, dynamic>> programs;

  const ProgramsTab({super.key, required this.programs});

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) {
      return const Center(child: Text('No programs'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final item = programs[index];
        return ListTile(
          title: Text(item['name']?.toString() ?? 'No name'),
          subtitle: Text(item['description']?.toString() ?? ''),
        );
      },
    );
  }
}
