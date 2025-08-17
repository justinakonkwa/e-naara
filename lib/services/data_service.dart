import 'package:flutter/foundation.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/models/cart.dart';
import 'package:ecommerce/models/user.dart';
import 'package:ecommerce/models/order.dart';

import 'package:ecommerce/data/sample_data.dart' as sample;

class DataService extends ChangeNotifier {
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  List<CartItem> _cartItems = [];
  List<String> _wishlist = [];
  List<SimpleOrder> _orders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  List<CartItem> get cartItems => _cartItems;
  List<String> get wishlist => _wishlist;
  List<SimpleOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Produits filtrés
  List<Product> get featuredProducts => _products.where((p) => p.isFeatured).toList();
  List<Product> get recentProducts => _products.take(4).toList();

  DataService() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await loadProducts();
    await loadCategories();
  }

  // ===== PRODUITS =====
  
  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _products = await SupabaseService.getProducts();
      
      // Ne plus utiliser les données d'exemple - laisser la liste vide si aucun produit
      print('📦 [DATA] ${_products.length} produits chargés depuis Supabase');
    } catch (e) {
      print('❌ [DATA] Erreur lors du chargement des produits: $e');
      _error = 'Erreur lors du chargement des produits: $e';
      _products = []; // Liste vide en cas d'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.isEmpty) return _products;
      
      final results = await SupabaseService.searchProducts(query);
      return results; // Retourner directement les résultats de Supabase
    } catch (e) {
      _error = 'Erreur lors de la recherche: $e';
      return [];
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final results = await SupabaseService.getProductsByCategory(category);
      return results; // Retourner directement les résultats de Supabase
    } catch (e) {
      _error = 'Erreur lors du chargement des produits par catégorie: $e';
      return [];
    }
  }

  // ===== CATÉGORIES =====
  
  Future<void> loadCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _categories = await SupabaseService.getCategories();
      
      // Si pas de catégories dans Supabase, utiliser les données d'exemple
      if (_categories.isEmpty) {
        print('⚠️ [DATA] Aucune catégorie trouvée dans Supabase, utilisation des données d\'exemple');
        _categories = sample.SampleData.categories.map((cat) => ProductCategory(
          id: cat.id,
          name: cat.name,
          icon: cat.icon,
          subcategories: cat.subcategories,
        )).toList();
      }
    } catch (e) {
      print('❌ [DATA] Erreur lors du chargement des catégories: $e');
      _error = 'Erreur lors du chargement des catégories: $e';
      // Utiliser les données d'exemple en cas d'erreur
      _categories = sample.SampleData.categories.map((cat) => ProductCategory(
        id: cat.id,
        name: cat.name,
        icon: cat.icon,
        subcategories: cat.subcategories,
      )).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== PANIER =====
  
  Future<void> loadCartItems() async {
    try {
      _cartItems = await SupabaseService.getCartItems();
    } catch (e) {
      _error = 'Erreur lors du chargement du panier: $e';
      _cartItems = [];
    }
    notifyListeners();
  }

  Future<void> saveCartItems(List<CartItem> items) async {
    try {
      _cartItems = items;
      await SupabaseService.saveCartItems(items);
    } catch (e) {
      _error = 'Erreur lors de la sauvegarde du panier: $e';
    }
    notifyListeners();
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    try {
      final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
      
      if (existingIndex >= 0) {
        // Mettre à jour la quantité
        final updatedItems = List<CartItem>.from(_cartItems);
        updatedItems[existingIndex] = CartItem(
          id: updatedItems[existingIndex].id,
          product: product,
          quantity: updatedItems[existingIndex].quantity + quantity,
        );
        _cartItems = updatedItems;
      } else {
        // Ajouter un nouvel élément
        final newItem = CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: quantity,
        );
        _cartItems.add(newItem);
      }
      
      await saveCartItems(_cartItems);
    } catch (e) {
      _error = 'Erreur lors de l\'ajout au panier: $e';
    }
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      _cartItems.removeWhere((item) => item.id == itemId);
      await saveCartItems(_cartItems);
    } catch (e) {
      _error = 'Erreur lors de la suppression du panier: $e';
    }
  }

  Future<void> updateCartItemQuantity(String itemId, int quantity) async {
    try {
      final index = _cartItems.indexWhere((item) => item.id == itemId);
      if (index >= 0) {
        final updatedItems = List<CartItem>.from(_cartItems);
        updatedItems[index] = CartItem(
          id: itemId,
          product: _cartItems[index].product,
          quantity: quantity,
        );
        _cartItems = updatedItems;
        await saveCartItems(_cartItems);
      }
    } catch (e) {
      _error = 'Erreur lors de la mise à jour de la quantité: $e';
    }
  }

  Future<void> clearCart() async {
    try {
      _cartItems.clear();
      await saveCartItems(_cartItems);
    } catch (e) {
      _error = 'Erreur lors du vidage du panier: $e';
    }
  }

  // ===== LISTE DE SOUHAITS =====
  
  Future<void> loadWishlist() async {
    try {
      _wishlist = await SupabaseService.getWishlist();
    } catch (e) {
      _error = 'Erreur lors du chargement de la liste de souhaits: $e';
      _wishlist = [];
    }
    notifyListeners();
  }

  Future<void> toggleWishlist(String productId) async {
    try {
      if (_wishlist.contains(productId)) {
        await SupabaseService.removeFromWishlist(productId);
        _wishlist.remove(productId);
      } else {
        await SupabaseService.addToWishlist(productId);
        _wishlist.add(productId);
      }
    } catch (e) {
      _error = 'Erreur lors de la mise à jour de la liste de souhaits: $e';
    }
    notifyListeners();
  }

  bool isInWishlist(String productId) {
    return _wishlist.contains(productId);
  }

  // ===== COMMANDES =====
  
  Future<void> loadOrders() async {
    try {
      // Pour le moment, utiliser une liste vide pour éviter les problèmes de timeout
      // TODO: Réactiver le chargement depuis Supabase une fois les tables configurées
      _orders = [];
      print('✅ [DATA] Commandes simulées chargées (liste vide pour le moment)');
    } catch (e) {
      _error = 'Erreur lors du chargement des commandes: $e';
      _orders = [];
    }
    notifyListeners();
  }

  Future<SimpleOrder?> createOrder({
    required double total,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      final order = await SupabaseService.createOrder(
        items: _cartItems,
        total: total,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
      );
      
      if (order != null) {
        _orders.insert(0, order);
        await clearCart();
        notifyListeners();
      }
      
      return order;
    } catch (e) {
      _error = 'Erreur lors de la création de la commande: $e';
      return null;
    }
  }

  // ===== UTILITAIRES =====
  
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Calculs du panier
  double get cartSubtotal {
    return _cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  int get cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isCartEmpty => _cartItems.isEmpty;
}
