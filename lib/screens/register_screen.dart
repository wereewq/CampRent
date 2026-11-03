import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();
  Role _role = Role.reader;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Регистрация в CampRent',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  TextField(
                    controller: _username,
                    decoration: const InputDecoration(labelText: 'Логин'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fullName,
                    decoration: const InputDecoration(labelText: 'ФИО'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Role>(
                    initialValue: _role,
                    items: Role.values
                        .map(
                          (r) =>
                              DropdownMenuItem(value: r, child: Text(r.title)),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _role = v ?? Role.reader;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Роль'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await context.read<AuthNotifier>().register(
                          _username.text,
                          _password.text,
                          _fullName.text,
                          _role,
                        );
                        if (context.mounted) {
                          context.go('/catalog');
                        }
                      } catch (e) {
                        setState(() => _error = 'Ошибка регистрации');
                      }
                    },
                    child: const Text('Зарегистрироваться'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Назад ко входу'),
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
