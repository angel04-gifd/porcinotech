import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _registering = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    if (_registering) {
      final requiresConfirmation = await controller.signUp(
        email: _email.text,
        password: _password.text,
        nombre: _name.text,
      );
      if (!mounted || requiresConfirmation == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requiresConfirmation
                ? 'Cuenta creada. Revisa tu correo para confirmarla.'
                : 'Cuenta creada. Ya puedes ingresar.',
          ),
        ),
      );
    } else {
      await controller.signIn(email: _email.text, password: _password.text);
    }
  }

  Future<void> _recoverPassword() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa primero un correo válido.')),
      );
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .recoverPassword(email: _email.text);
    if (mounted && !ref.read(authControllerProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        final error = next.error;
        final message = error is AuthOperationException
            ? error.message
            : 'No se pudo completar la solicitud. Inténtalo de nuevo.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pets, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          'PorcinoTech',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                          ),
                          validator: (v) => v != null && v.contains('@')
                              ? null
                              : 'Ingresa un correo válido',
                        ),
                        if (_registering) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                          ),
                          validator: (v) => v != null && v.length >= 6
                              ? null
                              : 'Mínimo 6 caracteres',
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: isLoading
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _registering ? 'Crear cuenta' : 'Ingresar',
                                  ),
                          ),
                        ),
                        if (!_registering)
                          TextButton(
                            onPressed: isLoading ? null : _recoverPassword,
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => setState(
                                  () => _registering = !_registering,
                                ),
                          child: Text(
                            _registering
                                ? 'Ya tengo cuenta'
                                : 'Crear una cuenta',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
