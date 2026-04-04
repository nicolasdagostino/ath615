class AppStrings {
  final bool isSpanish;

  const AppStrings({required this.isSpanish});

  String get save => isSpanish ? 'Guardar' : 'Save';
  String get saving => isSpanish ? 'Guardando...' : 'Saving...';
  String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  String get delete => isSpanish ? 'Eliminar' : 'Delete';
  String get edit => isSpanish ? 'Editar' : 'Edit';
  String get update => isSpanish ? 'Actualizar' : 'Update';
  String get create => isSpanish ? 'Crear' : 'Create';

  String get memberNotFound =>
      isSpanish ? 'Miembro no encontrado' : 'Member not found';

  String get gymNotFound =>
      isSpanish ? 'Gimnasio no encontrado' : 'Gym not found';

  String get noPlansAvailableYet => isSpanish
      ? 'Todavía no hay planes disponibles'
      : 'No plans available yet';

  String get memberUpdated =>
      isSpanish ? 'Miembro actualizado' : 'Member updated';

  String get titleAndMessageRequired => isSpanish
      ? 'El título y el mensaje son obligatorios.'
      : 'Title and message are required.';

  String get adminGymNotFound => isSpanish
      ? 'No se encontró gimnasio para este admin.'
      : 'Gym not found for this admin.';

  String get notificationPublished =>
      isSpanish ? 'Notificación publicada.' : 'Notification published.';

  String get notificationCreatedAndPublished => isSpanish
      ? 'Notificación creada y publicada.'
      : 'Notification created & published.';

  String get notificationSaved =>
      isSpanish ? 'Notificación guardada.' : 'Notification saved.';

  String get notificationCreatedAsDraft => isSpanish
      ? 'Notificación creada como borrador.'
      : 'Notification created as draft.';

  String get publishNow => isSpanish ? 'Publicar ahora' : 'Publish now';
  String get saveChanges => isSpanish ? 'Guardar cambios' : 'Save Changes';

  String get createMember => isSpanish ? 'Crear miembro' : 'Create Member';

  String get program => isSpanish ? 'Programa' : 'Program';
  String get classLabel => isSpanish ? 'Clase' : 'Class';
  String get workout => isSpanish ? 'Entrenamiento' : 'Workout';

  String get createProgramTitle =>
      isSpanish ? 'Crear programa' : 'Create Program';

  String get editProgram => isSpanish ? 'Editar programa' : 'Edit Program';

  String get updateProgramDetails => isSpanish
      ? 'Actualiza los detalles del programa.'
      : 'Update the program details.';

  String get addProgramForGym => isSpanish
      ? 'Añade un nuevo programa de entrenamiento para tu gimnasio.'
      : 'Add a new training program for your gym.';

  String get programName => isSpanish ? 'Nombre del programa' : 'Program Name';

  String get shortDescription =>
      isSpanish ? 'Descripción corta' : 'Short Description';

  String get programUpdated =>
      isSpanish ? 'Programa actualizado' : 'Program updated';

  String get programCreated =>
      isSpanish ? 'Programa creado' : 'Program created';

  String get selectDate => isSpanish ? 'Seleccionar fecha' : 'Select Date';

  String get dateLabel => isSpanish ? 'Fecha' : 'Date';
  String get timeLabel => isSpanish ? 'Hora' : 'Time';

  String get chooseDate => isSpanish ? 'Elige una fecha.' : 'Choose a date.';

  String get chooseTime => isSpanish
      ? 'Elige la hora de inicio de la clase.'
      : 'Choose the class start time.';

  String get workoutDate =>
      isSpanish ? 'Fecha del entrenamiento' : 'Workout Date';

  String get chooseWorkoutDate => isSpanish
      ? 'Elige la fecha del entrenamiento.'
      : 'Choose the workout date.';

  String get titleAndMessageRequiredShort => isSpanish
      ? 'Completa el título y el mensaje.'
      : 'Enter a title and message.';

  String get adminGymMissing => isSpanish
      ? 'No se encontró el gimnasio del administrador.'
      : 'Admin gym not found.';

  String get publishedNow =>
      isSpanish ? 'Notificación publicada.' : 'Notification published.';

  String get savedDraft => isSpanish ? 'Borrador guardado.' : 'Draft saved.';

  String get createdAndPublished => isSpanish
      ? 'Notificación creada y publicada.'
      : 'Notification created and published.';

  String get createdDraft => isSpanish ? 'Borrador creado.' : 'Draft created.';

  String get publish => isSpanish ? 'Publicar' : 'Publish';

  String get notificationTitle => isSpanish ? 'Título' : 'Title';

  String get messageLabel => isSpanish ? 'Mensaje' : 'Message';

  String get draft => isSpanish ? 'Borrador' : 'Draft';

  String get bookClass => isSpanish ? 'Reservar clase' : 'Book class';

  String get cancelBooking => isSpanish ? 'Cancelar reserva' : 'Cancel booking';

  String get bookingClosed => isSpanish ? 'Reserva cerrada' : 'Booking closed';

  String get classFull => isSpanish ? 'Clase completa' : 'Class full';

  String get checkedIn => isSpanish ? 'Registrado' : 'Checked in';

  String get imHere => isSpanish ? 'Ya llegué' : 'I’m here';

  String get membershipActive =>
      isSpanish ? 'Membresía activa' : 'Membership active';

  String get markAttended => isSpanish ? 'Marcar asistencia' : 'Mark attended';

  String get setBooked => isSpanish ? 'Marcar reservado' : 'Set booked';

  String get attendanceHistory =>
      isSpanish ? 'Historial de clases' : 'Class history';

  String get pastBookingsAndAttendance => isSpanish
      ? 'Reservas y asistencias pasadas'
      : 'Past bookings and attendance';

  String get attended => isSpanish ? 'Asistió' : 'Attended';

  String get cancelled => isSpanish ? 'Cancelado' : 'Cancelled';

  String get noShow => isSpanish ? 'No asistió' : 'No-show';

  String get missed => isSpanish ? 'Perdida' : 'Missed';

  String get classBooked => isSpanish ? '¡Dentro! 🔥' : "You're in 🔥";

  String get bookingCancelled =>
      isSpanish ? 'Reserva cancelada' : 'Booking cancelled';

  String get checkedInSuccess =>
      isSpanish ? 'Check-in realizado' : 'Checked in successfully';

  String get bookingNotFound =>
      isSpanish ? 'Reserva no encontrada' : 'Booking not found';

  String get bookingIdNotFound =>
      isSpanish ? 'Id de reserva no encontrado' : 'Booking id not found';

  String get classFinished => isSpanish ? 'Clase finalizada' : 'Class finished';

  String get membershipRequired =>
      isSpanish ? 'Membresía requerida' : 'Membership required';

  String get bookingWasCancelled =>
      isSpanish ? 'Esta reserva fue cancelada.' : 'This booking was cancelled.';

  String get noActivePlan => isSpanish ? 'Sin plan activo' : 'No active plan';

  String get noActiveMembership =>
      isSpanish ? 'Sin membresía activa' : 'No active membership';

  String get roster => isSpanish ? 'Lista' : 'Roster';

  String get coach => isSpanish ? 'Coach' : 'Coach';

  String get spots => isSpanish ? 'Plazas' : 'Spots';

  String get bookedUpper => isSpanish ? 'DENTRO' : "YOU'RE IN";

  String get checkedInUpper => isSpanish ? 'REGISTRADO' : 'CHECKED IN';

  String get finished => isSpanish ? 'Finalizada' : 'Finished';

  String get inProgress => isSpanish ? 'En curso' : 'In progress';

  String get tomorrow => isSpanish ? 'Mañana' : 'Tomorrow';

  String inDays(int days) => isSpanish ? 'En $days días' : 'In $days days';

  String startsInMinutes(int minutes) =>
      isSpanish ? 'Empieza en $minutes min' : 'Starts in $minutes min';

  String startsInHoursMinutes(int hours, int minutes) => isSpanish
      ? 'Empieza en ${hours}h ${minutes}m'
      : 'Starts in ${hours}h ${minutes}m';

  String get language => isSpanish ? 'Idioma' : 'Language';

  String get chooseLanguage => isSpanish ? 'Elegir idioma' : 'Choose language';

  String get appLanguage => isSpanish ? 'Idioma de la app' : 'App language';

  String get english => isSpanish ? 'Inglés' : 'English';

  String get spanish => isSpanish ? 'Español' : 'Spanish';

  String get athlete => isSpanish ? 'Atleta' : 'Athlete';

  String get profile => isSpanish ? 'Perfil' : 'Profile';

  String get account => isSpanish ? 'Cuenta' : 'Account';

  String get records => isSpanish ? 'Marcas' : 'Records';

  String get classHistory =>
      isSpanish ? 'Historial de clases' : 'Class history';

  String get yourStats => isSpanish ? 'Tus estadísticas' : 'Your stats';

  String get classes => isSpanish ? 'Clases' : 'Classes';

  String get strength => isSpanish ? 'Fuerza' : 'Strength';

  String get milestones => isSpanish ? 'Logros' : 'Milestones';

  String get more => isSpanish ? 'Más' : 'More';

  String get helpCenter => isSpanish ? 'Centro de ayuda' : 'Help Center';

  String get privacyPolicy =>
      isSpanish ? 'Política de privacidad' : 'Privacy Policy';

  String get termsOfService =>
      isSpanish ? 'Términos del servicio' : 'Terms of Service';

  String get logOut => isSpanish ? 'Cerrar sesión' : 'Log Out';

  String get couldNotUploadAvatar => isSpanish
      ? 'No se pudo subir la foto de perfil'
      : 'Could not upload avatar';

  String get profilePhotoUpdated =>
      isSpanish ? 'Foto de perfil actualizada' : 'Profile photo updated';

  String get noAuthenticatedUser =>
      isSpanish ? 'Usuario no autenticado' : 'No authenticated user';

  String get updateAccountInformation => isSpanish
      ? 'Actualiza la información de tu cuenta.'
      : 'Update your account information.';

  String get details => isSpanish ? 'Detalles' : 'Details';

  String enterField(String field) =>
      isSpanish ? 'Introduce $field' : 'Enter $field';
  String fieldUpdated(String field) =>
      isSpanish ? '$field actualizado' : '$field updated';

  String get dateOfBirth => isSpanish ? 'Fecha de nacimiento' : 'Date of Birth';

  String get chooseBirthDate =>
      isSpanish ? 'Elige tu fecha de nacimiento.' : 'Choose your birth date.';
  String get dateOfBirthUpdated =>
      isSpanish ? 'Fecha de nacimiento actualizada' : 'Date of birth updated';

  String get changePassword =>
      isSpanish ? 'Cambiar contraseña' : 'Change Password';

  String get setNewPasswordSubtitle => isSpanish
      ? 'Define una nueva contraseña para tu cuenta.'
      : 'Set a new password for your account.';

  String get security => isSpanish ? 'Seguridad' : 'Security';

  String get newPassword => isSpanish ? 'Nueva contraseña' : 'New password';

  String get confirmNewPassword =>
      isSpanish ? 'Confirmar nueva contraseña' : 'Confirm new password';

  String get updatePassword =>
      isSpanish ? 'Actualizar contraseña' : 'Update Password';

  String get completeBothPasswordFields => isSpanish
      ? 'Completa ambos campos de contraseña'
      : 'Please complete both password fields';

  String get passwordMinLength => isSpanish
      ? 'La contraseña debe tener al menos 6 caracteres'
      : 'Password must be at least 6 characters';

  String get passwordsDoNotMatch =>
      isSpanish ? 'Las contraseñas no coinciden' : 'Passwords do not match';

  String get passwordUpdated =>
      isSpanish ? 'Contraseña actualizada' : 'Password updated';

  String get profileUpper => isSpanish ? 'PERFIL' : 'PROFILE';

  String get accountUpper => isSpanish ? 'CUENTA' : 'ACCOUNT';

  String get memberSince => isSpanish ? 'Miembro desde' : 'Member since';

  String get phone => isSpanish ? 'Teléfono' : 'Phone';

  String get gym => isSpanish ? 'Gimnasio' : 'Gym';

  String get birthday => isSpanish ? 'Cumpleaños' : 'Birthday';

  String get uploadingUpper => isSpanish ? 'SUBIENDO...' : 'UPLOADING...';

  String get uploadNewPhotoUpper =>
      isSpanish ? 'SUBIR NUEVA FOTO' : 'UPLOAD NEW PHOTO';

  String get personalUpper => isSpanish ? 'PERSONAL' : 'PERSONAL';

  String get securityUpper => isSpanish ? 'SEGURIDAD' : 'SECURITY';

  String get appUpper => isSpanish ? 'APP' : 'APP';

  String get settings => isSpanish ? 'Ajustes' : 'Settings';

  String get dangerZoneUpper => isSpanish ? 'ZONA DE PELIGRO' : 'DANGER ZONE';

  String get deleteAccount => isSpanish ? 'Eliminar cuenta' : 'Delete Account';

  String get record => isSpanish ? 'Marca' : 'Record';

  String get addRecord => isSpanish ? 'Añadir marca' : 'Add Record';

  String get editRecord => isSpanish ? 'Editar marca' : 'Edit Record';

  String get deleteRecord => isSpanish ? 'Eliminar marca' : 'Delete Record';

  String get recordDeleted => isSpanish ? 'Marca eliminada' : 'Record deleted';

  String get recordActions =>
      isSpanish ? 'Acciones de la marca' : 'Record actions';

  String get chooseRecordDate =>
      isSpanish ? 'Elige la fecha de la marca.' : 'Choose the record date.';

  String get updateMovementScoreDate => isSpanish
      ? 'Actualiza movimiento, resultado y fecha'
      : 'Update movement, score and date';

  String get recordsUpper => isSpanish ? 'MARCAS' : 'RECORDS';

  String get category => isSpanish ? 'Categoría' : 'Category';

  String get movement => isSpanish ? 'Movimiento' : 'Movement';

  String get benchmark => isSpanish ? 'Benchmark' : 'Benchmark';

  String get openWorkout => isSpanish ? 'Open' : 'Open Workout';

  String get weightKg => isSpanish ? 'Peso (kg)' : 'Weight (kg)';

  String get score => isSpanish ? 'Resultado' : 'Score';

  String get notes => isSpanish ? 'Notas' : 'Notes';

  String get optionalNotes => isSpanish ? 'Notas opcionales' : 'Optional notes';
  String get createRecord => isSpanish ? 'Crear marca' : 'Create Record';

  String get updateRecord => isSpanish ? 'Actualizar marca' : 'Update Record';

  String get movementRequired =>
      isSpanish ? 'El movimiento es obligatorio' : 'Movement is required';

  String get dateRequired =>
      isSpanish ? 'La fecha es obligatoria' : 'Date is required';

  String get validWeightRequired => isSpanish
      ? 'Introduce un peso válido en kg'
      : 'Enter a valid weight in kg';

  String get scoreRequired =>
      isSpanish ? 'El resultado es obligatorio' : 'Score is required';

  String get recordUpdated =>
      isSpanish ? 'Marca actualizada' : 'Record updated';

  String get recordCreated => isSpanish ? 'Marca creada' : 'Record created';

  String get achievement => isSpanish ? 'Logro' : 'Achievement';

  String get removeRecordFromProfile => isSpanish
      ? 'Elimina esta marca de tu perfil'
      : 'Remove this record from your profile';

  String get changePhoto => isSpanish ? 'Cambiar foto' : 'Change Photo';

  String get justNow => isSpanish ? 'Justo ahora' : 'Just now';

  String minutesAgo(int minutes) =>
      isSpanish ? 'Hace $minutes min' : '$minutes min ago';

  String hoursAgo(int hours) => isSpanish ? 'Hace $hours h' : '$hours h ago';

  String get oneDayAgo => isSpanish ? 'Hace 1 día' : '1 day ago';

  String daysAgo(int days) => isSpanish ? 'Hace $days días' : '$days days ago';

  String get notification => isSpanish ? 'Notificación' : 'Notification';

  String get noDetailsAvailable =>
      isSpanish ? 'No hay detalles disponibles.' : 'No details available.';

  String unreadNotifications(int count) => isSpanish
      ? '$count notificaciones sin leer'
      : '$count unread notifications';

  String get allCaughtUp => isSpanish ? 'Todo al día' : 'All caught up';

  String get noNotificationsYet =>
      isSpanish ? 'Todavía no hay notificaciones' : 'No notifications yet';

  String get notificationsEmptySubtitle => isSpanish
      ? 'Aquí aparecerán las novedades del gimnasio, logros, recordatorios y anuncios.'
      : 'Your gym updates, milestones, reminders and announcements will appear here.';

  String get couldNotLoadNotifications => isSpanish
      ? 'No se pudieron cargar las notificaciones'
      : 'Could not load notifications';

  String get unknownError => isSpanish ? 'Error desconocido' : 'Unknown error';

  String get retry => isSpanish ? 'Reintentar' : 'Retry';

  String get notificationsUpper =>
      isSpanish ? 'NOTIFICACIONES' : 'NOTIFICATIONS';

  String get couldNotLoadWorkouts => isSpanish
      ? 'No se pudieron cargar los entrenamientos'
      : 'Could not load workouts';

  String minutesAgoShort(int minutes) =>
      isSpanish ? 'Hace ${minutes}m' : '${minutes}m ago';

  String hoursAgoShort(int hours) =>
      isSpanish ? 'Hace ${hours}h' : '${hours}h ago';

  String daysAgoShort(int days) => isSpanish ? 'Hace ${days}d' : '${days}d ago';

  String get writeAComment =>
      isSpanish ? 'Escribe un comentario...' : 'Write a comment...';

  String get post => isSpanish ? 'Publicar' : 'Post';

  String get todaysWorkoutsUpper =>
      isSpanish ? 'ENTRENAMIENTOS DE HOY' : "TODAY'S WORKOUTS";

  String get like => isSpanish ? 'Me gusta' : 'Like';

  String get workoutNotFound =>
      isSpanish ? 'Entrenamiento no encontrado' : 'Workout not found';

  String get workoutDetails =>
      isSpanish ? 'Detalles del entrenamiento' : 'Workout details';

  String likesCount(String count) =>
      isSpanish ? '$count me gusta' : '$count likes';

  String commentsCount(String count) =>
      isSpanish ? '$count comentarios' : '$count comments';

  String get commentLabel => isSpanish ? 'Comentar' : 'Comment';

  String get noCommentsYet =>
      isSpanish ? 'Todavía no hay comentarios' : 'No comments yet';

  String get athleteFallback => isSpanish ? 'Atleta' : 'Athlete';

  String get athlete615 => 'Athlete 615';

  String get restDayUpper => isSpanish ? 'DÍA DE DESCANSO' : 'REST DAY';

  String get restDayDescription => isSpanish
      ? 'Descansar es tan importante como entrenar. Deja que tu mente y tu cuerpo se recuperen, haz algo de movilidad y estira. No te tientes a entrenar aunque te sientas bien.'
      : "Resting is as important as work. Let your mind and body rest, do some mobility and stretching. Don't be tempted to train if you feel good.";

  String get noWorkoutsForToday => isSpanish
      ? 'No hay entrenamientos para este día'
      : 'No workouts for this day';

  String get workoutDetailUpper =>
      isSpanish ? 'DETALLE DEL ENTRENAMIENTO' : 'WORKOUT DETAIL';

  String get navWorkouts => isSpanish ? 'Entrenos' : 'Workouts';
  String get navBooking => isSpanish ? 'Reservas' : 'Booking';
  String get navExplore => isSpanish ? 'Explorar' : 'Explore';
  String get navDashboard => isSpanish ? 'Dashboard' : 'Dashboard';
  String get navAdmin => isSpanish ? 'Admin' : 'Admin';
  String get navProfile => isSpanish ? 'Perfil' : 'Profile';

  String get authTagline => isSpanish
      ? 'Levanta. Sentadilla. Tracciona. Empuja.'
      : 'Lift. Squat. Pull. Push.';
  String get athleteLoginTitle => isSpanish ? 'ACCESO ATLETA' : 'ATHLETE LOGIN';
  String get forgotPasswordTitle =>
      isSpanish ? '¿OLVIDASTE TU CONTRASEÑA?' : 'FORGOT YOUR PASSWORD?';
  String get forgotPasswordSubtitle => isSpanish
      ? 'Introduce tu email para recuperar el acceso.'
      : 'Enter your email to restore access.';
  String get forgotPassword =>
      isSpanish ? '¿OLVIDASTE TU CONTRASEÑA?' : 'FORGOT PASSWORD?';
  String get restorePassword =>
      isSpanish ? 'RECUPERAR CONTRASEÑA' : 'RESTORE PASSWORD';
  String get back => isSpanish ? 'VOLVER' : 'BACK';

  String get createAccountTitle =>
      isSpanish ? 'CREAR CUENTA' : 'CREATE ACCOUNT';
  String get createAccountSubtitle => isSpanish
      ? 'Únete a Athlete Lab y empieza tu camino de entrenamiento.'
      : 'Join Athlete Lab and start your training journey.';
  String get fullName => isSpanish ? 'Nombre completo' : 'Full Name';

  String get email => isSpanish ? 'Email' : 'Email';

  String get emailLabel => isSpanish ? 'EMAIL' : 'EMAIL';
  String get enterFullName =>
      isSpanish ? 'Introduce nombre completo' : 'Enter full name';
  String get enterEmail => isSpanish ? 'Introduce email' : 'Enter email';
  String get passwordLabel => isSpanish ? 'Contraseña' : 'Password';
  String get enterPassword =>
      isSpanish ? 'Introduce contraseña' : 'Enter password';
  String get createPasswordHint =>
      isSpanish ? 'Crea una contraseña' : 'Create password';
  String get creatingAccount =>
      isSpanish ? 'CREANDO CUENTA...' : 'CREATING ACCOUNT...';
  String get alreadyHaveAccount =>
      isSpanish ? '¿YA TIENES UNA CUENTA?' : 'ALREADY HAVE AN ACCOUNT?';
  String get signIn => isSpanish ? 'INICIAR SESIÓN' : 'SIGN IN';

  String get setNewPasswordTitle =>
      isSpanish ? 'CREAR NUEVA CONTRASEÑA' : 'SET NEW PASSWORD';
  String get newPasswordLabel =>
      isSpanish ? 'Nueva contraseña' : 'New password';
  String get enterNewPassword =>
      isSpanish ? 'Introduce nueva contraseña' : 'Enter new password';
  String get confirmPasswordLabel =>
      isSpanish ? 'Confirmar contraseña' : 'Confirm password';
  String get repeatNewPassword =>
      isSpanish ? 'Repite la nueva contraseña' : 'Repeat new password';
  String get useAtLeast6Chars =>
      isSpanish ? 'Usa al menos 6 caracteres.' : 'Use at least 6 characters.';
  String get updatePasswordCta =>
      isSpanish ? 'ACTUALIZAR CONTRASEÑA' : 'UPDATE PASSWORD';

  String get noAccountTitle =>
      isSpanish ? '¿NO TIENES UNA CUENTA?' : "DON'T HAVE AN ACCOUNT?";
  String get noAccountSubtitle1 => isSpanish
      ? 'El acceso a ATH615 está pensado para atletas registrados en uno de nuestros programas de entrenamiento.'
      : 'ATH615 access is designed for athletes registered in one of our training programs.';
  String get noAccountSubtitle2 => isSpanish
      ? 'Puedes solicitar acceso o crear tu cuenta para empezar a reservar clases, seguir entrenamientos y usar toda la experiencia Athlete Lab.'
      : 'You can request access or create your account to start booking classes, following workouts and using the full Athlete Lab experience.';

  String get splashTagline => isSpanish
      ? 'Entrena duro. Sé constante.'
      : 'Train hard. Stay consistent.';

  String get exploreWorkoutsUpper =>
      isSpanish ? 'EXPLORAR ENTRENAMIENTOS' : 'EXPLORE WORKOUTS';

  String get popularWorkoutsUpper =>
      isSpanish ? 'ENTRENAMIENTOS POPULARES' : 'POPULAR WORKOUTS';

  String get browseMostLikedWorkouts => isSpanish
      ? 'Explora los entrenamientos con más me gusta'
      : 'Browse the most liked workouts';

  String get searchRecentAndBenchmarkWorkouts => isSpanish
      ? 'Busca entrenamientos recientes y benchmark'
      : 'Search recent and benchmark workouts';

  String get recentUpper => isSpanish ? 'RECIENTES' : 'RECENT';

  String get popularUpper => isSpanish ? 'POPULARES' : 'POPULAR';

  String get searchWorkouts =>
      isSpanish ? 'Buscar entrenamientos' : 'Search workouts';

  String get popularWorkouts =>
      isSpanish ? 'Entrenamientos populares' : 'Popular workouts';

  String get recentWorkouts =>
      isSpanish ? 'Entrenamientos recientes' : 'Recent workouts';

  String resultsCount(int count) =>
      isSpanish ? '$count resultados' : '$count results';

  String resultsWithBenchmarks(int count, int benchmarkCount) => isSpanish
      ? '$count resultados · $benchmarkCount benchmark'
      : '$count results · $benchmarkCount benchmarks';

  String get benchmarkUpper => isSpanish ? 'BENCHMARK' : 'BENCHMARK';

  String get noWorkoutsFound =>
      isSpanish ? 'No se encontraron entrenamientos' : 'No workouts found';

  String get defaultWorkoutTitle => isSpanish ? 'Entrenamiento' : 'Workout';

  String get classesTomorrow =>
      isSpanish ? 'Clases mañana' : 'Classes tomorrow';

  String get scheduledForTomorrow =>
      isSpanish ? 'Programadas para mañana' : 'Scheduled for tomorrow';

  String get lowOccupancy => isSpanish ? 'Baja ocupación' : 'Low occupancy';

  String get needPromotionOrReview =>
      isSpanish ? 'Necesitan promoción o revisión' : 'Need promotion or review';

  String get tomorrowLooksHealthy => isSpanish
      ? 'Mañana se ve bien por ahora.'
      : 'Tomorrow looks healthy right now.';

  String get nextClassUpper => isSpanish ? 'PRÓXIMA CLASE' : 'NEXT CLASS';

  String get workoutAssigned =>
      isSpanish ? 'Entrenamiento asignado' : 'Workout assigned';

  String get workoutMissing =>
      isSpanish ? 'Entrenamiento pendiente' : 'Workout missing';

  String get todayHighlightsTitle =>
      isSpanish ? 'Puntos clave de hoy' : 'Today Highlights';

  String get todayHighlightsSubtitle => isSpanish
      ? 'Cosas útiles para revisar a primera hora.'
      : 'Useful things to check first thing in the morning.';

  String get nothingUrgentToday =>
      isSpanish ? 'Nada urgente para hoy.' : 'Nothing urgent for today.';

  String get morningOverviewTitle =>
      isSpanish ? 'Resumen de la mañana' : 'Morning Overview';

  String get morningOverviewSubtitle => isSpanish
      ? 'Lo primero que revisa un dueño.'
      : 'The first things an owner checks.';

  String get todayUpper => isSpanish ? 'HOY' : 'TODAY';

  String get milestonesTitle => isSpanish ? 'Hitos' : 'Milestones';

  String get milestonesSubtitle => isSpanish
      ? 'Logros de asistencia para celebrar.'
      : 'Attendance wins worth celebrating.';

  String get noNearbyMilestones => isSpanish
      ? 'Todavía no hay hitos cercanos.'
      : 'No nearby milestones yet.';

  String get noUrgentAlerts => isSpanish
      ? 'No hay alertas urgentes ahora mismo.'
      : 'No urgent alerts right now.';

  String get noActiveMemberData => isSpanish
      ? 'Todavía no hay datos activos de miembros.'
      : 'No active member data yet.';

  String get noPendingAttendance =>
      isSpanish ? 'No hay asistencias pendientes' : 'No pending attendance';

  String get allPastClassesReviewed => isSpanish
      ? 'Todas las clases pasadas parecen revisadas por ahora.'
      : 'All past classes look reviewed right now.';

  String get pendingAttendanceUpper =>
      isSpanish ? 'ASISTENCIA PENDIENTE' : 'PENDING ATTENDANCE';

  String pendingClassesToReview(int count) => isSpanish
      ? (count == 1 ? '1 clase para revisar' : '$count clases para revisar')
      : (count == 1 ? '1 class to review' : '$count classes to review');

  String pendingCount(int count) =>
      isSpanish ? '$count pendientes' : '$count pending';

  String durationMinutesLabel(int count) =>
      isSpanish ? '$count min' : '$count min';

  String get coachTbd => isSpanish ? 'Coach: por definir' : 'Coach: TBD';

  String coachLabel(String name) => isSpanish ? 'Coach: $name' : 'Coach: $name';

  String bookedCountLabel(int count) =>
      isSpanish ? 'Reservados: $count' : 'Booked: $count';

  String attendedCountLabel(int count) =>
      isSpanish ? 'Asistieron: $count' : 'Attended: $count';

  String get tomorrowRiskTitle =>
      isSpanish ? 'Riesgo de mañana' : 'Tomorrow risk';

  String get tomorrowRiskSheetSubtitle => isSpanish
      ? 'Clases que pueden necesitar promoción, revisión o ajustes de horario antes de mañana.'
      : 'Classes that may need promotion, review or schedule adjustments before tomorrow.';

  String get openClasses => isSpanish ? 'Abrir clases' : 'Open Classes';

  String get inactiveMembersTitle =>
      isSpanish ? 'Miembros inactivos' : 'Inactive members';

  String get inactiveMembersSubtitle => isSpanish
      ? 'Miembros que pueden necesitar un mensaje de seguimiento o un check-in personal.'
      : 'Members who may need a follow-up message or personal check-in.';

  String get noInactiveMembers => isSpanish
      ? 'No hay miembros inactivos ahora mismo.'
      : 'No inactive members right now.';

  String get openMembers => isSpanish ? 'Abrir miembros' : 'Open Members';

  String get membersNavigationUnavailable => isSpanish
      ? 'La navegación de miembros no está disponible.'
      : 'Members navigation is not available.';

  String get membersUpper => isSpanish ? 'MIEMBROS' : 'MEMBERS';

  String get recommendedActionsTitle =>
      isSpanish ? 'Acciones recomendadas' : 'Recommended actions';

  String get recommendedActionsSubtitle => isSpanish
      ? 'Próximos pasos rápidos para el dueño o admin.'
      : 'Fast next steps for the owner or admin.';

  String get classesNavigationUnavailable => isSpanish
      ? 'La navegación de clases no está disponible.'
      : 'Classes navigation is not available.';

  String get reviewHighlightsAndCongratulate => isSpanish
      ? 'Revisa los puntos clave de hoy y felicítalos.'
      : 'Review today highlights and congratulate them.';

  String get adminNavigationUnavailable => isSpanish
      ? 'La navegación de admin no está disponible ahora mismo.'
      : 'Admin navigation is not available right now.';

  String get alertsTitle => isSpanish ? 'Alertas' : 'Alerts';

  String get alertsSubtitle => isSpanish
      ? 'Cosas útiles para revisar pronto.'
      : 'Useful things to review soon.';

  String get tomorrowRiskSubtitle => isSpanish
      ? 'Clases que pueden necesitar atención antes de mañana.'
      : 'Classes that may need attention before tomorrow.';

  String get classDetailUnavailable => isSpanish
      ? 'El detalle de la clase no está disponible.'
      : 'Class detail is not available.';

  String get membersActivityTitle =>
      isSpanish ? 'Actividad de miembros' : 'Members activity';

  String get membersActivitySubtitle => isSpanish
      ? 'Vista rápida estilo CRM de tu comunidad.'
      : 'Quick CRM-style view of your community.';

  String get memberDetailUnavailable => isSpanish
      ? 'El detalle del miembro no está disponible.'
      : 'Member detail is not available.';

  String get dashboardTitle => isSpanish ? 'Dashboard' : 'Dashboard';

  String get dashboardSubtitle => isSpanish
      ? 'Información clave para tu gimnasio.'
      : 'Business insights for your gym.';

  String couldNotLoadDashboardData(String error) => isSpanish
      ? 'No se pudieron cargar los datos del dashboard. Desliza para refrescar.\n\n$error'
      : 'Could not load dashboard data. Pull to refresh.\n\n$error';

  String get noDashboardDataAvailable => isSpanish
      ? 'No hay datos del dashboard disponibles.'
      : 'No dashboard data available.';

  String get workoutNotAssigned =>
      isSpanish ? 'Entrenamiento no asignado' : 'Workout not assigned';

  String bookedRatio(int reserved, int maxSpots) => isSpanish
      ? '$reserved / $maxSpots reservados'
      : '$reserved / $maxSpots booked';

  String bookedCountOnly(int reserved) =>
      isSpanish ? '$reserved reservados' : '$reserved booked';

  String todayTimeLabel(String hh, String mm) =>
      isSpanish ? 'Hoy · $hh:$mm' : 'Today · $hh:$mm';

  String tomorrowTimeLabel(String hh, String mm) =>
      isSpanish ? 'Mañana · $hh:$mm' : 'Tomorrow · $hh:$mm';

  String get noClassesScheduledToday => isSpanish
      ? 'No hay clases programadas hoy.'
      : 'No classes scheduled today.';

  String get todayProgrammingAssigned => isSpanish
      ? 'La programación de hoy está asignada.'
      : 'Today programming is assigned.';

  String classesNeedWorkout(int count) => isSpanish
      ? '$count clases todavía necesitan un entrenamiento.'
      : '$count classes still need a workout.';

  String get birthdayToday => isSpanish ? 'Cumpleaños hoy' : 'Birthday today';

  String get workoutReady =>
      isSpanish ? 'Entrenamiento listo' : 'Workout ready';

  String reachedClasses(int count) =>
      isSpanish ? 'Alcanzó $count clases' : 'Reached $count classes';

  String classesLeftForTarget(int remaining, int target) => isSpanish
      ? '$remaining clases para llegar a $target'
      : '$remaining classes left for $target';

  String get reviewTomorrowRiskTitle =>
      isSpanish ? 'Revisar riesgo de mañana' : 'Review tomorrow risk';

  String classesNeedPromotionOrReview(int count) => isSpanish
      ? '$count clases pueden necesitar promoción o revisión.'
      : '$count classes may need promotion or review.';

  String pastClassesHaveUnreviewedBookings(
    int classesCount,
    int bookingsCount,
  ) => isSpanish
      ? '$classesCount clases pasadas todavía tienen $bookingsCount reservas sin revisar.'
      : '$classesCount past classes still have $bookingsCount unreviewed bookings.';

  String pastClassesNeedAttendanceReview(int classesCount) => isSpanish
      ? '$classesCount clases pasadas todavía necesitan revisión de asistencia.'
      : '$classesCount past classes still need attendance review.';

  String get reviewPendingAttendanceTitle =>
      isSpanish ? 'Revisar asistencia pendiente' : 'Review pending attendance';

  String get checkInactiveMembersTitle =>
      isSpanish ? 'Revisar miembros inactivos' : 'Check inactive members';

  String membersMayNeedFollowUp(int count) => isSpanish
      ? '$count miembros pueden necesitar un mensaje de seguimiento.'
      : '$count members may need a follow-up message.';

  String get assignWorkoutToNextClassTitle => isSpanish
      ? 'Asignar entrenamiento a la próxima clase'
      : 'Assign workout to next class';

  String nextClassHasNoWorkoutAssigned(String title) => isSpanish
      ? '$title todavía no tiene entrenamiento asignado.'
      : '$title still has no workout assigned.';

  String get finishTodayProgrammingTitle =>
      isSpanish ? 'Completar programación de hoy' : 'Finish today programming';

  String get wishHappyBirthdayTitle =>
      isSpanish ? 'Felicitar cumpleaños' : 'Wish happy birthday';

  String membersCelebratingToday(int count) => isSpanish
      ? '$count miembros están celebrando hoy.'
      : '$count members are celebrating today.';

  String get reviewTodayBookingsTitle =>
      isSpanish ? 'Revisar reservas de hoy' : 'Review today bookings';

  String bookingsCurrentlyOnTodaySchedule(int count) => isSpanish
      ? '$count reservas están actualmente en el horario de hoy.'
      : '$count bookings currently on today schedule.';

  String get openAdminTitle => isSpanish ? 'Abrir admin' : 'Open admin';

  String get everythingLooksHealthy => isSpanish
      ? 'Todo se ve bien. Revisa clases, miembros y planes.'
      : 'Everything looks healthy. Review classes, members and plans.';

  String get goToAdminTools => isSpanish
      ? 'Ve a las herramientas de admin para gestionar clases, miembros y planes.'
      : 'Go to admin tools to manage classes, members and plans.';

  String get todayWord => isSpanish ? 'Hoy' : 'Today';

  String get tomorrowWord => isSpanish ? 'Mañana' : 'Tomorrow';

  String birthdayTitle(String name) =>
      isSpanish ? 'Cumpleaños de $name' : '$name birthday';

  String turnsAge(String when, int age) =>
      isSpanish ? '$when · cumple $age' : '$when · turns $age';

  String inactiveTitle(String name) =>
      isSpanish ? '$name inactivo' : '$name inactive';

  String get classWithLowOccupancy =>
      isSpanish ? 'Clase con baja ocupación' : 'Class with low occupancy';

  String get noBookingsYetOnboarding => isSpanish
      ? 'Todavía sin reservas · puede necesitar seguimiento de onboarding'
      : 'No bookings yet · member may need onboarding follow-up';

  String get noBookingsYetNewMember => isSpanish
      ? 'Todavía sin reservas · miembro nuevo o sin patrón claro'
      : 'No bookings yet · new member or no clear pattern';

  String daysInactiveHighFrequency(int days) => isSpanish
      ? '$days días inactivo · miembro frecuente en riesgo'
      : '$days days inactive · high-frequency member at risk';

  String daysInactiveRegular(int days) => isSpanish
      ? '$days días inactivo · miembro regular en riesgo'
      : '$days days inactive · regular member at risk';

  String daysInactiveLowFrequency(int days) => isSpanish
      ? '$days días inactivo · miembro de baja frecuencia en riesgo'
      : '$days days inactive · low-frequency member at risk';

  String daysInactiveNoPattern(int days) => isSpanish
      ? '$days días inactivo · sin patrón reciente'
      : '$days days inactive · no recent pattern';

  String get activeTodayConsistent => isSpanish
      ? 'Activo hoy · miembro constante'
      : 'Active today · consistent member';

  String get activeToday => isSpanish ? 'Activo hoy' : 'Active today';

  String get activeOneDayAgoHealthy => isSpanish
      ? 'Activo hace 1 día · ritmo saludable'
      : 'Active 1 day ago · healthy rhythm';

  String get activeOneDayAgo =>
      isSpanish ? 'Activo hace 1 día' : 'Active 1 day ago';

  String activeDaysAgoVeryConsistent(int days) => isSpanish
      ? 'Activo hace $days días · normalmente muy constante'
      : 'Active $days days ago · usually very consistent';

  String activeDaysAgoRegular(int days) => isSpanish
      ? 'Activo hace $days días · asistencia regular'
      : 'Active $days days ago · regular attendance';

  String activeDaysAgo(int days) =>
      isSpanish ? 'Activo hace $days días' : 'Active $days days ago';

  String activeDaysAgoNoPattern(int days) => isSpanish
      ? 'Activo hace $days días · sin patrón reciente'
      : 'Active $days days ago · no recent pattern';

  String get restDayMessage => isSpanish
      ? 'Descansar es tan importante como entrenar. Deja que tu mente y tu cuerpo se recuperen, haz algo de movilidad y estiramientos. No te tientes a entrenar solo porque te sientes bien.'
      : "Resting is as important as work. Let your mind and body rest, do some mobility and stretching. Don't be tempted to train if you feel good.";

  String get createWorkoutFirst =>
      isSpanish ? 'Crea un entrenamiento primero' : 'Create a workout first';

  String get assignWorkoutModalTitle =>
      isSpanish ? 'Asignar entrenamiento' : 'Assign Workout';

  String get workoutAssignedToClass => isSpanish
      ? 'Entrenamiento asignado a la clase'
      : 'Workout assigned to class';

  String get editWorkoutModalTitle =>
      isSpanish ? 'Editar entrenamiento' : 'Edit Workout';

  String get createWorkoutModalTitle =>
      isSpanish ? 'Crear entrenamiento' : 'Create Workout';

  String get workoutImageSection =>
      isSpanish ? 'Imagen del entrenamiento' : 'Workout image';

  String get tapToChooseImage =>
      isSpanish ? 'Toca para elegir imagen' : 'Tap to choose image';

  String get recurringScheduleTitle =>
      isSpanish ? 'Programación recurrente' : 'Recurring schedule';

  String get recurringScheduleCreated => isSpanish
      ? 'Programación recurrente creada'
      : 'Recurring schedule created';

  String get addMemberTitle => isSpanish ? 'Añadir miembro' : 'Add Member';

  String get fullNameRequiredError =>
      isSpanish ? 'El nombre completo es obligatorio' : 'Full name is required';

  String get validEmailRequiredError =>
      isSpanish ? 'Introduce un email válido' : 'Enter a valid email';

  String get memberCreatedInvitationSent => isSpanish
      ? 'Miembro creado. Email de invitación enviado.'
      : 'Member created. Invitation email sent.';

  String get workoutActionsTitle =>
      isSpanish ? 'Acciones del entrenamiento' : 'Workout actions';

  String get classActionsTitle =>
      isSpanish ? 'Acciones de la clase' : 'Class actions';

  String get workoutNotAssignedLabel =>
      isSpanish ? 'Entrenamiento: no asignado' : 'Workout: not assigned';

  String get editClassModalTitle => isSpanish ? 'Editar clase' : 'Edit Class';

  String get scheduleClassModalTitle =>
      isSpanish ? 'Programar clase' : 'Schedule Class';

  String get editClassModalSubtitle => isSpanish
      ? 'Actualiza la programación, capacidad y detalles del coach.'
      : 'Update scheduling, capacity and coach details.';

  String get scheduleClassModalSubtitle => isSpanish
      ? 'Programa una clase para tu gimnasio.'
      : 'Schedule a class for your gym.';

  String get classSetupSection =>
      isSpanish ? 'Configuración de clase' : 'Class setup';

  String get noCoach => isSpanish ? 'Sin coach' : 'No coach';

  String get startDateLabel => isSpanish ? 'Fecha de inicio' : 'Start Date';

  String get primaryTimeLabel => isSpanish ? 'Hora principal' : 'Primary Time';

  String get recurringScheduleSubtitle => isSpanish
      ? 'Crea la misma clase en varios días y horarios.'
      : 'Create the same class on multiple weekdays and hours.';

  String get repeatUntilLabel => isSpanish ? 'Repetir hasta' : 'Repeat Until';

  String get daysLabel => isSpanish ? 'Días' : 'Days';

  String get timesLabel => isSpanish ? 'Horarios' : 'Times';

  String get addTimeLabel => isSpanish ? 'Añadir hora' : 'Add time';

  String get createScheduleCta =>
      isSpanish ? 'Crear horario' : 'Create Schedule';

  String get classUpdated => isSpanish ? 'Clase actualizada' : 'Class updated';

  String get classCreated => isSpanish ? 'Clase creada' : 'Class created';

  String get workoutSetupSection =>
      isSpanish ? 'Configuración del workout' : 'Workout setup';

  String get noProgram => isSpanish ? 'Sin programa' : 'No program';

  String get workoutTitleLabel =>
      isSpanish ? 'Título del workout' : 'Workout Title';

  String get workoutDateLabel =>
      isSpanish ? 'Fecha del workout' : 'Workout Date';

  String get workoutTypeLabel => isSpanish ? 'Tipo de workout' : 'Workout Type';

  String get workoutTitleHint =>
      isSpanish ? 'Fran - 21-15-9' : 'Fran - 21-15-9';

  String get workoutTypeHint =>
      isSpanish ? 'For Time / AMRAP / EMOM' : 'For Time / AMRAP / EMOM';

  String get descriptionHintWorkout =>
      isSpanish ? 'Por tiempo...' : 'For time...';

  String get uploadingImage => isSpanish ? 'Subiendo...' : 'Uploading...';

  String get workoutUpdated =>
      isSpanish ? 'Workout actualizado' : 'Workout updated';

  String get workoutCreated => isSpanish ? 'Workout creado' : 'Workout created';

  String get assignWorkoutModalSubtitle => isSpanish
      ? 'Vincula un workout a esta clase.'
      : 'Link a workout to this class.';

  String get selectedLabel => isSpanish ? 'Seleccionado' : 'Selected';

  String get assignCta => isSpanish ? 'Asignar' : 'Assign';

  String get workoutLabel => isSpanish ? 'Workout' : 'Workout';

  String get programLabel => isSpanish ? 'Programa' : 'Program';

  String get date => isSpanish ? 'Fecha' : 'Date';

  String get time => isSpanish ? 'Hora' : 'Time';

  String get duration => isSpanish ? 'Duración' : 'Duration';

  String get description => isSpanish ? 'Descripción' : 'Description';

  String get editWorkoutModalSubtitle => isSpanish
      ? 'Actualiza el contenido, tipo e imagen del workout.'
      : 'Update the workout content, type and image.';

  String get createWorkoutModalSubtitle => isSpanish
      ? 'Crea un nuevo workout para el feed de programación.'
      : 'Create a new workout for the programming feed.';

  String get noClassesForThisDay =>
      isSpanish ? 'No hay clases para este día' : 'No classes for this day';

  String get adminProgramsTab => isSpanish ? 'Programas' : 'Programs';

  String get adminClassesTab => isSpanish ? 'Clases' : 'Classes';

  String get adminWorkoutsTab => isSpanish ? 'Entrenamientos' : 'Workouts';

  String get adminMembersTab => isSpanish ? 'Miembros' : 'Members';

  String get adminPlansTab => isSpanish ? 'Planes' : 'Plans';

  String get adminNotificationsTab =>
      isSpanish ? 'Notificaciones' : 'Notifications';

  String get refresh => isSpanish ? 'Actualizar' : 'Refresh';

  String get addUpper => isSpanish ? '+ Añadir' : '+ Add';

  String get searchMembers =>
      isSpanish ? 'Buscar miembros...' : 'Search members...';

  String get noProgramsYet =>
      isSpanish ? 'Todavía no hay programas' : 'No programs yet';

  String get noProgramsYetSubtitle => isSpanish
      ? 'Crea tu primer programa de entrenamiento para organizar clases y entrenamientos.'
      : 'Create your first training program to organize classes and workouts.';

  String adminFilterWithCount(String label, int count) => '$label ($count)';

  String get noClassesToday =>
      isSpanish ? 'No hay clases hoy' : 'No classes today';

  String get noUpcomingClasses =>
      isSpanish ? 'No hay próximas clases' : 'No upcoming classes';

  String get noPastClasses =>
      isSpanish ? 'No hay clases pasadas' : 'No past classes';

  String get noClassesTodaySubtitle => isSpanish
      ? 'Todavía no hay clases programadas para hoy.'
      : 'No classes scheduled for today yet.';

  String get noUpcomingClassesSubtitle => isSpanish
      ? 'No hay clases programadas para mañana o más adelante.'
      : 'No classes scheduled for tomorrow or later.';

  String get noPastClassesSubtitle => isSpanish
      ? 'Todavía no hay clases pasadas para revisar.'
      : 'No past classes to review yet.';

  String get noWorkoutsYet =>
      isSpanish ? 'Todavía no hay entrenamientos' : 'No workouts yet';

  String get noWorkoutsYetSubtitle => isSpanish
      ? 'Crea tu primer entrenamiento para planificar el feed.'
      : 'Create your first workout to plan the training feed.';

  String get noPlansYet => isSpanish ? 'Todavía no hay planes' : 'No plans yet';

  String get noPlansYetSubtitle => isSpanish
      ? 'Crea tu primer plan de membresía para gestionar precios y reservas.'
      : 'Create your first membership plan to manage pricing and bookings.';

  String get todayUpperShort => isSpanish ? 'HOY' : 'TODAY';
  String get upcomingUpper => isSpanish ? 'PRÓXIMAS' : 'UPCOMING';
  String get pastUpper => isSpanish ? 'PASADAS' : 'PAST';

  String durationMinutesShort(String value) =>
      isSpanish ? '$value min' : '$value min';

  String coachNameLabel(String coach) =>
      isSpanish ? 'Coach: $coach' : 'Coach: $coach';

  String spotsCountLabel(String remaining, String total) =>
      isSpanish ? '$remaining/$total plazas' : '$remaining/$total spots';

  String workoutTitleWithName(String title) =>
      isSpanish ? 'Entrenamiento: $title' : 'Workout: $title';

  String get planFallbackLabel => isSpanish ? 'Plan' : 'Plan';

  String bookingWindowDaysText(String days) => isSpanish
      ? '$days días de ventana de reserva'
      : '$days days booking window';

  String classesPerPeriodText(String count, String suffix) => isSpanish
      ? '$count clases por período · $suffix'
      : '$count classes per period · $suffix';

  String creditsTotalText(String count, String suffix) => isSpanish
      ? '$count créditos totales · $suffix'
      : '$count credits total · $suffix';

  String get programActionsTitle =>
      isSpanish ? 'Acciones del programa' : 'Program actions';

  String get editProgramTitle => isSpanish ? 'Editar programa' : 'Edit program';

  String get editProgramActionSubtitle => isSpanish
      ? 'Actualizar nombre y descripción corta'
      : 'Update name and short description';

  String get deleteProgramTitle =>
      isSpanish ? 'Eliminar programa' : 'Delete program';

  String get deleteProgramActionSubtitle => isSpanish
      ? 'Eliminar este programa de entrenamiento'
      : 'Remove this training program';

  String get programDeleted =>
      isSpanish ? 'Programa eliminado' : 'Program deleted';

  String get editWorkoutTitle =>
      isSpanish ? 'Editar entrenamiento' : 'Edit workout';

  String get editWorkoutActionSubtitle => isSpanish
      ? 'Actualizar título, tipo, fecha e imagen'
      : 'Update title, type, date and image';

  String get deleteWorkoutTitle =>
      isSpanish ? 'Eliminar entrenamiento' : 'Delete workout';

  String get deleteWorkoutActionSubtitle => isSpanish
      ? 'Eliminar este entrenamiento del feed'
      : 'Remove this workout from the feed';

  String get workoutDeleted =>
      isSpanish ? 'Entrenamiento eliminado' : 'Workout deleted';

  String get attendanceTitle => isSpanish ? 'Asistencia' : 'Attendance';

  String get attendanceActionSubtitle =>
      isSpanish ? 'Abrir lista y check-ins' : 'Open roster and check-ins';

  String get editClassActionTitle => isSpanish ? 'Editar clase' : 'Edit class';

  String get editClassActionSubtitle => isSpanish
      ? 'Actualizar coach, horario y plazas'
      : 'Update coach, schedule and spots';

  String get deleteClassTitle => isSpanish ? 'Eliminar clase' : 'Delete class';

  String get deleteClassActionSubtitle =>
      isSpanish ? 'Eliminar solo esta clase' : 'Remove only this class';

  String get classDeleted => isSpanish ? 'Clase eliminada' : 'Class deleted';

  String get deleteThisAndFutureTitle =>
      isSpanish ? 'Eliminar esta y futuras' : 'Delete this and future';

  String get deleteThisAndFutureSubtitle => isSpanish
      ? 'Eliminar futuras clases para este programa y horario'
      : 'Remove future classes for this program and time';

  String deletedClassesCount(int count) =>
      isSpanish ? '$count clases eliminadas' : '$count classes deleted';

  String get noMembersYet =>
      isSpanish ? 'Todavía no hay miembros' : 'No members yet';

  String get noMembersYetSubtitle => isSpanish
      ? 'Los miembros que se registren en la app aparecerán aquí automáticamente.'
      : 'Members who register in the app will appear here automatically.';

  String get assignPlanTitle => isSpanish ? 'Asignar plan' : 'Assign Plan';

  String get assignPlanSubtitle => isSpanish
      ? 'Vincula un plan de membresía a este atleta.'
      : 'Link a membership plan to this athlete.';

  String get statusLabel => isSpanish ? 'Estado' : 'Status';
  String get activeLabel => isSpanish ? 'Activo' : 'Active';
  String get pausedLabel => isSpanish ? 'Pausado' : 'Paused';
  String get expiredLabel => isSpanish ? 'Expirado' : 'Expired';
  String get cancelledLabel => isSpanish ? 'Cancelado' : 'Cancelled';
  String get pendingPaymentLabel =>
      isSpanish ? 'Pago pendiente' : 'Pending Payment';

  String get startDateShort => isSpanish ? 'Fecha inicio' : 'Start Date';
  String get endDateShort => isSpanish ? 'Fecha fin' : 'End Date';
  String get creditsLabel => isSpanish ? 'Créditos' : 'Credits';
  String get usedLabel => isSpanish ? 'Usados' : 'Used';

  String get planAssigned => isSpanish ? 'Plan asignado' : 'Plan assigned';
  String get noPlanShort => isSpanish ? 'Sin plan' : 'No Plan';

  String get cannotBookFutureClasses => isSpanish
      ? 'No puede reservar clases futuras'
      : 'Cannot book future classes';

  String creditsRemainingText(dynamic count) => isSpanish
      ? '${count.toString()} créditos restantes'
      : '${count.toString()} credits remaining';

  String classesUsedThisPeriodText(dynamic count) => isSpanish
      ? '${count.toString()} usadas en este período'
      : '${count.toString()} used this period';

  String get unlimitedAccess =>
      isSpanish ? 'Acceso ilimitado' : 'Unlimited access';

  String get noActiveMembershipShort =>
      isSpanish ? 'Sin membresía activa' : 'No active membership';

  String activeUntilAutoRenew(String endDate, bool autoRenew) => isSpanish
      ? 'Activo hasta $endDate · Renovación automática ${autoRenew ? 'activada' : 'desactivada'}'
      : 'Active until $endDate · Auto-renew ${autoRenew ? 'on' : 'off'}';

  String noEndDateAutoRenew(bool autoRenew) => isSpanish
      ? 'Sin fecha de fin · Renovación automática ${autoRenew ? 'activada' : 'desactivada'}'
      : 'No end date · Auto-renew ${autoRenew ? 'on' : 'off'}';

  String get memberActionsTitle =>
      isSpanish ? 'Acciones del miembro' : 'Member actions';

  String get sendPasswordEmailTitle =>
      isSpanish ? 'Enviar email de contraseña' : 'Send password email';

  String get sendPasswordEmailSubtitle => isSpanish
      ? 'Reenviar un enlace seguro para crear o restablecer contraseña'
      : 'Resend a secure link to create or reset password';

  String get passwordEmailSent =>
      isSpanish ? 'Email de contraseña enviado' : 'Password email sent';

  String get deactivateMemberTitle =>
      isSpanish ? 'Desactivar miembro' : 'Deactivate member';

  String get deactivateMemberSubtitle => isSpanish
      ? 'Mantener el perfil pero desactivar el acceso'
      : 'Keep the profile but disable active access';

  String get memberDeactivated =>
      isSpanish ? 'Miembro desactivado' : 'Member deactivated';

  String get activateMemberTitle =>
      isSpanish ? 'Activar miembro' : 'Activate member';

  String get activateMemberSubtitle => isSpanish
      ? 'Restaurar acceso y marcar este miembro como activo'
      : 'Restore access and mark this member as active';

  String get memberActivated =>
      isSpanish ? 'Miembro activado' : 'Member activated';

  String get makeAthleteTitle => isSpanish ? 'Hacer atleta' : 'Make athlete';

  String get makeAthleteSubtitle => isSpanish
      ? 'Quitar permisos elevados a este miembro'
      : 'Remove elevated access for this member';

  String get roleUpdatedToAthlete =>
      isSpanish ? 'Rol actualizado a atleta' : 'Role updated to athlete';

  String get makeAdminTitle => isSpanish ? 'Hacer admin' : 'Make admin';

  String get makeAdminSubtitle => isSpanish
      ? 'Dar permisos de admin a este miembro'
      : 'Give this member admin permissions';

  String get roleUpdatedToAdmin =>
      isSpanish ? 'Rol actualizado a admin' : 'Role updated to admin';

  String get linkedDataDeleteError => isSpanish
      ? 'No se puede borrar porque hay datos vinculados.'
      : 'Cannot delete because there is linked data.';

  String get deleteProgramLinkedError => isSpanish
      ? 'No se puede borrar el programa porque tiene clases o entrenamientos asociados.'
      : 'Cannot delete the program because it has related classes or workouts.';

  String get deletePlanLinkedError => isSpanish
      ? 'No se puede borrar el plan porque hay miembros que lo tienen asociado.'
      : 'Cannot delete the plan because members are assigned to it.';

  String get deleteClassLinkedError => isSpanish
      ? 'No se puede borrar la clase porque tiene reservas asociadas.'
      : 'Cannot delete the class because it has related bookings.';

  String get deleteWorkoutLinkedError => isSpanish
      ? 'No se puede borrar el entrenamiento porque está asociado o tiene actividad.'
      : 'Cannot delete the workout because it is linked or has activity.';

  String get adminDataLoadError => isSpanish
      ? 'No se pudieron cargar los datos de admin'
      : 'Could not load admin data';

  String get gymIdRequiredError => isSpanish
      ? 'No se pudo determinar el gym id'
      : 'Could not determine gym id';

  String get dateRequiredError =>
      isSpanish ? 'La fecha es obligatoria' : 'Date is required';

  String get timeRequiredError =>
      isSpanish ? 'La hora es obligatoria' : 'Time is required';

  String get dateFormatYmdError =>
      isSpanish ? 'La fecha debe ser YYYY-MM-DD' : 'Date must be YYYY-MM-DD';

  String get timeFormatHmError =>
      isSpanish ? 'La hora debe ser HH:mm' : 'Time must be HH:mm';

  String get invalidDateError => isSpanish ? 'Fecha inválida' : 'Invalid date';

  String get invalidTimeError => isSpanish ? 'Hora inválida' : 'Invalid time';

  String get programNameRequiredError => isSpanish
      ? 'El nombre del programa es obligatorio'
      : 'Program name is required';

  String get planNameRequiredError =>
      isSpanish ? 'El nombre del plan es obligatorio' : 'Plan name is required';

  String get planTypeRequiredError =>
      isSpanish ? 'El tipo de plan es obligatorio' : 'Plan type is required';

  String get billingPeriodRequiredError => isSpanish
      ? 'El período de facturación es obligatorio'
      : 'Billing period is required';

  String get invalidPriceError =>
      isSpanish ? 'Precio inválido' : 'Invalid price';

  String get invalidClassesPerPeriodError =>
      isSpanish ? 'Clases por período inválidas' : 'Invalid classes per period';

  String get invalidCreditsTotalError =>
      isSpanish ? 'Créditos totales inválidos' : 'Invalid credits total';

  String get invalidBookingWindowError =>
      isSpanish ? 'Ventana de reserva inválida' : 'Invalid booking window';

  String get programRequiredError =>
      isSpanish ? 'El programa es obligatorio' : 'Program is required';

  String get invalidDurationError =>
      isSpanish ? 'Duración inválida' : 'Invalid duration';

  String get invalidMaxSpotsError =>
      isSpanish ? 'Plazas máximas inválidas' : 'Invalid max spots';

  String get classesCannotBeInPastError => isSpanish
      ? 'No se pueden programar clases en el pasado'
      : 'Classes cannot be scheduled in the past';

  String get startDateRequiredError => isSpanish
      ? 'La fecha de inicio es obligatoria'
      : 'Start date is required';

  String get repeatUntilRequiredError =>
      isSpanish ? 'Repetir hasta es obligatorio' : 'Repeat until is required';

  String get invalidStartDateError =>
      isSpanish ? 'Fecha de inicio inválida' : 'Invalid start date';

  String get invalidRepeatUntilDateError => isSpanish
      ? 'Fecha de fin de repetición inválida'
      : 'Invalid repeat until date';

  String get repeatUntilAfterStartError => isSpanish
      ? 'La fecha de fin debe ser posterior a la fecha de inicio'
      : 'Repeat until must be after start date';

  String get selectAtLeastOneWeekdayError => isSpanish
      ? 'Selecciona al menos un día de la semana'
      : 'Select at least one weekday';

  String get addAtLeastOneTimeError =>
      isSpanish ? 'Añade al menos un horario' : 'Add at least one time';

  String invalidTimeValueError(String value) =>
      isSpanish ? 'Hora inválida: $value' : 'Invalid time: $value';

  String get noClassesGeneratedError => isSpanish
      ? 'No se generaron clases para los días/rango seleccionados'
      : 'No classes generated for the selected days/date range';

  String get workoutTitleRequiredError => isSpanish
      ? 'El título del entrenamiento es obligatorio'
      : 'Workout title is required';

  String get workoutDateRequiredError => isSpanish
      ? 'La fecha del entrenamiento es obligatoria'
      : 'Workout date is required';

  String duplicateWorkoutForProgramDateError(String title) => isSpanish
      ? 'Ya existe un WOD para este programa en esa fecha: $title'
      : 'A workout already exists for this program on that date: $title';

  String workoutNotificationError(String error) => isSpanish
      ? 'Error de notificación del entrenamiento: $error'
      : 'Workout notification error: $error';

  String workoutAutoAssignedMessage(int count) => isSpanish
      ? 'Entrenamiento creado y asignado automáticamente a $count clases.'
      : 'Workout created and auto-assigned to $count classes.';
}
