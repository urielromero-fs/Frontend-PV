import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/withdrawal_service.dart';
import 'package:pv26/core/utils/currency_formatter.dart';

class WithdrawalDialog extends StatefulWidget {
  final Function(double) onSaved;

  const WithdrawalDialog({
    super.key,
    required this.onSaved,
  });

  @override
  State<WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends State<WithdrawalDialog> {
  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  bool isWithdrawing = false;

  Future<void> submitWithdrawal() async {
    if (isWithdrawing) return;
    
    final double amount = double.tryParse(amountController.text.replaceAll(",", "")) ?? 0.0;
    final String reason = reasonController.text.trim();

    if (amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresa un monto válido'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresa un motivo'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => isWithdrawing = true);
    
    // Mostrar loader interno
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final response = await WithdrawalService.createWithdrawal(
      amount: amount,
      reason: reason,
    );

    if (mounted) {
      Navigator.pop(context); // cerrar loader
      if (response['success'] == true) {
        widget.onSaved(amount);
        Navigator.pop(context); // cerrar dialog principal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retiro registrado correctamente'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() => isWithdrawing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Error inesperado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          submitWithdrawal();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Salida de Efectivo',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              autofocus: true,
              onSubmitted: (_) => submitWithdrawal(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [CurrencyInputFormatter()],
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Monto a retirar',
                labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                prefixText: r'$ ',
                prefixStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              onSubmitted: (_) => submitWithdrawal(),
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Motivo / Concepto',
                labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
            ),
          ),
          ElevatedButton(
            onPressed: isWithdrawing ? null : submitWithdrawal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05e265),
            ),
            child: isWithdrawing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text(
                  'Registrar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
                ),
          ),
        ],
      ),
    );
  }
}
