import 'package:flutter/material.dart';

class QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const QtyBtn({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
