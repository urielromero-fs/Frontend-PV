import 'package:flutter/material.dart';

class RoleUtils {
  static String getRoleLabel(String? role) {
    if (role == null) return 'Sin rol';
    switch (role.trim().toLowerCase()) {
      case 'admin':
      case 'administrador':
        return 'Administrador';
      case 'seller':
      case 'cajero':
        return 'Cajero';
      case 'master':
        return 'Master';
      case 'creator':
        return 'Creador';
      default:
        return role;
    }
  }

  static Color getRoleColor(String? role) {
    if (role == null) return Colors.grey;
    switch (role.trim().toLowerCase()) {
      case 'admin':
      case 'administrador':
        return Colors.blueAccent;
      case 'seller':
      case 'cajero':
        return const Color(0xFF05e265);
      case 'master':
        return Colors.deepPurpleAccent;
      case 'creator':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }
}
