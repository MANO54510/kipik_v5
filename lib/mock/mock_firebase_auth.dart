import 'package:flutter/foundation.dart';

class MockFirebaseAuth {
  static final MockFirebaseAuth instance = MockFirebaseAuth._internal();

  MockFirebaseAuth._internal();

  Future<void> signInAnonymously() async {
    debugPrint("⚡ [MockFirebaseAuth] signInAnonymously appelé.");
  }

  Future<void> signOut() async {
    debugPrint("⚡ [MockFirebaseAuth] signOut appelé.");
  }

  // Tu peux rajouter d'autres méthodes au besoin
}
