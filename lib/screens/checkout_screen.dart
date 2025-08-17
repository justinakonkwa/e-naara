import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/services/app_state.dart';
import 'package:ecommerce/models/cart.dart';
import 'package:ecommerce/models/order.dart';
import 'package:ecommerce/screens/order_success_screen.dart';
import 'package:ecommerce/screens/payment_simulation_screen.dart';
import 'package:ecommerce/components/state_messages.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    if (user != null) {
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    final appState = context.read<AppState>();
    if (appState.isCartEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Votre panier est vide'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final shippingAddress = '${_addressController.text}, ${_postalCodeController.text} ${_cityController.text}';
      
      final order = await appState.createOrder(
        total: _calculateTotal(),
        shippingAddress: shippingAddress,
        paymentMethod: _selectedPaymentMethod,
      );

      if (order != null) {
        if (mounted) {
          // Rediriger vers l'écran de simulation de paiement
          final paymentSuccess = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => PaymentSimulationScreen(
                amount: _calculateTotal(),
                orderId: order.id,
              ),
            ),
          );

          if (paymentSuccess == true) {
            // Paiement réussi, aller à l'écran de succès
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const OrderSuccessScreen(),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création de la commande: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  double _calculateTotal() {
    final appState = context.read<AppState>();
    final subtotal = appState.cartSubtotal;
    const shipping = 9.99;
    const tax = 0.0; // TVA à calculer selon les règles fiscales
    return subtotal + shipping + tax;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final cartItems = appState.cartItems;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé de la commande
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Résumé de la commande',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Articles
                      ...cartItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.product.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 50,
                                  height: 50,
                                  color: theme.colorScheme.surface,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Quantité: ${item.quantity}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(item.product.price * item.quantity).toStringAsFixed(2)} €',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      
                      const Divider(height: 32),
                      
                      // Totaux
                      _buildTotalRow('Sous-total', appState.cartSubtotal, theme),
                      _buildTotalRow('Livraison', 9.99, theme),
                      _buildTotalRow('TVA', 0.0, theme),
                      const SizedBox(height: 8),
                      _buildTotalRow('Total', _calculateTotal(), theme, isTotal: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Adresse de livraison
              Text(
                'Adresse de livraison',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse *',
                  border: OutlineInputBorder(),
                  hintText: '123 Rue de la Paix',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'adresse est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postalCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Code postal *',
                        border: OutlineInputBorder(),
                        hintText: '75001',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le code postal est requis';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Ville *',
                        border: OutlineInputBorder(),
                        hintText: 'Paris',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La ville est requise';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                  hintText: '+33 1 23 45 67 89',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Méthode de paiement
              Text(
                'Méthode de paiement',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Carte bancaire'),
                      subtitle: const Text('Visa, Mastercard, American Express'),
                      value: 'card',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('PayPal'),
                      subtitle: const Text('Paiement sécurisé via PayPal'),
                      value: 'paypal',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Apple Pay'),
                      subtitle: const Text('Paiement via Apple Pay'),
                      value: 'apple_pay',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bouton de commande
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Confirmer la commande (${_calculateTotal().toStringAsFixed(2)} €)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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

  Widget _buildTotalRow(String label, double amount, ThemeData theme, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} €',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
