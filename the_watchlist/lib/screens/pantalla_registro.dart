/// Pantalla para crear una cuenta de usuario.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _password.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_nombre.text.trim().isEmpty ||
        _correo.text.trim().isEmpty ||
        _password.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }

    if (_password.text.length < 8) {
      setState(() => _error = 'La contrasena debe tener al menos 8 caracteres');
      return;
    }

    if (_password.text != _confirmacion.text) {
      setState(() => _error = 'Las contrasenas no coinciden');
      return;
    }

    try {
      await auth.registrar(
        _nombre.text.trim(),
        _correo.text.trim(),
        _password.text,
      );

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
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: AuthBackground(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: AuthCard(
        child: Column(
          children: [
            CustomTextField(
              controller: _nombre,
              label: 'Nombre de usuario',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _correo,
              label: 'Correo electronico',
              prefixIcon: Icons.alternate_email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _password,
              label: 'Contrasena',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmacion,
              label: 'Confirmar contrasena',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            PrimaryButton(
              text: 'Crear cuenta',
              icon: Icons.person_add,
              loading: auth.cargando,
              onPressed: _registrarse,
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
