import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
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
  bool _showPassword = false;

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
                : 'Cuenta creada. Ahora crea tu granja o únete con un código.',
          ),
        ),
      );
    } else {
      await controller.signIn(email: _email.text, password: _password.text);
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
                        Image.asset(
                          'assets/images/logo.png',
                          height: 150,
                          semanticLabel: 'PorcinoTech',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _registering
                              ? 'Crea tu cuenta'
                              : 'Inicia sesión para ver tu granja',
                          style: Theme.of(context).textTheme.titleMedium,
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
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            suffixIcon: IconButton(
                              tooltip: _showPassword
                                  ? 'Ocultar contraseña'
                                  : 'Mostrar contraseña',
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                            ),
                            helperText: _registering
                                ? 'Mínimo 8 caracteres, con letras y números'
                                : null,
                          ),
                          validator: (v) {
                            final value = v ?? '';
                            if (value.isEmpty) return 'Ingresa tu contraseña';
                            if (!_registering) return null;
                            if (value.length < 8 ||
                                !RegExp(r'[A-Za-z]').hasMatch(value) ||
                                !RegExp(r'\d').hasMatch(value)) {
                              return 'Mínimo 8 caracteres, con letras y números';
                            }
                            return null;
                          },
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
                            onPressed: isLoading
                                ? null
                                : () => context.go('/recuperar'),
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
