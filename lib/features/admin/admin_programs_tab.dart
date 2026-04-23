part of 'admin_screen.dart';

extension _AdminProgramsTab on _AdminScreenState {
  Widget _programsTab() {
    return ProgramsTab(programs: _programs);
  }
}
