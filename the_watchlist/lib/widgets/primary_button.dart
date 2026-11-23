/// Botón principal con el estilo consistente de la interfaz.
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  /// Botón morado reutilizable que puede mostrar progreso y estar deshabilitado.
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : icon == null ? null : Icon(icon),
        label: Text(text),
      ),
    );
  }
}
