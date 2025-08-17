import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/services/delivery_notification_service.dart';
import 'package:ecommerce/screens/delivery_confirmation_screen.dart';

class DeliveryRequestScreen extends StatelessWidget {
  final DeliveryRequest delivery;

  const DeliveryRequestScreen({
    super.key,
    required this.delivery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Commande #${delivery.order.id.substring(0, 8)}'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de statut
            _buildStatusCard(theme),
            
            const SizedBox(height: 24),
            
            // Informations de la commande
            _buildOrderInfoCard(theme),
            
            const SizedBox(height: 24),
            
            // Adresse de livraison
            _buildDeliveryAddressCard(theme),
            
            const SizedBox(height: 24),
            
            // Carte (simulée)
            _buildMapCard(theme),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActionButtons(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    Color statusColor;
    IconData statusIcon;
    
    switch (delivery.status) {
      case DeliveryStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case DeliveryStatus.accepted:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case DeliveryStatus.inProgress:
        statusColor = Colors.green;
        statusIcon = Icons.local_shipping;
        break;
      case DeliveryStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        break;
      case DeliveryStatus.declined:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case DeliveryStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery.statusDisplayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Informations de la commande',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('ID Commande', '#${delivery.order.id.substring(0, 8)}'),
          _buildInfoRow('Montant total', '${delivery.order.totalAmount.toStringAsFixed(2)} €'),
          _buildInfoRow('Méthode de paiement', delivery.order.paymentMethod),
          _buildInfoRow('Date de création', _formatDate(delivery.createdAt)),
          if (delivery.acceptedAt != null)
            _buildInfoRow('Date d\'acceptation', _formatDate(delivery.acceptedAt!)),
          if (delivery.startedAt != null)
            _buildInfoRow('Date de début', _formatDate(delivery.startedAt!)),
          if (delivery.completedAt != null)
            _buildInfoRow('Date de fin', _formatDate(delivery.completedAt!)),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Adresse de livraison',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.home,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    delivery.order.shippingAddress,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Livraison estimée: ${_formatTime(delivery.estimatedDeliveryTime)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.map,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Carte de livraison',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Carte interactive',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Intégration Google Maps à venir',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        if (delivery.canBeAccepted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _acceptDelivery(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Accepter la livraison',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _declineDelivery(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Refuser la livraison',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        
        if (delivery.canBeStarted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startDelivery(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Démarrer la livraison',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        
        if (delivery.canBeCompleted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _completeDelivery(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirmer la livraison',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openQRScanner(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Scanner QR Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription() {
    switch (delivery.status) {
      case DeliveryStatus.pending:
        return 'En attente d\'acceptation par un livreur';
      case DeliveryStatus.accepted:
        return 'Commande acceptée, prête à être livrée';
      case DeliveryStatus.inProgress:
        return 'Livraison en cours';
      case DeliveryStatus.completed:
        return 'Livraison terminée avec succès';
      case DeliveryStatus.declined:
        return 'Commande refusée par le livreur';
      case DeliveryStatus.cancelled:
        return 'Commande annulée';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Actions
  void _acceptDelivery(BuildContext context) {
    context.read<DeliveryNotificationService>().acceptDelivery(delivery.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Commande #${delivery.order.id.substring(0, 8)} acceptée'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

  void _declineDelivery(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la livraison'),
        content: const Text('Êtes-vous sûr de vouloir refuser cette livraison ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<DeliveryNotificationService>().declineDelivery(
                delivery.id,
                'Refusé par le livreur',
              );
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Commande #${delivery.order.id.substring(0, 8)} refusée'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  void _startDelivery(BuildContext context) {
    context.read<DeliveryNotificationService>().startDelivery(delivery.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Livraison #${delivery.order.id.substring(0, 8)} démarrée'),
        backgroundColor: Colors.blue,
      ),
    );
    Navigator.of(context).pop();
  }

  void _completeDelivery(BuildContext context) {
    context.read<DeliveryNotificationService>().completeDelivery(delivery.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Livraison #${delivery.order.id.substring(0, 8)} terminée'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

  void _openQRScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DeliveryConfirmationScreen(),
      ),
    );
  }
}
