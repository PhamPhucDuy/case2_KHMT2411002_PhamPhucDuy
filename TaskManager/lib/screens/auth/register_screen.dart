
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // Xử lý khi nhấn nút đăng ký
  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService().register(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
      );

      if (!mounted) return;

      // Đăng ký thành công, trở về đăng nhập
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 70,
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Tạo tài khoản mới',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),

                  const SizedBox(height: 24),

                  // Họ và tên
                  TextFormField(
                    controller: _name,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon:
                          Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

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
                      helperText: 'Ít nhất 8 ký tự',
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
                          value.length < 8) {
                        return 'Mật khẩu phải có ít nhất 8 ký tự';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Xác nhận mật khẩu
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: _hidePassword,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                      prefixIcon:
                          Icon(Icons.lock_reset),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != _password.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),

                  const SizedBox(height: 24),

                  // Nút đăng ký
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
                          : const Text('Đăng ký'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text(
                      'Đã có tài khoản? Đăng nhập',
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
