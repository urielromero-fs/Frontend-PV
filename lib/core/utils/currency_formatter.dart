import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double value) {
    if (value.isNaN || value.isInfinite) return r'$ 0.00';
    final formatter = NumberFormat("#,###.00", "en_US");
    return r'$ ' + formatter.format(value);
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    // Limpiar caracteres no numéricos excepto el punto decimal
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    // Manejar el caso de múltiples puntos decimales
    if (newText.split('.').length > 2) {
      return oldValue;
    }
    // Dividir parte entera y decimal
    List<String> parts = newText.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.' + parts[1] : '';
    // Limitar decimales a 2
    if (parts.length > 1 && parts[1].length > 2) {
      decimalPart = '.' + parts[1].substring(0, 2);
    }
    // Dar formato de miles a la parte entera
    if (integerPart.isNotEmpty) {
      try {
        final formatter = NumberFormat("#,###", "en_US");
        integerPart = formatter.format(int.parse(integerPart));
      } catch (e) {
        // En caso de error (ej. número demasiado grande), devolvemos el valor original
        return oldValue;
      }
    }
    String result = integerPart + decimalPart;
    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
