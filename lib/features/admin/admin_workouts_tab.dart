part of 'admin_screen.dart';

extension _AdminWorkoutsTab on _AdminScreenState {
  Widget _workoutsTab() {
    return WorkoutsTab(workouts: _workouts);
  }
}
