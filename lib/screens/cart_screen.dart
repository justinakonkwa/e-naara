import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/data/sample_data.dart';
import 'package:ecommerce/models/cart.dart';
import 'package:ecommerce/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _promoCode = '';
  PromoCode? _appliedPromo;
  double _shippingCost = 9.99;
  double _tax = 0.0;
  bool _showPromoInput = false;

  double get _subtotal => context.watch<DataService>().cartSubtotal;
  double get _discount => _appliedPromo?.calculateDiscount(_subtotal) ?? 0.0;
  double get _total => _subtotal + _shippingCost + _tax - _discount;

  void _applyPromoCode() {
    if (_promoCode.trim().isEmpty) return;
    
    final promo = SampleData.promoCodes.firstWhere(
      (p) => p.code.toLowerCase() == _promoCode.toLowerCase() && p.isValid,
      orElse: () => PromoCode(
        code: '',
        description: '',
        discountPercentage: 0,
        maxDiscount: 0,
        expiryDate: DateTime(2000),
        isActive: false,
      ),
    );

    if (promo.isValid) {
      setState(() {
        _appliedPromo = promo;
        _promoCode = '';
        _showPromoInput = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code promo appliqué : ${promo.description}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code promo invalide ou expiré'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Mon Panier (${dataService.cartItemCount})'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!dataService.isCartEmpty)
            TextButton(
              onPressed: () {
                _showClearCartDialog(context);
              },
              child: Text(
                'Vider',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: dataService.isCartEmpty ? _buildEmptyCart(theme) : _buildCartContent(theme),
    );
  }

  Widget _buildEmptyCart(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Votre panier est vide',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des produits pour commencer vos achats',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Découvrir nos produits'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(ThemeData theme) {
    final dataService = context.watch<DataService>();
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: dataService.cartItems.length,
            itemBuilder: (context, index) {
              final item = dataService.cartItems[index];
              return _buildCartItem(theme, item, dataService);
            },
          ),
        ),
        _buildOrderSummary(theme),
      ],
    );
  }

  Widget _buildCartItem(ThemeData theme, CartItem item, DataService dataService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(item.product.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.product.brand,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '${item.product.price.toStringAsFixed(2)} €',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.product.originalPrice != null && 
                        item.product.originalPrice! > item.product.price)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '${item.product.originalPrice!.toStringAsFixed(2)} €',
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Quantity Controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      if (item.quantity > 1) {
                        dataService.updateCartItemQuantity(item.id, item.quantity - 1);
                      } else {
                        dataService.removeFromCart(item.id);
                      }
                    },
                    icon: Icon(
                      item.quantity > 1 ? Icons.remove : Icons.delete_outline,
                      size: 16,
                      color: item.quantity > 1 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.error,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      minimumSize: const Size(26, 26),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Container(
                    width: 28,
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      dataService.updateCartItemQuantity(item.id, item.quantity + 1);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      minimumSize: const Size(26, 26),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${(item.product.price * item.quantity).toStringAsFixed(2)} €',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Promo Code Section
          _buildCompactPromoSection(theme),
          const SizedBox(height: 16),
          // Summary
          _buildSummaryRow('Sous-total', _subtotal, theme),
          _buildSummaryRow('Livraison', _shippingCost, theme),
          if (_tax > 0) _buildSummaryRow('Taxes', _tax, theme),
          if (_discount > 0) _buildSummaryRow('Réduction', -_discount, theme, isDiscount: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: _buildSummaryRow('Total', _total, theme, isTotal: true),
          ),
          const SizedBox(height: 16),
          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _subtotal > 0 ? _proceedToCheckout : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'Commander (${_total.toStringAsFixed(2)} €)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPromoSection(ThemeData theme) {
    if (_appliedPromo != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Code ${_appliedPromo!.code} appliqué (-${_discount.toStringAsFixed(2)} €)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _appliedPromo = null;
                });
              },
              icon: const Icon(Icons.close, size: 16),
              style: IconButton.styleFrom(
                minimumSize: const Size(24, 24),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );
    }

    if (_showPromoInput) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => _promoCode = value,
                decoration: InputDecoration(
                  hintText: 'Code promo',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _applyPromoCode,
              child: const Text('Appliquer'),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _showPromoInput = false;
                  _promoCode = '';
                });
              },
              icon: const Icon(Icons.close, size: 16),
              style: IconButton.styleFrom(
                minimumSize: const Size(24, 24),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          _showPromoInput = true;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              'Ajouter un code promo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.add,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, ThemeData theme, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} €',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isDiscount ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Êtes-vous sûr de vouloir vider votre panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<DataService>().clearCart();
            },
            child: Text(
              'Vider',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CheckoutScreen(),
      ),
    );
  }
}