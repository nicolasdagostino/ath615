
import 'package:flutter/material.dart';

class AdminWorkoutsTab extends StatelessWidget {

  final bool loading;
  final List items;
  final bool adminActionBusy;
  final Function() onAdd;
  final Function(Map<String,dynamic>) onEdit;
  final Function(Map<String,dynamic>) onActions;
  final dynamic font;

  const AdminWorkoutsTab({
    super.key,
    required this.loading,
    required this.items,
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
                'Workouts',
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
            )

          ],
        ),

        const SizedBox(height:12),

        if(loading)
          const Center(child:CircularProgressIndicator())
        else if(items.isEmpty)
          const SizedBox()
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom:10),
                child: GestureDetector(
                  onTap: adminActionBusy ? null : () => onEdit(item),
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
                            item.toString(),
                            style: font(
                              16,
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
