import 'package:flutter/material.dart';
import 'package:ecommerce/services/qr_code_service.dart';
import 'package:ecommerce/models/order.dart';

class QRCodeCardWidget extends StatelessWidget {
  final SimpleOrder order;
  final bool isPaymentQR;
  final VoidCallback? onTap;
  final bool showCode;

  const QRCodeCardWidget({
    super.key,
    required this.order,
    this.isPaymentQR = false,
    this.onTap,
    this.showCode = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrPainter = QRCodeService.generateOrderQRCode(order);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPaymentQR 
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPaymentQR ? Icons.payment : Icons.local_shipping,
                    color: isPaymentQR ? Colors.blue : Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPaymentQR ? 'QR Code de Paiement' : 'QR Code de Livraison',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Commande #${order.id.substring(0, 8)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} €',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // QR Code
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CustomPaint(
                  painter: qrPainter,
                  size: const Size(120, 120),
                ),
              ),
            ),
            
            if (showCode) ...[
              const SizedBox(height: 12),
              
              // Code court
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  QRCodeService.generateShortCode(order.id),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Instructions
            Text(
              isPaymentQR 
                ? 'Présentez au commerçant'
                : 'Présentez au livreur',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
