import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';

/// A focused auth boundary so feature providers only depend on a user id.
final authUserIdProvider = StreamProvider<String?>((ref) {
  return AuthService()
      .authStateChanges
      .map((_) => AuthService().currentUser?.uid);
});
