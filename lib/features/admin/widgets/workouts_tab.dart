
import 'package:flutter/material.dart';

class WorkoutsTab extends StatelessWidget {
  final List<Map<String, dynamic>> workouts;

  const WorkoutsTab({
    super.key,
    required this.workouts,
  });

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return const Center(child: Text('No workouts'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final item = workouts[index];
        return ListTile(
          title: Text(item['title']?.toString() ?? 'No title'),
          subtitle: Text(item['description']?.toString() ?? ''),
        );
      },
    );
  }
}
