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
      text: '',
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

    final planNameRaw = plan?['name']?.toString().trim() ?? '';

    String selectedType;
    if (plan != null &&
        ((plan['plan_type']?.toString().isNotEmpty) ?? false) &&
        planNameRaw.toLowerCase().contains('trial')) {
      selectedType = 'trial_class';
    } else {
      selectedType = ((plan?['plan_type']?.toString().isNotEmpty) ?? false)
          ? plan!['plan_type'].toString()
          : 'unlimited';
    }

    String selectedBilling =
        (plan?['billing_period']?.toString().isNotEmpty ?? false)
        ? plan!['billing_period'].toString()
        : ((selectedType == 'drop_in' || selectedType == 'trial_class')
              ? 'one_time'
              : 'monthly');

    String suggestedPlanName(String type) {
      switch (type) {
        case 'trial_class':
          return 'Trial Class';
        case 'drop_in':
          return 'Drop-In';
        case 'unlimited':
          return 'Unlimited';
        case 'class_pack':
          final credits = creditsCtrl.text.trim();
          if (credits.isEmpty) return 'Class Pack';
          if (credits == '1') return '1-class pack';
          return '$credits-class pack';
        default:
          return '';
      }
    }

    bool shouldAutoReplacePlanName(String currentName) {
      final normalized = currentName.trim().toLowerCase();
      return normalized.isEmpty ||
          normalized == 'trial class' ||
          normalized == 'drop-in' ||
          normalized == 'unlimited' ||
          normalized == 'class pack' ||
          normalized == '1-class pack' ||
          normalized == '10-class pack' ||
          normalized.endsWith('-class pack');
    }

    String billingLabel(String billing) {
      switch (billing) {
        case 'weekly':
          return 'Weekly';
        case 'monthly':
          return 'Monthly';
        case 'one_time':
          return 'One Time';
        default:
          return billing;
      }
    }


    if (!isEdit && nameCtrl.text.trim().isEmpty) {
      nameCtrl.text = suggestedPlanName(selectedType);
    }

    if (!isEdit && selectedType == 'trial_class') {
      priceCtrl.text = '0';
      creditsCtrl.text = '1';
    } else if (!isEdit && selectedType == 'class_pack' && creditsCtrl.text.trim().isEmpty) {
      nameCtrl.text = suggestedPlanName(selectedType);
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
      bool readOnly = false,
      ValueChanged<String>? onChanged,
    }) {
      return InputField(
        label: label,
        controller: controller,
        hint: hint,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction: textInputAction,
        focusNode: focusNode,
        readOnly: readOnly,
        onChanged: onChanged,
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
                    final showsCreditsTotal =
                        selectedType == 'trial_class' ||
                        selectedType == 'drop_in' ||
                        selectedType == 'class_pack';

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
                                          value: 'trial_class',
                                          child: Text('Trial Class'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'drop_in',
                                          child: Text('Drop-In'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'unlimited',
                                          child: Text('Unlimited'),
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

                                        if (value == 'trial_class') {
                                          selectedBilling = 'one_time';
                                          priceCtrl.text = '0';
                                          creditsCtrl.text = '1';
                                          classesCtrl.clear();
                                        } else if (value == 'drop_in') {
                                          selectedBilling = 'one_time';
                                          if (priceCtrl.text.trim() == '0' &&
                                              nameCtrl.text.trim().toLowerCase() ==
                                                  'trial class') {
                                            priceCtrl.clear();
                                          }
                                          creditsCtrl.text = '1';
                                          classesCtrl.clear();
                                        } else if (value == 'unlimited') {
                                          selectedBilling = 'monthly';
                                          classesCtrl.clear();
                                          creditsCtrl.clear();
                                        } else if (value == 'class_pack') {
                                          selectedBilling = 'monthly';
                                          classesCtrl.clear();
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
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Billing Period',
                                        style: _font(
                                          12,
                                          weight: FontWeight.w500,
                                          color: const Color(0xFF667085),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        billingLabel(selectedBilling),
                                        style: _font(
                                          13,
                                          weight: FontWeight.w500,
                                          color: const Color(0xFF111318),
                                        ),
                                      ),
                                    ],
                                  ),
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
                                        ? 'Single class credit for one visit.'
                                        : selectedType == 'unlimited'
                                        ? 'Recurring membership with unlimited access.'
                                        : selectedType == 'trial_class'
                                        ? 'Free one-time trial class for new members.'
                                        : 'Monthly class pack with a fixed number of class credits.',
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
                                  hint: selectedType == 'trial_class' ? '0' : '129',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  readOnly: selectedType == 'trial_class',
                                ),
                                if (showsCreditsTotal) ...[
                                  const SizedBox(height: 12),
                                  styledField(
                                    label: 'Credits Total',
                                    controller: creditsCtrl,
                                    hint: (selectedType == 'drop_in' ||
                                            selectedType == 'trial_class')
                                        ? '1'
                                        : '8',
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (value) {
                                      if (selectedType != 'class_pack') return;
                                      if (!shouldAutoReplacePlanName(nameCtrl.text)) return;
                                      setLocalState(() {
                                        nameCtrl.text = suggestedPlanName('class_pack');
                                      });
                                    },
                                  ),
                                ],
                                const SizedBox(height: 12),
                                styledField(
                                  label: 'Description',
                                  controller: descriptionCtrl,
                                  hint: selectedType == 'trial_class'
                                      ? 'Free one-time trial class.'
                                      : selectedType == 'drop_in'
                                      ? 'Single visit for one class.'
                                      : selectedType == 'unlimited'
                                      ? 'Unlimited monthly access.'
                                      : 'One-time class pack with fixed credits.',
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
                                          type: selectedType == 'trial_class'
                                              ? 'drop_in'
                                              : selectedType,
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
                                          type: selectedType == 'trial_class'
                                              ? 'drop_in'
                                              : selectedType,
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

                                    if (!context.mounted) return;
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