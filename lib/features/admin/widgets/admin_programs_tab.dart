
import 'package:flutter/material.dart';

class AdminProgramsTab extends StatelessWidget {
  final bool loading;
  final List programs;
  final bool adminActionBusy;
  final Function() onAdd;
  final Function(Map<String,dynamic>) onEdit;
  final Function(Map<String,dynamic>) onActions;
  final dynamic font;

  const AdminProgramsTab({
    super.key,
    required this.loading,
    required this.programs,
    required this.adminActionBusy,
    required this.onAdd,
    required this.onEdit,
    required this.onActions,
    required this.font,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Programs',
                style: font(
                  18,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                ),
              ),
            ),
            GestureDetector(
              onTap: adminActionBusy ? null : onAdd,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB59B6A),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+ Add',
                  style: font(
                    15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (programs.isEmpty)
          const SizedBox()
        else
          ...programs.map((item) => GestureDetector(
                onTap: adminActionBusy ? null : () => onEdit(item),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFEFF1F4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (item['name'] ?? 'Program').toString(),
                            style: font(
                              18,
                              weight: FontWeight.w700,
                              color: const Color(0xFF111318),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: adminActionBusy
                              ? null
                              : () => onActions(item),
                          child: const Icon(Icons.more_horiz_rounded),
                        )
                      ],
                    ),
                  ),
                ),
              ))
      ],
    );
  }
}
