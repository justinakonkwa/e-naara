import 'package:flutter/foundation.dart';
import 'package:ecommerce/services/auth_service.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/models/cart.dart';
import 'package:ecommerce/models/order.dart';
import 'package:ecommerce/models/chat.dart';
import 'dart:io';
import 'dart:async';

/// Service de gestion d'état global de l'application
/// Centralise la logique métier et coordonne les différents services
class AppState extends ChangeNotifier {
  final AuthService _authService;
  final DataService _dataService;

  AppState(this._authService, this._dataService) {
    // Écouter les changements des services
    _authService.addListener(_onAuthChanged);
    _dataService.addListener(_onDataChanged);
  }

  // ===== ÉTATS GLOBAUX =====
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  // ===== ÉTATS DÉRIVÉS =====
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isUserLoading => _authService.isLoading;
  bool get isDataLoading => _dataService.isLoading;
  
  // Utilisateur
  get currentUser => _authService.currentUser;
  
  // Produits
  List<Product> get products => _dataService.products;
  List<Product> get featuredProducts => _dataService.featuredProducts;
  List<Product> get recentProducts => _dataService.recentProducts;
  
  // Panier
  List<CartItem> get cartItems => _dataService.cartItems;
  int get cartItemCount => _dataService.cartItemCount;
  double get cartSubtotal => _dataService.cartSubtotal;
  bool get isCartEmpty => _dataService.isCartEmpty;
  
  // Catégories
  get categories => _dataService.categories;
  
  // Liste de souhaits
  List<String> get wishlist => _dataService.wishlist;
  
  // Commandes
  List<SimpleOrder> get orders => _dataService.orders;

  // ===== INITIALISATION =====
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      _clearMessages();
      
      // Initialiser les données de base
      await Future.wait([
        _dataService.loadProducts(),
        _dataService.loadCategories(),
      ]);
      
      // Si l'utilisateur est connecté, charger ses données
      if (isAuthenticated) {
        await _loadUserData();
      }
      
