import 'package:ecommerce/models/product.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;
  final String selectedSize;
  final String selectedColor;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedSize = '',
    this.selectedColor = '',
  });

  double get totalPrice => product.price * quantity;
  double get originalTotalPrice => product.originalPrice * quantity;
  double get totalSavings => originalTotalPrice - totalPrice;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      selectedSize: json['selected_size'] ?? '',
      selectedColor: json['selected_color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'selected_size': selectedSize,
      'selected_color': selectedColor,
    };
  }
}

class Cart {
  final List<CartItem> items = [];

  void addItem(CartItem item) {
    final existingIndex = items.indexWhere(
      (cartItem) => 
          cartItem.product.id == item.product.id &&
          cartItem.selectedSize == item.selectedSize &&
          cartItem.selectedColor == item.selectedColor,
    );

    if (existingIndex >= 0) {
      items[existingIndex].quantity += item.quantity;
    } else {
      items.add(item);
    }
  }

  void removeItem(String itemId) {
    items.removeWhere((item) => item.id == itemId);
  }

  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    final index = items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      items[index].quantity = newQuantity;
    }
  }

  void clear() {
    items.clear();
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  double get totalSavings => items.fold(0.0, (sum, item) => sum + item.totalSavings);
  
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

class PromoCode {
  final String code;
  final String description;
  final double discountPercentage;
  final double maxDiscount;
  final DateTime expiryDate;
  final bool isActive;

  const PromoCode({
    required this.code,
    required this.description,
    required this.discountPercentage,
    required this.maxDiscount,
    required this.expiryDate,
    required this.isActive,
  });

  bool get isValid => isActive && DateTime.now().isBefore(expiryDate);
  
  double calculateDiscount(double subtotal) {
    if (!isValid) return 0.0;
    final discount = subtotal * (discountPercentage / 100);
    return discount > maxDiscount ? maxDiscount : discount;
  }
}