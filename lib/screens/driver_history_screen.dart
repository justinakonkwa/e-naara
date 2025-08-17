import 'package:flutter/material.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/order.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  List<SimpleOrder> _deliveredOrders = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, week, month, year

  @override
  void initState() {
    super.initState();
    _loadDeliveredOrders();
  }

  Future<void> _loadDeliveredOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await SupabaseService.getDeliveredOrders();
      setState(() {
        _deliveredOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [HISTORY] Erreur lors du chargement: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<SimpleOrder> _getFilteredOrders() {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _deliveredOrders.where((order) => 
          order.deliveredAt != null && order.deliveredAt!.isAfter(weekAgo)
        ).toList();
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return _deliveredOrders.where((order) => 
          order.deliveredAt != null && order.deliveredAt!.isAfter(monthAgo)
        ).toList();
      case 'year':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        return _deliveredOrders.where((order) => 
          order.deliveredAt != null && order.deliveredAt!.isAfter(yearAgo)
        ).toList();
      default:
        return _deliveredOrders;
    }
  }

  double _calculateTotalEarnings() {
    return _getFilteredOrders().fold(0, (sum, order) => sum + order.totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredOrders = _getFilteredOrders();
    final totalEarnings = _calculateTotalEarnings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de Livraison'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadDeliveredOrders,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header avec statistiques
            _buildStatsHeader(theme, filteredOrders.length, totalEarnings),
            
            // Filtres
            _buildFilterChips(theme),
            
            // Liste des commandes
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Chargement de l\'historique...'),
                        ],
                      ),
                    )
                  : filteredOrders.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildOrdersList(theme, filteredOrders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme, int orderCount, double totalEarnings) {
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
              icon: Icons.check_circle_rounded,
              title: 'Livraisons',
              value: orderCount.toString(),
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
              icon: Icons.euro_rounded,
              title: 'Gains',
              value: '${totalEarnings.toStringAsFixed(2)} €',
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

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(theme, 'Tout', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Cette semaine', 'week'),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Ce mois', 'month'),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Cette année', 'year'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, String value) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                      Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Aucune livraison trouvée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos livraisons complétées apparaîtront ici',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
                      ElevatedButton.icon(
              onPressed: _loadDeliveredOrders,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualiser'),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(ThemeData theme, List<SimpleOrder> orders) {
    return RefreshIndicator(
      onRefresh: _loadDeliveredOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildHistoryCard(order);
        },
      ),
    );
  }

  Widget _buildHistoryCard(SimpleOrder order) {
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
                         color: theme.colorScheme.primaryContainer,
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Icon(
                         Icons.check_circle_rounded,
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
                         color: theme.colorScheme.primaryContainer,
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(
                           color: theme.colorScheme.primary.withValues(alpha: 0.3),
                         ),
                       ),
                       child: Text(
                         'Livrée',
                         style: theme.textTheme.bodySmall?.copyWith(
                           color: theme.colorScheme.primary,
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
                
                const SizedBox(height: 12),
                
                // Date de livraison
                if (order.deliveredAt != null)
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Livrée le ${_formatDate(order.deliveredAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showOrderDetails(SimpleOrder order) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Titre
              Text(
                'Détails de la livraison',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('ID Commande', '#${order.id.substring(0, 8)}'),
                      _buildDetailRow('Montant', '${order.totalAmount.toStringAsFixed(2)} €'),
                      _buildDetailRow('Adresse', order.shippingAddress),
                      if (order.deliveredAt != null)
                        _buildDetailRow('Date de livraison', _formatDate(order.deliveredAt!)),
                      if (order.pickedUpAt != null)
                        _buildDetailRow('Date de récupération', _formatDate(order.pickedUpAt!)),
                      if (order.assignedAt != null)
                        _buildDetailRow('Date d\'assignation', _formatDate(order.assignedAt!)),
                      
                      const SizedBox(height: 20),
                      
                      // Statut de livraison
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Livraison complétée',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'La commande a été livrée avec succès',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
