import 'package:flutter/material.dart';

import 'api.dart';
import 'brand.dart';
import 'notify.dart';
import 'screens/admin_home.dart';
import 'screens/faculty_home.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await resolveApiBase();
  final restored = await Session.instance.restore();
  runApp(SmartTrackApp(loggedIn: restored));
}

class SmartTrackApp extends StatelessWidget {
  const SmartTrackApp({super.key, required this.loggedIn});
  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTrack',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: Notify.key,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          child ?? const SizedBox.shrink(),
          const BusyOverlay(),
        ],
      ),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Outfit',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Brand.green,
          primary: Brand.deep,
          secondary: Brand.orange,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Brand.contentBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Brand.dark,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Brand.dark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Brand.active.withValues(alpha: 0.18),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: _gate(),
    );
  }

  Widget _gate() {
    if (!loggedIn) return const LoginScreen();
    return Session.instance.isAdmin ? const AdminHome() : const FacultyHome();
  }
}
