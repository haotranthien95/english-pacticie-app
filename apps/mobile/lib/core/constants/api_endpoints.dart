/// API endpoint constants
class ApiEndpoints {
  // Authentication
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String socialAuth = '/auth/social';
  static const String refreshToken = '/auth/refresh';

  // User Profile
  static const String profile = '/users/me';

  // Game
  static const String tags = '/game/tags';
  static const String randomSpeeches = '/game/speeches/random';
  static const String gameSessions = '/game/sessions';
  static String gameSessionDetail(String id) => '/game/sessions/$id';

  // Speech
  static const String scoreSpeech = '/speech/score';
}
