part of 'admin_screen.dart';

extension _AdminMembersTab on _AdminScreenState {
  Widget _membersTab() {
    return MembersTab(members: _members);
  }
}
