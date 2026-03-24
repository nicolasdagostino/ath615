import 'package:flutter/material.dart';

Future<void> showClassModal({
  required BuildContext context,
  required bool isEdit,
  required Function setLocalState,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return const SizedBox();
    },
  );
}
