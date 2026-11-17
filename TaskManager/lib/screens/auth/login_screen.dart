
import 'package:flutter/material.dart';
import '../../widgets/app_theme_toggle_button.dart';
import '../../services/auth_service.dart';
import '../stats/statistics_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Xử lý đăng nhập
  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService().login(
        _email.text.trim(),
        _password.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const StatisticsScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Chuyển sang màn hình đăng ký
  Future<void> _openRegister() async {
    final registered =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );

    if (!mounted || registered != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đăng ký thành công! Hãy đăng nhập.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: const [AppThemeToggleButton()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 70,
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Đăng nhập',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),

                  const SizedBox(height: 24),

                  // Email
                  TextFormField(
                    controller: _email,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                          Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Mật khẩu
                  TextFormField(
                    controller: _password,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword =
                                !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),

                  const SizedBox(height: 24),

                  // Nút đăng nhập
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(14),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Đăng nhập'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nút chuyển sang đăng ký
                  TextButton(
                    onPressed:
                        _loading ? null : _openRegister,
                    child: const Text(
                      'Chưa có tài khoản? Đăng ký',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
