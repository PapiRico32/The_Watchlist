/// Pantalla de inicio de sesión de usuario.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class PantallaLogin extends StatefulWidget {
  /// StatefulWidget porque controla textos, errores y estado de inicio de sesión.
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  // Controllers mantienen el texto escrito sin que Flutter pierda el valor.
  final _correo = TextEditingController();
  final _password = TextEditingController();
  // Mensaje visible cuando falta información o falla el servidor.
  String? _error;

  @override
  void dispose() {
    // Los controllers deben liberarse para evitar fugas de memoria.
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }


  Future<void> _iniciarSesion() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_correo.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Completa correo y contrasena');
      return;
    }

    try {
      await auth.iniciarSesion(_correo.text.trim(), _password.text);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/inicio');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AuthCard(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA21CAF)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withAlpha(55),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.movie_filter_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'The Watchlist',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Historias para compartir. Personas con quien vivirlas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 34),
                  CustomTextField(
                    controller: _correo,
                    label: 'Correo electrónico',
                    prefixIcon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _password,
                    label: 'Contraseña',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => auth.cargando ? null : _iniciarSesion(),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBE123C).withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFB7185).withAlpha(90),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFFDA4AF)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: auth.cargando ? 'Iniciando sesión…' : 'Iniciar sesión',
                    icon: Icons.login_rounded,
                    loading: auth.cargando,
                    onPressed: _iniciarSesion,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/registro'),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                ],
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
