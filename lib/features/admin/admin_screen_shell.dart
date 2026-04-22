part of 'admin_screen.dart';

extension _AdminScreenShell on _AdminScreenState {
  Widget _currentAdminTab() {
    if (tabs[tabIndex] == 'Members') return _membersTab();
    if (tabs[tabIndex] == 'Classes') return _classesTab();
    if (tabs[tabIndex] == 'Workouts') return _workoutsTab();
    if (tabs[tabIndex] == 'Plans') return _plansTab();
    if (tabs[tabIndex] == 'Notifications') return const AdminNotificationsTab();
    if (tabs[tabIndex] == 'Programs') return _programsTab();
    return const SizedBox.shrink();
  }


  Widget _adminTabsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          return Padding(
            key: _tabChipKeys[i],
            padding: EdgeInsets.only(
              right: i == tabs.length - 1 ? 0 : 8,
            ),
            child: _adminTabChip(
              label: _adminTabLabel(tabs[i]),
              selected: i == tabIndex,
              onTap: () {
                setState(() => tabIndex = i);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _scrollToActiveTab();
                });
              },
            ),
          );
        }),
      ),
    );
  }


  Widget _adminErrorBanner() {
    if (_error == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _error!,
          style: const TextStyle(
            color: Color(0xFFB42318),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }


  Widget _adminBody() {
    return Expanded(
      child: IgnorePointer(
        ignoring: _adminActionBusy,
        child: RefreshIndicator(
          color: const Color(0xFFB59B6A),
          backgroundColor: Colors.white,
          onRefresh: _loadAdminData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              _adminTabsRow(),
              const SizedBox(height: 20),
              _adminErrorBanner(),
              _currentAdminTab(),
            ],
          ),
        ),
      ),
    );
  }
}
