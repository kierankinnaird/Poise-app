// Entry point. I initialise Firebase and notifications before runApp so every
// service downstream can safely call their APIs synchronously.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();

  // Force the status bar to light text on a transparent background.
  // I do it here AND in PoiseTheme so it applies before the first frame renders.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const PoiseApp());
}

class PoiseApp extends StatelessWidget {
  const PoiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poise',
      debugShowCheckedModeBanner: false,
      theme: PoiseTheme.light(),
      // I listen to the Firebase auth stream here so the routing is reactive.
      // Signing in or out anywhere in the app automatically redirects.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: PoiseColors.background,
              body: Center(
                child: Image(
                  image: AssetImage('assets/images/logo.png'),
                  width: 96,
                  height: 96,
                ),
              ),
            );
          }
          return snapshot.hasData ? const HomeScreen() : const AuthScreen();
        },
      ),
    );
  }
}
