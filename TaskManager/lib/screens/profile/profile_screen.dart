import 'package:flutter/material.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  late Future<Map<String, dynamic>> _future;

  Map<String, dynamic> _user = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final user = await _service.getProfile();

    if (mounted) {
      _user = user;
      _name.text = user['fullName']?.toString() ?? '';
    }

    return user;
  }

  Future<void> _refresh() async {
    final next = _load();

    setState(() {
      _future = next;
    });

    try {
      await next;
    } catch (_) {
      // FutureBuilder hien thi loi.
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final newName = _name.text.trim();

      await _service.updateProfile(newName);

      if (!mounted) return;

      setState(() {
        _user = {
          ..._user,
          'fullName': newName,
        };
        _future = Future.value(_user);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u0110\u00E3 c\u1EADp nh\u1EADt h\u1ED3 s\u01A1',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openChangePassword() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ChangePasswordScreen(),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u0110\u1ED5i m\u1EADt kh\u1EA9u th\u00E0nh c\u00F4ng',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'H\u1ED3 s\u01A1 c\u00E1 nh\u00E2n',
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : _refresh,
            tooltip: 'L\u00E0m m\u1EDBi',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text(
                      'Th\u1EED l\u1EA1i',
                    ),
                  ),
                ],
              ),
            );
          }

          final email =
              _user['email']?.toString() ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(
                    radius: 42,
                    child: Icon(
                      Icons.person,
                      size: 45,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'T\u00E0i kho\u1EA3n c\u1EE7a t\u00F4i',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'H\u1ECD v\u00E0 t\u00EAn',
                      prefixIcon:
                          Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().length < 2) {
                        return 'Vui l\u00F2ng nh\u1EADp h\u1ECD t\u00EAn';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                          Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(email),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Ch\u1EC9 c\u00F3 th\u1EC3 \u0111\u1ED5i h\u1ECD t\u00EAn '
                    '\u1EDF m\u00E0n h\u00ECnh n\u00E0y.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _saving
                          ? '\u0110ang l\u01B0u...'
                          : 'L\u01B0u thay \u0111\u1ED5i',
                    ),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : _openChangePassword,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text(
                      '\u0110\u1ED5i m\u1EADt kh\u1EA9u',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================
// MAN HINH DOI MAT KHAU
// =============================

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProfileService();

  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();

  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.changePassword(
        currentPassword: _current.text,
        newPassword: _newPassword.text,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscure,
      enabled: !_saving,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u0110\u1ED5i m\u1EADt kh\u1EA9u',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_reset,
                size: 70,
              ),

              const SizedBox(height: 24),

              _passwordField(
                controller: _current,
                label:
                    'M\u1EADt kh\u1EA9u hi\u1EC7n t\u1EA1i',
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui l\u00F2ng nh\u1EADp '
                        'm\u1EADt kh\u1EA9u hi\u1EC7n t\u1EA1i';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _passwordField(
                controller: _newPassword,
                label: 'M\u1EADt kh\u1EA9u m\u1EDBi',
                validator: (v) {
                  if (v == null || v.length < 8) {
                    return 'M\u1EADt kh\u1EA9u m\u1EDBi '
                        'ph\u1EA3i c\u00F3 \u00EDt nh\u1EA5t '
                        '8 k\u00FD t\u1EF1';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _passwordField(
                controller: _confirm,
                label:
                    'X\u00E1c nh\u1EADn m\u1EADt kh\u1EA9u m\u1EDBi',
                validator: (v) {
                  if (v != _newPassword.text) {
                    return 'Hai m\u1EADt kh\u1EA9u '
                        'kh\u00F4ng kh\u1EDBp';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CheckboxListTile(
                value: !_obscure,
                title: const Text(
                  'Hi\u1EC3n th\u1ECB m\u1EADt kh\u1EA9u',
                ),
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          _obscure = !(value ?? false);
                        });
                      },
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.check),
                label: Text(
                  _saving
                      ? '\u0110ang x\u1EED l\u00FD...'
                      : 'C\u1EADp nh\u1EADt m\u1EADt kh\u1EA9u',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}