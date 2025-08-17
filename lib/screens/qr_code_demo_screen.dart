import 'package:flutter/material.dart';
import 'package:ecommerce/screens/qr_scanner_screen.dart';
import 'package:ecommerce/screens/qr_code_display_screen.dart';
import 'package:ecommerce/screens/driver_qr_scanner_screen.dart';
import 'package:ecommerce/widgets/qr_code_card_widget.dart';
import 'package:ecommerce/models/order.dart';

class QRCodeDemoScreen extends StatelessWidget {
  const QRCodeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Créer des commandes de démonstration
    final demoOrder1 = SimpleOrder(
      id: 'demo_order_001',
      userId: 'demo_user',
      totalAmount: 45.99,
      shippingAddress: '123 Rue de la Paix, Paris',
      paymentMethod: 'card',
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final demoOrder2 = SimpleOrder(
      id: 'demo_order_002',
      userId: 'demo_user',
      totalAmount: 29.50,
      shippingAddress: '456 Avenue des Champs, Lyon',
      paymentMethod: 'card',
      status: 'shipped',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Démonstration QR Code'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fonctionnalités QR Code',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Testez toutes les fonctionnalités de scan et génération de QR codes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Section Scanner
            Text(
              'Scanner QR Codes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Scanner QR Code',
                    Icons.qr_code_scanner,
                    Colors.blue,
                    'Scanner n\'importe quel QR code',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DriverQRScannerScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Scanner Livraison',
                    Icons.local_shipping,
                    Colors.green,
                    'Scanner QR codes de livraison',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DriverQRScannerScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section Génération
            Text(
              'Générer QR Codes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'QR Code Paiement',
                    Icons.payment,
                    Colors.orange,
                    'Générer QR code de paiement',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QRCodeDisplayScreen(
                          order: demoOrder1,
                          isPaymentQR: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'QR Code Livraison',
                    Icons.local_shipping,
                    Colors.purple,
                    'Générer QR code de livraison',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QRCodeDisplayScreen(
                          order: demoOrder2,
                          isPaymentQR: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section Aperçu
            Text(
              'Aperçu des QR Codes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: QRCodeCardWidget(
                    order: demoOrder1,
                    isPaymentQR: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QRCodeDisplayScreen(
                          order: demoOrder1,
                          isPaymentQR: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QRCodeCardWidget(
                    order: demoOrder2,
                    isPaymentQR: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QRCodeDisplayScreen(
                          order: demoOrder2,
                          isPaymentQR: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section Informations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                                     _buildInfoRow(context, 'QR Code Paiement', 'Contient les informations de commande pour le paiement'),
                   _buildInfoRow(context, 'QR Code Livraison', 'Contient les informations pour confirmer la livraison'),
                   _buildInfoRow(context, 'Scanner Général', 'Peut scanner n\'importe quel QR code valide'),
                   _buildInfoRow(context, 'Scanner Livraison', 'Spécialisé pour les livreurs avec confirmation'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton de test
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showTestInstructions(context);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Instructions de Test'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showTestInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instructions de Test'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Générez un QR code de paiement ou de livraison'),
            SizedBox(height: 8),
            Text('2. Utilisez l\'écran de scanner pour le lire'),
            SizedBox(height: 8),
            Text('3. Testez la validation et le traitement'),
            SizedBox(height: 8),
            Text('4. Vérifiez les informations décodées'),
            SizedBox(height: 8),
            Text('5. Testez l\'écran de scanner pour livreurs'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