      _isInitialized = true;
      _setSuccessMessage('Application initialisée avec succès');
    } catch (e) {
      _setError('Erreur lors de l\'initialisation: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      await Future.wait([
        _dataService.loadCartItems(),
        _dataService.loadWishlist(),
        _dataService.loadOrders(),
      ]);
    } catch (e) {
      _setError('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  // ===== GESTION DES PRODUITS =====
  
  Future<void> refreshProducts() async {
    try {
      _setLoading(true);
      await _dataService.loadProducts();
      _setSuccessMessage('Produits actualisés');
    } catch (e) {
      _setError('Erreur lors de l\'actualisation des produits: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      return await _dataService.searchProducts(query);
    } catch (e) {
      _setError('Erreur lors de la recherche: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      return await _dataService.getProductsByCategory(category);
    } catch (e) {
      _setError('Erreur lors du chargement des produits par catégorie: $e');
      return [];
    }
  }

  // ===== GESTION DU PANIER =====
  
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    try {
      await _dataService.addToCart(product, quantity: quantity);
      _setSuccessMessage('${product.name} ajouté au panier');
    } catch (e) {
      _setError('Erreur lors de l\'ajout au panier: $e');
    }
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      await _dataService.removeFromCart(itemId);
      _setSuccessMessage('Produit retiré du panier');
    } catch (e) {
      _setError('Erreur lors de la suppression du panier: $e');
    }
  }

  Future<void> updateCartItemQuantity(String itemId, int quantity) async {
    try {
      await _dataService.updateCartItemQuantity(itemId, quantity);
    } catch (e) {
      _setError('Erreur lors de la mise à jour de la quantité: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      await _dataService.clearCart();
      _setSuccessMessage('Panier vidé');
    } catch (e) {
      _setError('Erreur lors du vidage du panier: $e');
    }
  }

  // ===== GESTION DE LA LISTE DE SOUHAITS =====
  
  Future<void> toggleWishlist(String productId) async {
    try {
      await _dataService.toggleWishlist(productId);
      final isInWishlist = _dataService.isInWishlist(productId);
      _setSuccessMessage(isInWishlist 
        ? 'Produit ajouté à la liste de souhaits' 
        : 'Produit retiré de la liste de souhaits');
    } catch (e) {
      _setError('Erreur lors de la mise à jour de la liste de souhaits: $e');
    }
  }

  bool isInWishlist(String productId) {
    return _dataService.isInWishlist(productId);
  }

  // ===== GESTION DES COMMANDES =====
  
  Future<SimpleOrder?> createOrder({
    required double total,
    required String shippingAddress,
    required String paymentMethod,
    double? shippingLatitude,
    double? shippingLongitude,
  }) async {
    try {
      _setLoading(true);
      final order = await _dataService.createOrder(
        total: total,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        shippingLatitude: shippingLatitude,
        shippingLongitude: shippingLongitude,
      );
      
      if (order != null) {
        _setSuccessMessage('Commande créée avec succès');
      }
      
      return order;
    } catch (e) {
      _setError('Erreur lors de la création de la commande: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshOrders() async {
    try {
      await _dataService.loadOrders();
    } catch (e) {
      _setError('Erreur lors du chargement des commandes: $e');
    }
  }

  // ===== CHAT =====

  Future<List<Chat>> getUserChats() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return [];
      
      return await SupabaseService.getUserChats(user.id);
    } catch (e) {
      _setError('Erreur lors du chargement des chats: $e');
      return [];
    }
  }

  Future<List<ChatMessage>> getChatMessages(String chatId) async {
    try {
      return await SupabaseService.getChatMessages(chatId);
    } catch (e) {
      _setError('Erreur lors du chargement des messages: $e');
      return [];
    }
  }

  Future<ChatMessage?> sendChatMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
    String? replyToMessageId,
    String? replyToMessageText,
  }) async {
    try {
      return await SupabaseService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        message: message,
        replyToMessageId: replyToMessageId,
        replyToMessageText: replyToMessageText,
      );
    } catch (e) {
      _setError('Erreur lors de l\'envoi du message: $e');
      return null;
    }
  }

  Future<ChatMessage?> sendChatMessageWithImage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required File imageFile,
  }) async {
    try {
      // Upload de l'image
      final imageUrls = await SupabaseService.uploadProductImages([imageFile], chatId);
      if (imageUrls.isEmpty) {
        _setError('Erreur lors de l\'upload de l\'image');
        return null;
      }

      return await SupabaseService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        message: 'Image',
        imageUrl: imageUrls.first,
        type: MessageType.image,
      );
    } catch (e) {
      _setError('Erreur lors de l\'envoi de l\'image: $e');
      return null;
    }
  }

  Future<bool> markChatMessagesAsRead(String chatId, String userId) async {
    try {
      return await SupabaseService.markMessagesAsRead(chatId, userId);
    } catch (e) {
      _setError('Erreur lors du marquage des messages: $e');
      return false;
    }
  }

  Future<Chat?> createChat({
    required String customerId,
    required String customerName,
    required String sellerId,
    required String sellerName,
    required String productId,
    required String productName,
    required String productImageUrl,
  }) async {
    try {
      return await SupabaseService.createChat(
        customerId: customerId,
        customerName: customerName,
        sellerId: sellerId,
        sellerName: sellerName,
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
      );
    } catch (e) {
      _setError('Erreur lors de la création du chat: $e');
      return null;
    }
    }

  Stream<List<ChatMessage>> subscribeToChatMessages(String chatId) {
    try {
      return SupabaseService.subscribeToChatMessages(chatId);
    } catch (e) {
      _setError('Erreur lors de l\'abonnement aux messages: $e');
      return Stream.value([]);
    }
  }

  // ===== GESTION DES MESSAGES =====
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    _error = null;
    notifyListeners();
  }

  void _clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  // ===== ÉCOUTEURS =====
  
  void _onAuthChanged() {
    if (isAuthenticated) {
      _loadUserData();
    }
    notifyListeners();
  }

  void _onDataChanged() {
    notifyListeners();
  }

  // ===== NETTOYAGE =====
  
  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }
}
