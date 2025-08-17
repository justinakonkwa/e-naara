import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecommerce/services/qr_code_service.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/order.dart';

class DriverQRScannerScreen extends StatefulWidget {
  const DriverQRScannerScreen({super.key});

  @override
  State<DriverQRScannerScreen> createState() => _DriverQRScannerScreenState();
}

class _DriverQRScannerScreenState extends State<DriverQRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _scannedOrders = [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        _processQRCode(code);
        break;
      }
    }
  }

  void _processQRCode(String qrData) async {
    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });

    try {
      // Décoder le QR code
      final decodedData = QRCodeService.decodeQRCode(qrData);
      
      if (decodedData == null) {
        _showError('QR code invalide');
        return;
      }

      // Valider le type de QR code
      if (!QRCodeService.isValidOrderQRCode(qrData)) {
        _showError('QR code non reconnu');
        return;
      }

      // Extraire l'ID de commande
      final orderId = QRCodeService.extractOrderId(qrData);
      if (orderId == null) {
        _showError('ID de commande manquant');
        return;
      }

      // Vérifier si la commande a déjà été scannée
      if (_scannedOrders.any((order) => order['order_id'] == orderId)) {
        _showError('Cette commande a déjà été scannée');
        return;
      }

      // Récupérer les vraies données de la commande depuis Supabase
      final order = await SupabaseService.getOrderByIdForDriver(orderId);
      
      if (order == null) {
        _showError('Commande non trouvée dans la base de données');
        return;
      }

      // Vérifier que la commande n'est pas déjà livrée
      if (order.status == 'delivered') {
        _showError('Cette commande a déjà été livrée');
        return;
      }

      // Ajouter la commande à la liste avec les vraies données
      setState(() {
        _scannedOrders.add({
          'order_id': orderId,
          'qr_data': decodedData,
          'order': order, // Ajouter l'objet order complet
          'scanned_at': DateTime.now(),
        });
        _isProcessing = false;
        _isScanning = true;
      });

      _showSuccess('Commande #${orderId.substring(0, 8)} scannée avec succès');
    } catch (e) {
      _showError('Erreur lors du traitement: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      _isProcessing = false;
      _isScanning = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _isScanning = true;
            });
          },
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showConfirmationDialog(String orderId, SimpleOrder? order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la Livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous confirmer la livraison de la commande #${orderId.substring(0, 8)} ?'),
            const SizedBox(height: 16),
            if (order != null) ...[
              Text('Montant: ${order.totalAmount.toStringAsFixed(2)} €'),
              const SizedBox(height: 8),
              Text('Adresse: ${order.shippingAddress}'),
              const SizedBox(height: 8),
              Text('Statut actuel: ${_getStatusText(order.status)}'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Cette action mettra à jour le statut de la commande à "Livré" dans la base de données.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelivery(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelivery(String orderId) async {
    try {
      print('🚚 [DRIVER] Début de la confirmation de livraison pour: $orderId');
      
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Confirmer la livraison dans Supabase
      print('🚚 [DRIVER] Appel de SupabaseService.confirmDelivery...');
      final success = await SupabaseService.confirmDeliverySimple(orderId);
      print('🚚 [DRIVER] Résultat de confirmDelivery: $success');
      
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (success) {
        print('🚚 [DRIVER] Confirmation réussie, mise à jour de l\'interface');
        
        // Retirer la commande de la liste
        setState(() {
          _scannedOrders.removeWhere((order) => order['order_id'] == orderId);
        });

        _showSuccess('Livraison confirmée pour la commande #${orderId.substring(0, 8)}');
        
        // Afficher une boîte de dialogue de confirmation
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Livraison Confirmée'),
            content: Text('La livraison de la commande #${orderId.substring(0, 8)} a été confirmée avec succès.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        print('🚚 [DRIVER] Échec de la confirmation');
        _showError('Échec de la confirmation de livraison');
      }
    } catch (e) {
      print('🚚 [DRIVER] Erreur lors de la confirmation: $e');
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showError('Erreur lors de la confirmation: $e');
    }
  }

  void _toggleFlash() {
    controller.toggleTorch();
  }

  void _switchCamera() {
    controller.switchCamera();
  }

  void _showDeliveryHistory() async {
    print('📋 [DRIVER] Affichage de l\'historique des livraisons');
    
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Récupérer l'historique des livraisons
      print('📋 [DRIVER] Appel de SupabaseService.getDeliveredOrders...');
      final deliveredOrders = await SupabaseService.getDeliveredOrders();
      print('📋 [DRIVER] Nombre de commandes livrées récupérées: ${deliveredOrders.length}');
      
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      // Afficher l'historique dans une boîte de dialogue
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Historique des Livraisons'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: deliveredOrders.isEmpty
              ? const Center(
                  child: Text('Aucune livraison confirmée'),
                )
              : ListView.builder(
                  itemCount: deliveredOrders.length,
                  itemBuilder: (context, index) {
                    final order = deliveredOrders[index];
                    return ListTile(
                      title: Text('Commande #${order.id.substring(0, 8)}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${order.totalAmount.toStringAsFixed(2)} €'),
                          Text('Livrée le ${_formatDate(order.updatedAt)}'),
                        ],
                      ),
                      trailing: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    );
                  },
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('📋 [DRIVER] Erreur lors du chargement de l\'historique: $e');
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showError('Erreur lors du chargement de l\'historique: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scanner QR Codes de Livraison',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _showDeliveryHistory,
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                ),
                
                // Overlay avec zone de scan
                _buildScanOverlay(),
                
                // Indicateur de traitement
                if (_isProcessing)
                  _buildProcessingOverlay(),
                
                // Instructions
                _buildInstructions(),
              ],
            ),
          ),
          
          // Liste des commandes scannées
          Expanded(
            flex: 1,
            child: _buildScannedOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Coins décoratifs
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Traitement en cours...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 8),
            const Text(
              'Scannez les QR codes de livraison',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_scannedOrders.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_scannedOrders.length} commande(s) scannée(s)',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScannedOrdersList() {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Commandes Scannées (${_scannedOrders.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _scannedOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune commande scannée',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scannez un QR code pour commencer',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _scannedOrders.length,
                  itemBuilder: (context, index) {
                    final orderData = _scannedOrders[index];
                    final orderId = orderData['order_id'] as String;
                    final scannedAt = orderData['scanned_at'] as DateTime;
                    final order = orderData['order'] as SimpleOrder?;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            '#${orderId.substring(0, 6)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Commande #${orderId.substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scannée à ${_formatTime(scannedAt)}'),
                            if (order != null) ...[
                              Text(
                                '${order.totalAmount.toStringAsFixed(2)} €',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Statut: ${_getStatusText(order.status)}',
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Adresse: ${order.shippingAddress}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _showConfirmationDialog(orderId, order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Confirmer'),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'processing':
        return 'En traitement';
      case 'shipped':
        return 'Expédié';
      case 'out_for_delivery':
        return 'En livraison';
      case 'delivered':
        return 'Livré';
      case 'cancelled':
        return 'Annulé';
      case 'returned':
        return 'Retourné';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'out_for_delivery':
        return Colors.green;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'returned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
