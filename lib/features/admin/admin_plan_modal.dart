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

    String selectedType = (plan?['plan_type']?.toString().isNotEmpty ?? false)
        ? plan!['plan_type'].toString()
        : 'unlimited';

    String selectedBilling =
        (plan?['billing_period']?.toString().isNotEmpty ?? false)
            ? plan!['billing_period'].toString()
            : 'monthly';

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    }) {
      return InputField(
        label: label,
        controller: controller,
        hint: hint,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction: textInputAction,
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
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    return SingleChildScrollView(
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
                          sectionTitle('Plan setup'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0xFFEAECEF)),
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
                                  items: const [
                                    DropdownMenuItem(value: 'unlimited', child: Text('Unlimited')),
                                    DropdownMenuItem(value: 'weekly_limit', child: Text('Weekly Limit')),
                                    DropdownMenuItem(value: 'class_pack', child: Text('Class Pack')),
                                    DropdownMenuItem(value: 'drop_in', child: Text('Drop-In')),
                                    DropdownMenuItem(value: 'open_gym', child: Text('Open Gym')),
                                    DropdownMenuItem(value: 'pt_pack', child: Text('PT Pack')),
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
                                        selectedType = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedBilling,
                                  decoration: dropdownDecoration('Billing Period'),
                                  borderRadius: BorderRadius.circular(16),
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: const Color(0xFF667085),
                                  style: _font(
                                    13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF111318),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                    DropdownMenuItem(value: 'one_time', child: Text('One Time')),
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
                              border: Border.all(color: const Color(0xFFEAECEF)),
                            ),
                            child: Column(
                              children: [
                                styledField(
                                  label: 'Price',
                                  controller: priceCtrl,
                                  hint: '129',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                styledField(
                                  label: 'Classes Per Period',
                                  controller: classesCtrl,
                                  hint: '3',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                styledField(
                                  label: 'Credits Total',
                                  controller: creditsCtrl,
                                  hint: '10',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                ),
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
                                  hint: 'Plan summary',
                                  maxLines: 4,
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
                                          bookingWindowDays: bookingWindowCtrl.text,
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
                                          bookingWindowDays: bookingWindowCtrl.text,
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
