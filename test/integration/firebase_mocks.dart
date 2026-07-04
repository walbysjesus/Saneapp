
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  User? _user;
  @override
  User? get currentUser => _user;
  set mockUser(User? user) => _user = user;
}

class MockUser extends Mock implements User {
  @override
  String get uid => 'test-uid';
}
