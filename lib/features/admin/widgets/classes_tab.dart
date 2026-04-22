
import 'package:flutter/material.dart';

class ClassesTab extends StatelessWidget {
  final List<Map<String, dynamic>> classes;

  const ClassesTab({
    super.key,
    required this.classes,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const Center(child: Text('No classes'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final item = classes[index];
        return ListTile(
          title: Text(item['title']?.toString() ?? item['name']?.toString() ?? 'No title'),
          subtitle: Text(item['description']?.toString() ?? ''),
        );
      },
    );
  }
}
