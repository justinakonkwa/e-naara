import 'package:flutter/material.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/order.dart';
import 'package:ecommerce/screens/driver_qr_scanner_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<SimpleOrder> _availableOrders = [];
  List<SimpleOrder> _myOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availableOrders = await SupabaseService.getAvailableOrders();
      final myOrders = await SupabaseService.getDriverOrders();

      setState(() {
        _availableOrders = availableOrders;
        _myOrders = myOrders;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [DASHBOARD] Erreur lors du chargement: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _assignOrder(String orderId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await SupabaseService.assignOrderToDriver(orderId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Commande assignée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadOrders(); // Recharger les listes
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Impossible d\'assigner la commande'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ [DASHBOARD] Erreur lors de l\'assignation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickUpOrder(String orderId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await SupabaseService.markOrderAsPickedUp(orderId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📦 Commande marquée comme récupérée !'),
            backgroundColor: Colors.blue,
          ),
        );
        await _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Impossible de marquer comme récupérée'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ [DASHBOARD] Erreur lors de la récupération: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAssignment(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'assignation'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette commande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await SupabaseService.cancelOrderAssignment(orderId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Assignation annulée'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Impossible d\'annuler l\'assignation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ [DASHBOARD] Erreur lors de l\'annulation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showOrderDetails(SimpleOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Statut', _getStatusText(order.status)),
            _buildInfoRow('Montant', '${order.totalAmount.toStringAsFixed(2)} €'),
            _buildInfoRow('Adresse', order.shippingAddress),
            _buildInfoRow('Méthode de paiement', order.paymentMethod),
            _buildInfoRow('Date de création', _formatDate(order.createdAt)),
            if (order.assignedAt != null)
              _buildInfoRow('Assignée le', _formatDate(order.assignedAt!)),
            if (order.pickedUpAt != null)
              _buildInfoRow('Récupérée le', _formatDate(order.pickedUpAt!)),
            const SizedBox(height: 16),
            if (order.status == 'assigned')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _pickUpOrder(order.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('📦 Marquer comme récupérée'),
                ),
              ),
            if (order.status == 'picked_up')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DriverQRScannerScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🚚 Scanner QR pour livraison'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'assigned':
        return 'Assignée';
      case 'picked_up':
        return 'Récupérée';
      case 'in_transit':
        return 'En transit';
      case 'delivered':
        return 'Livrée';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'picked_up':
        return Colors.indigo;
      case 'in_transit':
        return Colors.cyan;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header avec statistiques
          _buildStatsHeader(theme),
          
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary,
                ),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Disponibles'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Mes Commandes'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contenu des tabs
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des commandes...'),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAvailableOrdersTab(),
                      _buildMyOrdersTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              theme,
              icon: Icons.inbox_rounded,
              title: 'Disponibles',
              value: _availableOrders.length.toString(),
              color: Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatCard(
              theme,
              icon: Icons.local_shipping_rounded,
              title: 'En cours',
              value: _myOrders.length.toString(),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableOrdersTab() {
    if (_availableOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.blue.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune commande disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les nouvelles commandes apparaîtront ici',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableOrders.length,
        itemBuilder: (context, index) {
          final order = _availableOrders[index];
          return _buildOrderCard(
            order: order,
            isAvailable: true,
            onAction: () => _assignOrder(order.id),
            actionText: 'Récupérer',
            actionColor: Colors.green,
            actionIcon: Icons.local_shipping_rounded,
          );
        },
      ),
    );
  }

  Widget _buildMyOrdersTab() {
    if (_myOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 64,
                color: Colors.blue.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune commande assignée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Récupérez des commandes dans l\'onglet "Disponibles"',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myOrders.length,
        itemBuilder: (context, index) {
          final order = _myOrders[index];
          return _buildOrderCard(
            order: order,
            isAvailable: false,
            onAction: () => _showOrderActions(order),
            actionText: _getActionText(order.status),
            actionColor: _getActionColor(order.status),
            actionIcon: _getActionIcon(order.status),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard({
    required SimpleOrder order,
    required bool isAvailable,
    required VoidCallback onAction,
    required String actionText,
    required Color actionColor,
    required IconData actionIcon,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(order),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec ID et montant
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commande #${order.id.substring(0, 8)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${order.totalAmount.toStringAsFixed(2)} €',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(order.status).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusText(order.status),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Adresse de livraison
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.shippingAddress,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Bouton d'action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAction,
                    icon: Icon(actionIcon, size: 18),
                    label: Text(actionText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getActionText(String status) {
    switch (status) {
      case 'assigned':
        return 'Marquer comme récupérée';
      case 'picked_up':
        return 'Scanner pour livrer';
      default:
        return 'Voir détails';
    }
  }

  Color _getActionColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String status) {
    switch (status) {
      case 'assigned':
        return Icons.inventory_2_rounded;
      case 'picked_up':
        return Icons.qr_code_scanner_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  void _showOrderActions(SimpleOrder order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Actions pour la commande #${order.id.substring(0, 8)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (order.status == 'assigned')
              _buildActionButton(
                icon: Icons.inventory_2_rounded,
                title: 'Marquer comme récupérée',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _pickUpOrder(order.id);
                },
              ),
            if (order.status == 'picked_up')
              _buildActionButton(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scanner pour livrer',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DriverQRScannerScreen(),
                    ),
                  );
                },
              ),
            _buildActionButton(
              icon: Icons.cancel_rounded,
              title: 'Annuler l\'assignation',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _cancelAssignment(order.id);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
