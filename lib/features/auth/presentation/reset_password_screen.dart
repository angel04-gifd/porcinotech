import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

/// Recuperar contraseña: 1) escribes tu correo y recibes un código de 6 dígitos;
/// 2) escribes el código y tu nueva contraseña.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _emailValid => _email.text.trim().contains('@');

  Future<void> _sendCode() async {
    if (!_emailValid) {
      setState(() => _error = 'Ingresa un correo válido.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _busy = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _busy = false;
        _error = e.statusCode == '429'
            ? 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.'
            : 'No se pudo enviar el correo. Inténtalo de nuevo.';
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Sin conexión con el servidor. Revisa tu internet.';
      });
    }
  }

  Future<void> _reset() async {
    final password = _password.text;
    if (_code.text.trim().length < 6) {
      setState(() => _error = 'Escribe el código que llegó a tu correo.');
      return;
    }
    if (password.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      setState(
        () => _error = 'La contraseña necesita 8 caracteres, con letras y números.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPasswordWithCode(
            email: _email.text,
            code: _code.text,
            newPassword: password,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada.')),
      );
      context.go('/dashboard');
    } on AuthException catch (e) {
      final text = e.message.toLowerCase();
      setState(() {
        _busy = false;
        _error = text.contains('expired') || text.contains('invalid')
            ? 'El código no es válido o ya venció. Pide uno nuevo.'
            : text.contains('same') || text.contains('different')
            ? 'La nueva contraseña debe ser distinta a la anterior.'
            : text.contains('weak') || text.contains('password')
            ? 'La contraseña es muy débil. Usa una más larga.'
            : 'No se pudo cambiar la contraseña. Inténtalo de nuevo.';
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Sin conexión con el servidor. Revisa tu internet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/images/logo.png', height: 110),
                    const SizedBox(height: 12),
                    Text(
                      _codeSent
                          ? 'Te enviamos un código de verificación a ${_email.text.trim()}. Revisa también la carpeta de spam.'
                          : 'Escribe el correo de tu cuenta y te enviaremos un código para crear una nueva contraseña.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _email,
                      enabled: !_codeSent && !_busy,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                      ),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        decoration: const InputDecoration(
                          labelText: 'Código del correo',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          helperText: 'Mínimo 8 caracteres, con letras y números',
                          suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Ocultar contraseña'
                                : 'Mostrar contraseña',
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : (_codeSent ? _reset : _sendCode),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _codeSent ? 'Cambiar contraseña' : 'Enviar código',
                              ),
                      ),
                    ),
                    if (_codeSent)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _codeSent = false;
                                _error = null;
                                _code.clear();
                                _password.clear();
                              }),
                        child: const Text('Pedir un código nuevo'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
