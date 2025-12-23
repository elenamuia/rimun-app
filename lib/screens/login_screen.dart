import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models.dart';
import '../services.dart';

class LoginScreen extends StatefulWidget {
  final void Function(Student) onLoggedIn;

  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ===============================
      // 🔐 LOGIN DEMO (solo in DEBUG)
      // ===============================
      if (kDebugMode &&
          _emailCtrl.text.trim() == 'demo@rimun.it' &&
          _passwordCtrl.text.trim() == '123') {
        final student = Student(
          id: 'demo-user',
          name: 'Demo',
          surname: 'RIMUN',
          email: 'demo@rimun.it',
          school: 'RIMUN Demo School',
          country: 'Italy',
        );
        widget.onLoggedIn(student);
        return;
      }

      // ===============================
      // 🔥 LOGIN FIREBASE (futuro)
      // ===============================
      final bool isFirebaseSupported =
          kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows;

      if (isFirebaseSupported) {
        final authService = AuthService();
        final student = await authService.signInWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text.trim(),
        );
        widget.onLoggedIn(student);
      } else {
        // Fallback locale (Linux ecc.)
        final email = _emailCtrl.text.trim();
        final student = Student(
          id: 'local-demo',
          name: email.isNotEmpty ? email.split('@').first : 'Demo',
          surname: '',
          email: email,
          school: 'Demo School',
          country: 'Demo',
        );
        widget.onLoggedIn(student);
      }
    } catch (e) {
      setState(() {
        _error = 'Credentials not valid or connection error.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 SFONDO
          Container(
            color: const Color(0xFF0F245B),
          ),

          // 🔹 LOGO DI SFONDO
          Center(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/logo_frase.png',
                width: 700,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 🔹 CARD LOGIN
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'RIMUN APP',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _emailCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Insert email' : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Insert password'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          if (_error != null)
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),

                          const SizedBox(height: 16),

                          // 🔘 LOGIN BUTTON con ICONA
                          FilledButton.icon(
                            onPressed: _loading ? null : _submit,
                            icon: const Icon(Icons.person),
                            label: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
