part of 'admin_screen.dart';

extension _AdminScreenPlanModal on _AdminScreenState {
  void _showPlanModal({Map<String, dynamic>? plan}) {
    final isEdit = plan != null;
    final nameCtrl = TextEditingController(
      text: plan?['name']?.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: plan?['price']?.toString() ?? '',
    );
    final classesCtrl = TextEditingController(
      text: plan?['classes_per_period']?.toString() ?? '',
    );
    final creditsCtrl = TextEditingController(
      text: plan?['credits_total']?.toString() ?? '',
    );
    final bookingWindowCtrl = TextEditingController(
      text: plan?['booking_window_days']?.toString() ?? '7',
    );
    final descriptionCtrl = TextEditingController(
      text: plan?['description']?.toString() ?? '',
    );
    final scrollCtrl = ScrollController();
    final descriptionFocusNode = FocusNode();

    String selectedType = (plan?['plan_type']?.toString().isNotEmpty ?? false)
        ? plan!['plan_type'].toString()
        : 'unlimited';

    String selectedBilling =
        (plan?['billing_period']?.toString().isNotEmpty ?? false)
        ? plan!['billing_period'].toString()
        : 'monthly';

    String suggestedPlanName(String type) {
      switch (type) {
        case 'drop_in':
          return 'Drop-in';
        case 'unlimited':
          return 'Unlimited';
        case 'weekly_limit':
          final classes = classesCtrl.text.trim();
          if (classes == '2') return '2x / week';
          if (classes == '3' || classes.isEmpty) return '3x / week';
          return '${classes}x / week';
        case 'class_pack':
          final credits = creditsCtrl.text.trim();
          if (credits == '1') return '1-class pack';
          if (credits == '10' || credits.isEmpty) return '10-class pack';
          return '$credits-class pack';
        default:
          return '';
      }
    }

    bool shouldAutoReplacePlanName(String currentName) {
      final normalized = currentName.trim().toLowerCase();
      return normalized.isEmpty ||
          normalized == 'drop-in' ||
          normalized == 'unlimited' ||
          normalized == '2x / week' ||
          normalized == '3x / week' ||
          normalized.endsWith('x / week') ||
          normalized == '1-class pack' ||
          normalized == '10-class pack' ||
          normalized.endsWith('-class pack');
    }

    InputDecoration dropdownDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: _font(
          12,
          weight: FontWeight.w500,
          color: const Color(0xFF667085),
        ),
        floatingLabelStyle: _font(
          12,
          weight: FontWeight.w600,
          color: const Color(0xFF667085),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB59B6A), width: 1.2),
        ),
      );
    }

    Widget sectionTitle(String text) {
      return Text(
        text,
        style: _font(
          15,
          weight: FontWeight.w800,
          color: const Color(0xFF111318),
          letterSpacing: -0.1,
        ),
      );
    }

    InputField styledField({
      required String label,
      required TextEditingController controller,
      required String hint,
      TextInputType? keyboardType,
      int maxLines = 1,
      TextInputAction? textInputAction,
      FocusNode? focusNode,
    }) {
      return InputField(
        label: label,
        controller: controller,
        hint: hint,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction: textInputAction,
        focusNode: focusNode,
        fillColor: const Color(0xFFF8FAFC),
        borderColor: const Color(0xFFE2E8F0),
        focusedBorderColor: const Color(0xFFB59B6A),
        radius: 16,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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

    descriptionFocusNode.addListener(() {
      if (descriptionFocusNode.hasFocus && scrollCtrl.hasClients) {
        Future.delayed(const Duration(milliseconds: 180), () {
          if (!scrollCtrl.hasClients) return;
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        });
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(top: 36, bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    final showsClassesPerPeriod =
                        selectedType == 'weekly_limit';
                    final showsCreditsTotal =
                        selectedType == 'class_pack' ||
                        selectedType == 'drop_in';

                    return SingleChildScrollView(
                      controller: scrollCtrl,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(bottom: bottomInset + 24),
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
                                  Icons.badge_rounded,
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
                                      isEdit ? 'Edit Plan' : 'Create Plan',
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
                                          ? 'Update pricing, access rules and booking settings.'
                                          : 'Create a new membership plan for your gym.',
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
                                    border: Border.all(
                                      color: const Color(0xFFE8EBF0),
                                    ),
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
                          sectionTitle('Plan setup'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFEAECEF),
                              ),
                            ),
                            child: Column(
                              children: [
                                styledField(
                                  label: 'Plan Name',
                                  controller: nameCtrl,
                                  hint: 'Unlimited',
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedType,
                                  decoration: dropdownDecoration('Plan Type'),
                                  borderRadius: BorderRadius.circular(16),
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: const Color(0xFF667085),
                                  style: _font(
                                    13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF111318),
                                  ),
                                  items:
                                      const [
                                        DropdownMenuItem(
                                          value: 'drop_in',
                                          child: Text('Drop-In'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'unlimited',
                                          child: Text('Unlimited'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'weekly_limit',
                                          child: Text('Weekly Limit'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'class_pack',
                                          child: Text('Class Pack'),
                                        ),
                                      ].map((item) {
                                        return DropdownMenuItem<String>(
                                          value: item.value,
                                          child: Text(
                                            (item.child as Text).data ?? '',
                                            style: _font(
                                              13,
                                              weight: FontWeight.w500,
                                              color: const Color(0xFF111318),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setLocalState(() {
                                        final canReplaceName =
                                            shouldAutoReplacePlanName(
                                              nameCtrl.text,
                                            );

                                        selectedType = value;

                                        if (value == 'drop_in') {
                                          selectedBilling = 'one_time';
                                          creditsCtrl.text = '1';
                                          classesCtrl.clear();
                                        } else if (value == 'unlimited') {
                                          selectedBilling = 'monthly';
                                          classesCtrl.clear();
                                          creditsCtrl.clear();
                                        } else if (value == 'weekly_limit') {
                                          selectedBilling = 'monthly';
                                          creditsCtrl.clear();
                                          if (classesCtrl.text.trim().isEmpty) {
                                            classesCtrl.text = '3';
                                          }
                                        } else if (value == 'class_pack') {
                                          selectedBilling = 'one_time';
                                          classesCtrl.clear();
                                          if (creditsCtrl.text.trim().isEmpty) {
                                            creditsCtrl.text = '10';
                                          }
                                        }

                                        if (canReplaceName) {
                                          nameCtrl.text = suggestedPlanName(
                                            value,
                                          );
                                        }
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedBilling,
                                  decoration: dropdownDecoration(
                                    'Billing Period',
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: const Color(0xFF667085),
                                  style: _font(
                                    13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF111318),
                                  ),
                                  items:
                                      const [
                                        DropdownMenuItem(
                                          value: 'weekly',
                                          child: Text('Weekly'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'monthly',
                                          child: Text('Monthly'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'one_time',
                                          child: Text('One Time'),
                                        ),
                                      ].map((item) {
                                        return DropdownMenuItem<String>(
                                          value: item.value,
                                          child: Text(
                                            (item.child as Text).data ?? '',
                                            style: _font(
                                              13,
                                              weight: FontWeight.w500,
                                              color: const Color(0xFF111318),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setLocalState(() {
                                        selectedBilling = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          sectionTitle('Pricing & access'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFEAECEF),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    selectedType == 'drop_in'
                                        ? 'One-time single class.'
                                        : selectedType == 'unlimited'
                                        ? 'Recurring membership with unlimited access.'
                                        : selectedType == 'weekly_limit'
                                        ? 'Recurring membership with a weekly class limit.'
                                        : 'One-time pack with a fixed number of credits.',
                                    style: _font(
                                      12,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF667085),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                styledField(
                                  label: 'Price',
                                  controller: priceCtrl,
                                  hint: '129',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                ),
                                if (showsClassesPerPeriod) ...[
                                  const SizedBox(height: 12),
                                  styledField(
                                    label: 'Classes Per Period',
                                    controller: classesCtrl,
                                    hint: '3',
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ],
                                if (showsCreditsTotal) ...[
                                  const SizedBox(height: 12),
                                  styledField(
                                    label: 'Credits Total',
                                    controller: creditsCtrl,
                                    hint: selectedType == 'drop_in'
                                        ? '1'
                                        : '10',
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                styledField(
                                  label: 'Booking Window Days',
                                  controller: bookingWindowCtrl,
                                  hint: '7',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                styledField(
                                  label: 'Description',
                                  controller: descriptionCtrl,
                                  hint: selectedType == 'drop_in'
                                      ? 'Single visit for one class.'
                                      : selectedType == 'unlimited'
                                      ? 'Unlimited monthly access.'
                                      : selectedType == 'weekly_limit'
                                      ? 'Attend up to 2 or 3 classes per week.'
                                      : 'Pack of classes to use flexibly.',
                                  maxLines: 4,
                                  textInputAction: TextInputAction.done,
                                  focusNode: descriptionFocusNode,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: bottomInset > 0 ? 12 : 18),
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
                                  text: isEdit ? 'Save Changes' : 'Create Plan',
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
                                        () => _updatePlan(
                                          id: plan['id'].toString(),
                                          name: nameCtrl.text,
                                          type: selectedType,
                                          billing: selectedBilling,
                                          price: priceCtrl.text,
                                          classesPerPeriod: classesCtrl.text,
                                          creditsTotal: creditsCtrl.text,
                                          bookingWindowDays:
                                              bookingWindowCtrl.text,
                                          description: descriptionCtrl.text,
                                        ),
                                        successMessage: 'Plan updated',
                                      );
                                    } else {
                                      await _runAdminAction(
                                        () => _createPlan(
                                          name: nameCtrl.text,
                                          type: selectedType,
                                          billing: selectedBilling,
                                          price: priceCtrl.text,
                                          classesPerPeriod: classesCtrl.text,
                                          creditsTotal: creditsCtrl.text,
                                          bookingWindowDays:
                                              bookingWindowCtrl.text,
                                          description: descriptionCtrl.text,
                                        ),
                                        successMessage: 'Plan created',
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
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
