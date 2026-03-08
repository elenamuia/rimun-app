// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api/models.dart';
import 'services.dart';
import 'services/rimun_api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (API base URL, etc.)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Fallback silently if .env is missing; defaults will be used
  }

  final bool isFirebaseSupported =
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  if (isFirebaseSupported) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // In tests or unsupported envs, ignore initialization errors
    }
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
        iconTheme: const IconThemeData(size: 22, color: Colors.white),
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
          data: mq.copyWith(textScaler: TextScaler.linear(totalTextScale)),
          child: IconTheme(
            data: IconTheme.of(context).copyWith(size: 22 * totalIconScale),
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
  LoginResult? _session;
  late final ApiService _apiService;
  bool _loading = true;

  String _resolveBaseUrl() {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['API_BASE_URL'] ??
            dotenv.env['VITE_RIMUN_API_URL'] ??
            'http://127.0.0.1:8081';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8081';
  }

  @override
  void initState() {
    super.initState();

    _apiService = ApiService(
      baseUrl: _resolveBaseUrl(),
      getToken: () => _session?.token ?? '',
    );

    final bool isFirebaseSupported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;

    if (isFirebaseSupported) {
      try {
        final authService = AuthService();
        authService.authStateChanges().listen((user) async {
          if (!mounted) return;

          if (user == null) {
            setState(() {
              _session = null;
              _loading = false;
            });
          } else {
            setState(() {
              _loading = false;
            });
          }
        });
      } catch (_) {
        // If Firebase is not initialized or unavailable in tests, show login
        setState(() {
          _session = null;
          _loading = false;
        });
      }
    } else {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return LoginScreen(
        apiService: _apiService,
        onLoggedIn: (session) {
          setState(() => _session = session);
        },
      );
    } else {
      return HomeScreen(
        apiService: _apiService,
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
            setState(() => _session = null);
          }
        },
      );
    }
  }
}
