import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/app_state.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

/// Routes to [LoginScreen] or [MainNavigationScreen] depending on real
/// Firebase Auth state, and keeps [AppState] attached to the signed-in
/// user's Firestore data (bots) for as long as they're signed in.
///
/// The attach/detach side effect is driven by its own subscription in
/// [initState] rather than inline in `build`, so it never fires during a
/// widget build.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    _authStream.listen((user) {
      if (user == null) {
        AppState().detachUser();
      } else {
        AppState().attachToUser(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data == null ? const LoginScreen() : const MainNavigationScreen();
      },
    );
  }
}
