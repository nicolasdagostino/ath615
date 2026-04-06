enum UserRole { owner, admin, coach, athlete }

UserRole parseRole(String? role) {
  switch (role) {
    case 'owner':
      return UserRole.owner;
    case 'admin':
      return UserRole.admin;
    case 'coach':
      return UserRole.coach;
    default:
      return UserRole.athlete;
  }
}
