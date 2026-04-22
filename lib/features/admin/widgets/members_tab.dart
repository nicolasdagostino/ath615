
import 'package:flutter/material.dart';

class MembersTab extends StatelessWidget {
  final List<Map<String, dynamic>> members;

  const MembersTab({
    super.key,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(child: Text('No members'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final name = member['full_name']?.toString().trim();
        final email = member['email']?.toString().trim();
        final role = member['role']?.toString().trim();

        return ListTile(
          title: Text(name != null && name.isNotEmpty ? name : 'No name'),
          subtitle: Text(email != null && email.isNotEmpty ? email : ''),
          trailing: Text(role != null && role.isNotEmpty ? role : ''),
        );
      },
    );
  }
}
