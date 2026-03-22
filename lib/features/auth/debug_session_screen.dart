import 'package:flutter/material.dart';
import '../../core/supabase/auth_repository.dart';

class DebugSessionScreen extends StatefulWidget {
  const DebugSessionScreen({super.key});

  @override
  State<DebugSessionScreen> createState() => _DebugSessionScreenState();
}

class _DebugSessionScreenState extends State<DebugSessionScreen> {
  String message = 'Ready';

  Future<void> _clear() async {
    try {
      await AuthRepository().hardSignOutAndClear();
      if (!mounted) return;
      setState(() {
        message = 'Local session cleared';
      });
    } catch (e) {
      setState(() {
        message = 'Error clearing session';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthRepository().currentSession();

    return Scaffold(
      appBar: AppBar(title: const Text('Debug Session')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Has session: ${session != null}'),
            const SizedBox(height: 12),
            SelectableText('User id: ${session?.user.id ?? 'none'}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clear,
              child: const Text('Clear local session'),
            ),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}
