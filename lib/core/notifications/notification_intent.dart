enum NotificationIntentType { workoutDetail }

class NotificationIntent {
  final NotificationIntentType type;
  final String workoutId;
  final int initialIndex;

  const NotificationIntent.workoutDetail(
    this.workoutId, {
    this.initialIndex = 0,
  }) : type = NotificationIntentType.workoutDetail;
}
