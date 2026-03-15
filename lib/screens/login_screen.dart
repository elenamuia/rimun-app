import 'package:flutter/material.dart';

import 'package:rimun_app/api/models.dart';
import 'package:rimun_app/services/rimun_api_service.dart';

class LoginScreen extends StatefulWidget {
  final ApiService apiService;
  final void Function(LoginResult session) onLoggedIn;

  const LoginScreen({
    super.key,
    required this.apiService,
    required this.onLoggedIn,
  });

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
      final result = await widget.apiService.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      widget.onLoggedIn(result);
    } catch (e) {
      debugPrint('Login error: $e');
      setState(() => _error = 'Credentials not valid or connection error.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFF0F245B)),

          Center(
            child: Opacity(
              opacity: 0.10,
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Image.asset(
                  'assets/logo_frase.png',
                  width: MediaQuery.of(context).size.width * 1.6,
                ),
              ),
            ),
          ),

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
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Insert email' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
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
