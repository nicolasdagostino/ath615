part of 'admin_screen.dart';

extension _AdminPlansTab on _AdminScreenState {
  Widget _plansTab() {
    String prettyType(String raw) {
      if (raw.trim().isEmpty) return 'PLAN';
      return raw.replaceAll('_', ' ').toUpperCase();
    }

    String prettyBilling(String raw) {
      if (raw.trim().isEmpty) return '-';
      final value = raw.replaceAll('_', ' ').trim();
      return value[0].toUpperCase() + value.substring(1);
    }

    String priceLabel(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) return '- €';
      return '${value.toString()} €';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.adminPlansTab,
                style: _font(
                  18,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            GestureDetector(
              onTap: _adminActionBusy ? null : () => _showPlanModal(),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB59B6A),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.addUpper,
                  style: _font(
                    15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_plans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFF1F4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: Color(0xFFB59B6A),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.noPlansYet,
                  style: _font(
                    18,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.noPlansYetSubtitle,
                  textAlign: TextAlign.center,
                  style: _font(
                    13,
                    weight: FontWeight.w500,
                    color: const Color(0xFF8F96A3),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          )
        else
          ..._plans.map((plan) {
            final name = (plan['name'] ?? t.planFallbackLabel).toString();
            final description = (plan['description'] ?? '').toString().trim();
            final planType = (plan['plan_type'] ?? '').toString();
            final billing = (plan['billing_period'] ?? '').toString();
            final price = plan['price'];
            final bookingWindow = (plan['booking_window_days'] ?? '7')
                .toString();
            final classesPerPeriod = (plan['classes_per_period'] ?? '')
                .toString();
            final creditsTotal = (plan['credits_total'] ?? '').toString();

            final isTrialPlan =
                planType == 'drop_in' && name.toLowerCase().contains('trial');

            String accessLine = '';
            if (isTrialPlan) {
              accessLine = t.creditsLabelText(
                creditsTotal.isNotEmpty && creditsTotal != 'null'
                    ? creditsTotal
                    : '1',
              );
            } else if (planType == 'class_pack' &&
                creditsTotal.isNotEmpty &&
                creditsTotal != 'null') {
              accessLine = t.validOneMonthText(creditsTotal);
            } else if (planType == 'drop_in' &&
                creditsTotal.isNotEmpty &&
                creditsTotal != 'null') {
              accessLine = t.creditsLabelText(creditsTotal);
            } else if (classesPerPeriod.isNotEmpty &&
                classesPerPeriod != 'null') {
              accessLine = t.classesPerPeriodText(
                classesPerPeriod,
                t.bookingWindowDaysText(bookingWindow),
              );
            } else if (planType == 'unlimited') {
              accessLine = billing.isNotEmpty && billing != 'null'
                  ? prettyBilling(billing)
                  : '';
            } else if (creditsTotal.isNotEmpty && creditsTotal != 'null') {
              accessLine = t.creditsTotalText(
                creditsTotal,
                t.bookingWindowDaysText(bookingWindow),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F3EA),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              planType == 'drop_in'
                                  ? t.trialPlanTypeLabel(name)
                                  : prettyType(planType),
                              style: _font(
                                10,
                                weight: FontWeight.w700,
                                color: const Color(0xFFB59B6A),
                                letterSpacing: 0.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name.toUpperCase(),
                            style: _font(
                              20,
                              weight: FontWeight.w800,
                              color: const Color(0xFF111318),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _font(
                                13,
                                weight: FontWeight.w500,
                                color: const Color(0xFF8F96A3),
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color(0xFFEFF1F4),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${priceLabel(price)} · ${prettyBilling(billing)}',
                            style: _font(
                              13,
                              weight: FontWeight.w700,
                              color: const Color(0xFFB59B6A),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            accessLine,
                            style: _font(
                              13,
                              weight: FontWeight.w500,
                              color: const Color(0xFF667085),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _adminActionBusy
                          ? null
                          : () => _showPlanActions(plan),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEBE6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
