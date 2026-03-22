enum UserRole { admin, coach, athlete }

UserRole parseRole(String? role) {
  switch (role) {
    case 'admin':
      return UserRole.admin;
    case 'coach':
      return UserRole.coach;
    default:
      return UserRole.athlete;
  }
}
