part of 'admin_screen.dart';

extension _AdminScreenProgramModal on _AdminScreenState {
void _showProgramModal({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(
      text: item?['name']?.toString() ?? '',
    );
    final descriptionCtrl = TextEditingController(
      text: item?['description']?.toString() ?? '',
    );

    InputField styledField({
      required String label,
      required TextEditingController controller,
      required String hint,
      TextInputAction? textInputAction,
      int maxLines = 1,
    }) {
      return InputField(
        label: label,
        controller: controller,
        hint: hint,
        textInputAction: textInputAction,
        maxLines: maxLines,
        fillColor: const Color(0xFFF8FAFC),
        borderColor: const Color(0xFFE2E8F0),
        focusedBorderColor: const Color(0xFFB59B6A),
        radius: 16,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: _font(
          12,
          weight: FontWeight.w500,
          color: const Color(0xFF667085),
        ),
        hintStyle: _font(
          13,
          weight: FontWeight.w500,
          color: const Color(0xFF98A2B3),
        ),
        textStyle: _font(
          13,
          weight: FontWeight.w500,
          color: const Color(0xFF111318),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            top: 36,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7DBE1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F3EA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.widgets_rounded,
                              color: Color(0xFFB59B6A),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit Program' : 'Create Program',
                                  style: _font(
                                    24,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFF111318),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEdit
                                      ? 'Update the program details.'
                                      : 'Add a new training program for your gym.',
                                  style: _font(
                                    13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF8F96A3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE8EBF0)),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 22,
                                color: Color(0xFF111318),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFEAECEF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            styledField(
                              label: 'Program Name',
                              controller: nameCtrl,
                              hint: 'CrossFit',
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            styledField(
                              label: 'Short Description',
                              controller: descriptionCtrl,
                              hint: 'Functional fitness, conditioning and strength',
                              maxLines: 2,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'Cancel',
                              compact: true,
                              radius: 16,
                              textStyle: _font(
                                16,
                                weight: FontWeight.w700,
                                color: const Color(0xFF344054),
                                letterSpacing: -0.15,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              text: isEdit ? 'Save Changes' : 'Create Program',
                              compact: true,
                              radius: 16,
                              backgroundColor: const Color(0xFFB59B6A),
                              pressedColor: const Color(0xFFA88C59),
                              disabledColor: const Color(0xFFC9C9C9),
                              textColor: Colors.white,
                              textStyle: _font(
                                16,
                                weight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.15,
                              ),
                              boxShadow: const [],
                              onPressed: () async {
                                FocusScope.of(context).unfocus();

                                if (isEdit) {
                                  await _runAdminAction(
                                    () => _updateProgram(
                                      id: item['id'].toString(),
                                      name: nameCtrl.text,
                                      description: descriptionCtrl.text,
                                    ),
                                    successMessage: 'Program updated',
                                  );
                                } else {
                                  await _runAdminAction(
                                    () => _createProgram(
                                      name: nameCtrl.text,
                                      description: descriptionCtrl.text,
                                    ),
                                    successMessage: 'Program created',
                                  );
                                }

                                if (!mounted) return;
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
