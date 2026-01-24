// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'models.dart';
import 'services.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool isFirebaseSupported =
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  if (isFirebaseSupported) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MUNApp());
}

class MUNApp extends StatelessWidget {
  const MUNApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark(useMaterial3: true);

    return MaterialApp(
      title: 'RIMUN App',

      // 🎨 THEME BASE (NON tocchiamo textTheme.apply per evitare crash su web/M3)
      theme: baseTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(
          size: 22,
          color: Colors.white,
        ),
      ),

      // 📱 RESPONSIVE SCALING (font + icone) in modo stabile
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final width = mq.size.width;

        // 390px ≈ iPhone 14
        final deviceScale = (width / 390.0).clamp(0.95, 1.12);

        // 👇 aumento globale richiesto (sempre)
        const baseFontScale = 1.08;

        final totalTextScale = mq.textScaleFactor * deviceScale * baseFontScale;
        final totalIconScale = deviceScale; // icone seguono solo deviceScale

        return MediaQuery(
          data: mq.copyWith(
            textScaleFactor: totalTextScale,
          ),
          child: IconTheme(
            data: IconTheme.of(context).copyWith(
              size: 22 * totalIconScale,
            ),
            child: child!,
          ),
        );
      },

      home: const LoginWrapper(),
    );
  }
}

class LoginWrapper extends StatefulWidget {
  const LoginWrapper({super.key});

  @override
  State<LoginWrapper> createState() => _LoginWrapperState();
}

class _LoginWrapperState extends State<LoginWrapper> {
  Student? _student;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    final bool isFirebaseSupported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;

    if (isFirebaseSupported) {
      final authService = AuthService();
      authService.authStateChanges().listen((user) async {
        if (!mounted) return;

        if (user == null) {
          setState(() {
            _student = null;
            _loading = false;
          });
        } else {
          final email = user.email ?? '';
          final basic = Student(
            id: user.uid,
            name: email.isNotEmpty ? email.split('@').first : 'Studente',
            surname: '',
            email: email,
            school: '',
            country: '',
          );

          setState(() {
            _student = basic;
            _loading = false;
          });
        }
      });
    } else {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_student == null) {
      return LoginScreen(
        onLoggedIn: (student) {
          setState(() => _student = student);
        },
      );
    } else {
      return HomeScreen(
        student: _student!,
        onLogout: () async {
          final bool isFirebaseSupported =
              kIsWeb ||
              defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows;

          if (isFirebaseSupported) {
            final authService = AuthService();
            await authService.signOut();
          }

          if (mounted) {
            setState(() => _student = null);
          }
        },
      );
    }
  }
}
