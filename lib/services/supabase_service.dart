import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce/config/supabase_config.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/models/cart.dart';
import 'package:ecommerce/models/user.dart';
import 'package:ecommerce/models/order.dart';
import 'package:ecommerce/models/chat.dart';
import 'package:ecommerce/models/subcategory.dart';
import 'package:ecommerce/models/user_role.dart';
import 'dart:io';


class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Getters pour l'authentification
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  static Session? getCurrentSession() => _supabase.auth.currentSession;

  // Initialisation de Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  // ===== PRODUITS =====
  
  /// Récupère tous les produits
  static Future<List<Product>> getProducts() async {
    try {
      print('📦 [SUPABASE] Récupération des produits');
      final response = await _supabase
          .from(SupabaseConfig.productsTable)
          .select('*')
          .order('created_at', ascending: false);
      
      final products = response.map((json) => Product.fromJson(json)).toList();
      print('✅ [SUPABASE] ${products.length} produits récupérés');
      return products;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des produits: $e');
      return [];
    }
  }

  /// Récupère les produits par catégorie
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.productsTable)
          .select('*')
          .eq('category', category)
          .order('created_at', ascending: false);
      
      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des produits par catégorie: $e');
      return [];
    }
  }

  /// Crée un nouveau produit
  static Future<bool> createProduct(Product product, {List<File>? imageFiles}) async {
    try {
      print('📦 [SUPABASE] Création du produit: ${product.name}');
      
      // Vérifier que l'utilisateur est authentifié
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return false;
      }
      
      List<String> imageUrls = [];
      
      // Upload des images si fournies
      if (imageFiles != null && imageFiles.isNotEmpty) {
        print('📤 [SUPABASE] Upload de ${imageFiles.length} images');
        imageUrls = await uploadProductImages(imageFiles, product.id);
        
        if (imageUrls.isEmpty) {
          print('❌ [SUPABASE] Échec de l\'upload des images');
          return false;
        }
      }
      
      // Préparer les données du produit
      final productData = {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'original_price': product.originalPrice,
        'image_url': imageUrls.isNotEmpty ? imageUrls.first : product.imageUrl,
        'images': imageUrls.isNotEmpty ? imageUrls : product.images,
        'category': product.category,
        'subcategory': product.subcategory,
        'brand': product.brand,
        'rating': product.rating,
        'review_count': product.reviewCount,
        'is_available': product.isAvailable,
        'stock_quantity': product.stockQuantity,
        'is_featured': product.isFeatured,
        'tags': product.tags,
        'specifications': product.specifications,
        'created_at': product.createdAt.toIso8601String(),
        'seller_id': product.sellerId ?? user.id,
        'seller_name': product.sellerName ?? 'Vendeur',
      };

      await _supabase
          .from(SupabaseConfig.productsTable)
          .insert(productData);
      
      print('✅ [SUPABASE] Produit créé avec succès');
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la création du produit: $e');
      return false;
    }
  }

  /// Récupère un produit par ID
  static Future<Product?> getProductById(String id) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.productsTable)
          .select('*')
          .eq('id', id)
          .single();
      
      return Product.fromJson(response);
    } catch (e) {
      print('Erreur lors de la récupération du produit: $e');
      return null;
    }
  }

  /// Recherche de produits
  static Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.productsTable)
          .select('*')
          .or('name.ilike.%$query%,description.ilike.%$query%,brand.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la recherche de produits: $e');
      return [];
    }
  }


  





  
  
  /// Upload plusieurs images vers Supabase Storage
  static Future<List<String>> uploadProductImages(List<File> imageFiles, String productId) async {
    List<String> uploadedUrls = [];
    
    try {
      print('📤 [SUPABASE] Upload de ${imageFiles.length} images pour le produit: $productId');
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return [];
      }
      
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        
        // Générer un nom de fichier unique
        final fileName = '${productId}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = 'products/$fileName';
        
        try {
          // Upload du fichier
          await _supabase.storage
              .from('product-images')
              .upload(filePath, imageFile);
          
          // Obtenir l'URL publique
          final imageUrl = _supabase.storage
              .from('product-images')
              .getPublicUrl(filePath);
          
          uploadedUrls.add(imageUrl);
          print('✅ [SUPABASE] Image ${i + 1} uploadée avec succès');
        } catch (e) {
          print('❌ [SUPABASE] Erreur lors de l\'upload de l\'image ${i + 1}: $e');
        }
      }
      
      print('✅ [SUPABASE] ${uploadedUrls.length}/${imageFiles.length} images uploadées avec succès');
      return uploadedUrls;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de l\'upload des images: $e');
      return uploadedUrls;
    }
  }



  /// Met à jour un produit existant
  static Future<bool> updateProduct(Product product, {List<File>? newImageFiles}) async {
    try {
      print('📦 [SUPABASE] Mise à jour du produit: ${product.name}');
      
      // Vérifier que l'utilisateur est authentifié
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return false;
      }
      
      List<String> imageUrls = [];
      
      // Upload des nouvelles images si fournies
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        print('📤 [SUPABASE] Upload de ${newImageFiles.length} nouvelles images');
        imageUrls = await uploadProductImages(newImageFiles, product.id);
        
        if (imageUrls.isEmpty) {
          print('❌ [SUPABASE] Échec de l\'upload des nouvelles images');
          return false;
        }
      }
      
      // Préparer les données de mise à jour
      final updateData = {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'original_price': product.originalPrice,
        'category': product.category,
        'subcategory': product.subcategory,
        'brand': product.brand,
        'rating': product.rating,
        'review_count': product.reviewCount,
        'is_available': product.isAvailable,
        'stock_quantity': product.stockQuantity,
        'is_featured': product.isFeatured,
        'tags': product.tags,
        'specifications': product.specifications,
        'updated_at': DateTime.now().toIso8601String(),
        'seller_id': product.sellerId ?? user.id,
        'seller_name': product.sellerName ?? 'Vendeur',
      };

      // Mettre à jour l'image principale si de nouvelles images ont été uploadées
      if (imageUrls.isNotEmpty) {
        updateData['image_url'] = imageUrls.first;
        updateData['images'] = imageUrls;
      }

      await _supabase
          .from(SupabaseConfig.productsTable)
          .update(updateData)
          .eq('id', product.id);
      
      print('✅ [SUPABASE] Produit mis à jour avec succès');
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la mise à jour du produit: $e');
      return false;
    }
  }

  /// Supprime un produit
  static Future<bool> deleteProduct(String productId) async {
    try {
      print('🗑️ [SUPABASE] Suppression du produit: $productId');
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return false;
      }
      
      // Vérifier que l'utilisateur est bien le propriétaire du produit
      final product = await _supabase
          .from(SupabaseConfig.productsTable)
          .select('seller_id')
          .eq('id', productId)
          .single();
      
      if (product['seller_id'] != user.id) {
        print('❌ [SUPABASE] L\'utilisateur n\'est pas le propriétaire du produit');
        return false;
      }
      
      // Supprimer le produit
      await _supabase
          .from(SupabaseConfig.productsTable)
          .delete()
          .eq('id', productId);
      
      print('✅ [SUPABASE] Produit supprimé avec succès');
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la suppression du produit: $e');
      return false;
    }
  }





  // ===== UTILISATEURS =====
  
  /// Crée un nouvel utilisateur
  static Future<AppUser?> createUser({
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      print('👤 [SUPABASE] Création du profil utilisateur pour: $email');
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié trouvé');
        return null;
      }

      print('📝 [SUPABASE] Insertion dans la table users avec ID: ${user.id}');
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .insert({
            'id': user.id,
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'phone_number': phoneNumber,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      print('✅ [SUPABASE] Profil utilisateur créé avec succès');
      return AppUser.fromJson(response);
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la création de l\'utilisateur: $e');
      return null;
    }
  }

  /// Crée un nouvel utilisateur avec un ID spécifique
  static Future<AppUser?> createUserWithId({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      print('👤 [SUPABASE] Création du profil utilisateur pour: $email avec ID: $userId');
      
      // Vérifier d'abord si l'utilisateur existe déjà
      try {
        final existingUser = await _supabase
            .from(SupabaseConfig.usersTable)
            .select('*')
            .eq('id', userId)
            .maybeSingle();
        
        if (existingUser != null) {
          print('ℹ️ [SUPABASE] Utilisateur existe déjà, retour de l\'utilisateur existant');
          return AppUser.fromJson(existingUser);
        }
      } catch (e) {
        print('ℹ️ [SUPABASE] Erreur lors de la vérification de l\'existence: $e');
      }
      
      print('📝 [SUPABASE] Insertion dans la table users avec ID: $userId');
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .insert({
            'id': userId,
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'phone_number': phoneNumber,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      print('✅ [SUPABASE] Profil utilisateur créé avec succès');
      return AppUser.fromJson(response);
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la création de l\'utilisateur: $e');
      
      // En cas d'erreur, essayer de récupérer l'utilisateur existant
      try {
        print('🔄 [SUPABASE] Tentative de récupération de l\'utilisateur existant...');
        final existingUser = await _supabase
            .from(SupabaseConfig.usersTable)
            .select('*')
            .eq('id', userId)
            .single();
        
        print('✅ [SUPABASE] Utilisateur récupéré avec succès');
        return AppUser.fromJson(existingUser);
      } catch (retryError) {
        print('❌ [SUPABASE] Impossible de récupérer l\'utilisateur: $retryError');
        return null;
      }
    }
  }

  /// Récupère les informations de l'utilisateur connecté
  static Future<AppUser?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      print('🔍 [SUPABASE] Recherche de l\'utilisateur avec ID: ${user.id}');
      
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('*')
          .eq('id', user.id)
          .maybeSingle();
      
      if (response == null) {
        print('⚠️ [SUPABASE] Utilisateur non trouvé dans la base de données, tentative de création...');
        
        // Essayer de créer l'utilisateur s'il n'existe pas
        try {
          final createdUser = await _supabase
              .from(SupabaseConfig.usersTable)
              .insert({
                'id': user.id,
                'email': user.email ?? '',
                'first_name': '',
                'last_name': '',
                'phone_number': null,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();
          
          print('✅ [SUPABASE] Utilisateur créé avec succès');
          return AppUser.fromJson(createdUser);
        } catch (createError) {
          print('❌ [SUPABASE] Erreur lors de la création automatique: $createError');
          return null;
        }
      }
      
      print('✅ [SUPABASE] Utilisateur trouvé');
      return AppUser.fromJson(response);
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  /// Met à jour les informations de l'utilisateur
  static Future<bool> updateUser(Map<String, dynamic> updates) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from(SupabaseConfig.usersTable)
          .update(updates)
          .eq('id', user.id);
      
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'utilisateur: $e');
      return false;
    }
  }

  // ===== PANIER =====
  
  /// Sauvegarde les éléments du panier
  static Future<bool> saveCartItems(List<CartItem> items) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Supprime les anciens éléments
      await _supabase
          .from(SupabaseConfig.cartItemsTable)
          .delete()
          .eq('user_id', user.id);

      // Ajoute les nouveaux éléments
      if (items.isNotEmpty) {
        final cartData = items.map((item) => {
          'user_id': user.id,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'created_at': DateTime.now().toIso8601String(),
        }).toList();

        await _supabase
            .from(SupabaseConfig.cartItemsTable)
            .insert(cartData);
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de la sauvegarde du panier: $e');
      return false;
    }
  }

  /// Récupère les éléments du panier
  static Future<List<CartItem>> getCartItems() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from(SupabaseConfig.cartItemsTable)
          .select('*, products(*)')
          .eq('user_id', user.id);

      return response.map((json) => CartItem(
        id: json['id'],
        product: Product.fromJson(json['products']),
        quantity: json['quantity'],
      )).toList();
    } catch (e) {
      print('Erreur lors de la récupération du panier: $e');
      return [];
    }
  }

  // ===== COMMANDES =====
  
  /// Crée une nouvelle commande
  static Future<SimpleOrder?> createOrder({
    required List<CartItem> items,
    required double total,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      print('📦 [SUPABASE] Création d\'une nouvelle commande');
      
      // Créer la commande dans Supabase
      final orderResponse = await _supabase
          .from(SupabaseConfig.ordersTable)
          .insert({
            'user_id': user.id,
            'total_amount': total,
            'shipping_address': shippingAddress,
            'payment_method': paymentMethod,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final order = SimpleOrder.fromJson(orderResponse);
      print('✅ [SUPABASE] Commande créée avec succès: ${order.id}');

      // Ajouter les éléments de la commande
      if (items.isNotEmpty) {
        final orderItems = items.map((item) => {
          'order_id': order.id,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        }).toList();

        await _supabase
            .from(SupabaseConfig.orderItemsTable)
            .insert(orderItems);
        
        print('✅ [SUPABASE] ${orderItems.length} éléments ajoutés à la commande');
      }
      
      // Envoyer une notification aux livreurs
      print('🚚 [DELIVERY] Notification envoyée aux livreurs pour la commande: ${order.id}');
      
      return order;
    } catch (e) {
      print('Erreur lors de la création de la commande: $e');
      return null;
    }
  }

  // Code original commenté pour le moment
      /*
      // Crée la commande
      final orderResponse = await _supabase
          .from(SupabaseConfig.ordersTable)
          .insert({
            'user_id': user.id,
            'total_amount': total,
            'shipping_address': shippingAddress,
            'payment_method': paymentMethod,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final order = SimpleOrder.fromJson(orderResponse);

      // Ajoute les éléments de la commande
      final orderItems = items.map((item) => {
        'order_id': order.id,
        'product_id': item.product.id,
        'quantity': item.quantity,
        'price': item.product.price,
      }).toList();

      await _supabase
          .from(SupabaseConfig.orderItemsTable)
          .insert(orderItems);

            return order;
      */
  

  /// Récupère l'historique des commandes
  static Future<List<SimpleOrder>> getOrders() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

            return response.map((json) => SimpleOrder.fromJson(json)).toList();
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des commandes: $e');
      return [];
    }
  }

  /// Récupère une commande spécifique par son ID
  static Future<SimpleOrder?> getOrderById(String orderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .eq('id', orderId)
          .eq('user_id', user.id)
          .single();

      return SimpleOrder.fromJson(response);
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération de la commande $orderId: $e');
      return null;
    }
  }

  /// Récupère une commande par son ID (pour les livreurs, sans restriction utilisateur)
  static Future<SimpleOrder?> getOrderByIdForDriver(String orderId) async {
    try {
      print('🔍 [SUPABASE] Récupération de la commande pour livreur: $orderId');
      
      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .eq('id', orderId)
          .single();

      final order = SimpleOrder.fromJson(response);
      print('✅ [SUPABASE] Commande trouvée: ${order.id.substring(0, 8)} - Statut: ${order.status}');
      
      return order;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération de la commande $orderId: $e');
      print('❌ [SUPABASE] Détails de l\'erreur: ${e.toString()}');
      return null;
    }
  }

  /// Confirme la livraison d'une commande (version simple)
  static Future<bool> confirmDeliverySimple(String orderId) async {
    try {
      print('🚚 [SUPABASE] Confirmation de livraison pour la commande: $orderId');
      
      // Vérifier d'abord si la commande existe et son statut actuel
      final currentOrder = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .eq('id', orderId)
          .maybeSingle();
      
      if (currentOrder == null) {
        print('❌ [SUPABASE] Commande non trouvée: $orderId');
        return false;
      }
      
      print('📋 [SUPABASE] Statut actuel de la commande: ${currentOrder['status']}');
      
      // Mettre à jour le statut
      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .update({
            'status': 'delivered',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select()
          .single();

      print('✅ [SUPABASE] Livraison confirmée pour la commande: $orderId');
      print('📋 [SUPABASE] Nouveau statut: ${response['status']}');
      
      // Envoyer une notification au client
      // TODO: Implémenter les notifications push
      print('📱 [NOTIFICATION] Notification envoyée au client pour la livraison confirmée');
      
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la confirmation de livraison: $e');
      print('❌ [SUPABASE] Détails de l\'erreur: ${e.toString()}');
      return false;
    }
  }

  /// Récupère les commandes livrées (pour l'historique des livreurs)
  static Future<List<SimpleOrder>> getDeliveredOrders() async {
    try {
      print('📋 [SUPABASE] Récupération des commandes livrées');
      
      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .eq('status', 'delivered')
          .order('updated_at', ascending: false)
          .limit(50); // Limiter à 50 commandes récentes

      final orders = response.map((json) => SimpleOrder.fromJson(json)).toList();
      print('✅ [SUPABASE] ${orders.length} commandes livrées récupérées');
      
      // Afficher les détails pour debug
      for (final order in orders) {
        print('📦 [SUPABASE] Commande livrée: ${order.id.substring(0, 8)} - ${order.status} - ${order.updatedAt}');
      }
      
      return orders;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des commandes livrées: $e');
      print('❌ [SUPABASE] Détails de l\'erreur: ${e.toString()}');
      return [];
    }
  }

  // ===== GESTION DES LIVREURS =====

  /// Récupère les commandes disponibles pour la livraison (statut 'pending' ou 'confirmed')
  static Future<List<SimpleOrder>> getAvailableOrders() async {
    try {
      print('🚚 [SUPABASE] Récupération des commandes disponibles pour livraison');
      
      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .inFilter('status', ['pending', 'confirmed'])
          .isFilter('driver_id', null) // Pas encore assignée à un livreur
          .order('created_at', ascending: true); // Plus anciennes en premier

      final orders = response.map((json) => SimpleOrder.fromJson(json)).toList();
      print('✅ [SUPABASE] ${orders.length} commandes disponibles récupérées');
      
      return orders;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des commandes disponibles: $e');
      return [];
    }
  }

  /// Récupère les commandes assignées au livreur actuel
  static Future<List<SimpleOrder>> getDriverOrders() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return [];
      }

      print('🚚 [SUPABASE] Récupération des commandes du livreur: ${user.email}');
      
      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .eq('driver_id', user.id)
          .inFilter('status', ['assigned', 'picked_up', 'in_transit'])
          .order('updated_at', ascending: false);

      final orders = response.map((json) => SimpleOrder.fromJson(json)).toList();
      print('✅ [SUPABASE] ${orders.length} commandes assignées au livreur');
      
      return orders;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des commandes du livreur: $e');
      return [];
    }
  }

  /// Assigne une commande à un livreur (récupération)
  static Future<bool> assignOrderToDriver(String orderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return false;
      }

      print('🚚 [SUPABASE] Tentative d\'assignation de la commande $orderId au livreur ${user.email}');
      
      // Vérifier d'abord si la commande est disponible
      final currentOrder = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .eq('id', orderId)
          .maybeSingle();
      
      if (currentOrder == null) {
        print('❌ [SUPABASE] Commande non trouvée: $orderId');
        return false;
      }

      if (currentOrder['driver_id'] != null) {
        print('❌ [SUPABASE] Commande déjà assignée à un autre livreur: ${currentOrder['driver_id']}');
        return false;
      }

      if (!['pending', 'confirmed'].contains(currentOrder['status'])) {
        print('❌ [SUPABASE] Commande non disponible pour livraison. Statut: ${currentOrder['status']}');
        return false;
      }

      // Assigner la commande au livreur
      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .update({
            'driver_id': user.id,
            'status': 'assigned',
            'assigned_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select()
          .single();

      print('✅ [SUPABASE] Commande $orderId assignée au livreur ${user.email}');
      print('📋 [SUPABASE] Nouveau statut: ${response['status']}');
      
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de l\'assignation de la commande: $e');
      return false;
    }
  }

  /// Marque une commande comme "récupérée" par le livreur
  static Future<bool> markOrderAsPickedUp(String orderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return false;
      }

      print('📦 [SUPABASE] Marquage de la commande $orderId comme récupérée');
      
      // Vérifier que la commande est bien assignée à ce livreur
      final currentOrder = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .eq('id', orderId)
          .eq('driver_id', user.id)
          .maybeSingle();
      
      if (currentOrder == null) {
        print('❌ [SUPABASE] Commande non trouvée ou non assignée à ce livreur: $orderId');
        return false;
      }

      if (currentOrder['status'] != 'assigned') {
        print('❌ [SUPABASE] Commande non prête pour récupération. Statut: ${currentOrder['status']}');
        return false;
      }

      // Marquer comme récupérée
      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .update({
            'status': 'picked_up',
            'picked_up_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('driver_id', user.id)
          .select()
          .single();

      print('✅ [SUPABASE] Commande $orderId marquée comme récupérée');
      print('📋 [SUPABASE] Nouveau statut: ${response['status']}');
      
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors du marquage de récupération: $e');
      return false;
    }
  }

  /// Annule l'assignation d'une commande (le livreur renonce)
  static Future<bool> cancelOrderAssignment(String orderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return false;
      }

      print('❌ [SUPABASE] Annulation de l\'assignation de la commande $orderId');
      
      // Vérifier que la commande est bien assignée à ce livreur
      final currentOrder = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .eq('id', orderId)
          .eq('driver_id', user.id)
          .maybeSingle();
      
      if (currentOrder == null) {
        print('❌ [SUPABASE] Commande non trouvée ou non assignée à ce livreur: $orderId');
        return false;
      }

      // Annuler l'assignation
      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .update({
            'driver_id': null,
            'status': 'confirmed', // Retour au statut précédent
            'assigned_at': null,
            'picked_up_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('driver_id', user.id)
          .select()
          .single();

      print('✅ [SUPABASE] Assignation de la commande $orderId annulée');
      print('📋 [SUPABASE] Nouveau statut: ${response['status']}');
      
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de l\'annulation de l\'assignation: $e');
      return false;
    }
  }

  /// Met à jour le rôle d'un utilisateur
  static Future<bool> updateUserRole(String userId, UserRole role) async {
    try {
      print('🎭 [SUPABASE] Mise à jour du rôle pour l\'utilisateur: $userId');
      
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .update({
            'role': role.databaseValue,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      print('✅ [SUPABASE] Rôle mis à jour: ${response['role']}');
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la mise à jour du rôle: $e');
      return false;
    }
  }

  /// Confirme la livraison d'une commande (version améliorée)
  static Future<bool> confirmDelivery(String orderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return false;
      }

      print('🚚 [SUPABASE] Confirmation de livraison pour la commande: $orderId');
      
      // Vérifier que la commande est bien assignée à ce livreur et prête pour livraison
      final currentOrder = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select('*')
          .eq('id', orderId)
          .eq('driver_id', user.id)
          .maybeSingle();
      
      if (currentOrder == null) {
        print('❌ [SUPABASE] Commande non trouvée ou non assignée à ce livreur: $orderId');
        return false;
      }
      
      if (!['picked_up', 'in_transit'].contains(currentOrder['status'])) {
        print('❌ [SUPABASE] Commande non prête pour livraison. Statut: ${currentOrder['status']}');
        return false;
      }
      
      print('📋 [SUPABASE] Statut actuel de la commande: ${currentOrder['status']}');
      
      // Mettre à jour le statut
      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .update({
            'status': 'delivered',
            'delivered_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('driver_id', user.id)
          .select()
          .single();

      print('✅ [SUPABASE] Livraison confirmée pour la commande: $orderId');
      print('📋 [SUPABASE] Nouveau statut: ${response['status']}');
      
      // Envoyer une notification au client
      // TODO: Implémenter les notifications push
      print('📱 [NOTIFICATION] Notification envoyée au client pour la livraison confirmée');
      
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la confirmation de livraison: $e');
      print('❌ [SUPABASE] Détails de l\'erreur: ${e.toString()}');
      return false;
    }
  }



  // ===== LISTE DE SOUHAITS =====
  
  /// Ajoute un produit à la liste de souhaits
  static Future<bool> addToWishlist(String productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from(SupabaseConfig.wishlistTable)
          .insert({
            'user_id': user.id,
            'product_id': productId,
            'created_at': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout à la liste de souhaits: $e');
      return false;
    }
  }

  /// Supprime un produit de la liste de souhaits
  static Future<bool> removeFromWishlist(String productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from(SupabaseConfig.wishlistTable)
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);
      
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la liste de souhaits: $e');
      return false;
    }
  }

  /// Récupère la liste de souhaits
  static Future<List<String>> getWishlist() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from(SupabaseConfig.wishlistTable)
          .select('product_id')
          .eq('user_id', user.id);
      
      return response.map((json) => json['product_id'] as String).toList();
    } catch (e) {
      print('Erreur lors de la récupération de la liste de souhaits: $e');
      return [];
    }
  }

  // ===== CATÉGORIES =====
  
  /// Récupère toutes les catégories
  static Future<List<ProductCategory>> getCategories() async {
    try {
      print('📂 [SUPABASE] Récupération des catégories');
      final response = await _supabase
          .from(SupabaseConfig.categoriesTable)
          .select('*')
          .order('name');
      
      final categories = response.map((json) => ProductCategory.fromJson(json)).toList();
      print('✅ [SUPABASE] ${categories.length} catégories récupérées');
      return categories;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  // ===== AUTHENTIFICATION =====
  
  /// Connexion avec email et mot de passe
  static Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      return null;
    }
  }

  /// Déconnexion
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  /// Rafraîchit la session
  static Future<bool> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response.session != null;
    } catch (e) {
      print('Erreur lors du rafraîchissement de session: $e');
      return false;
    }
  }

  /// Vérifie si l'utilisateur est connecté
  static bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Renvoie un email de confirmation
  static Future<bool> resendConfirmationEmail(String email) async {
    try {
      print('📧 [SUPABASE] Renvoi d\'email de confirmation pour: $email');
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      print('✅ [SUPABASE] Email de confirmation renvoyé');
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors du renvoi d\'email: $e');
      return false;
    }
  }

  /// Inscription avec email et mot de passe (sans vérification)
  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [SUPABASE] Tentative d\'inscription pour: $email');
      
      // Créer l'utilisateur avec signUp
      final signUpResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (signUpResponse.user == null) {
        print('❌ [SUPABASE] Échec de la création de l\'utilisateur');
        return null;
      }
      
      print('✅ [SUPABASE] Utilisateur créé avec succès');
      return signUpResponse;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de l\'inscription: $e');
      return null;
    }
  }




  






  

  /// Vérifie le token de confirmation reçu par email
  static Future<AuthResponse?> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      print('🔐 [SUPABASE] Vérification du token de confirmation pour: $email');
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup, // Utiliser signup pour la confirmation d'inscription
      );
      print('✅ [SUPABASE] Token de confirmation vérifié avec succès');
      return response;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la vérification du token: $e');
      return null;
    }
  }

  // ===== CHAT =====

  /// Crée un nouveau chat ou récupère un chat existant
  static Future<Chat?> createChat({
    required String customerId,
    required String customerName,
    required String sellerId,
    required String sellerName,
    required String productId,
    required String productName,
    required String productImageUrl,
  }) async {
    try {
      print('💬 [SUPABASE] Vérification d\'un chat existant pour le produit: $productId');
      
      // Vérifier s'il existe déjà un chat pour ce produit entre ce client et ce vendeur
      print('🔍 [SUPABASE] Recherche d\'un chat existant pour le produit $productId entre client $customerId et vendeur $sellerId');
      
      // Rechercher un chat existant où ce client et ce vendeur discutent de ce produit
      final existingChats = await _supabase
          .from('chats')
          .select('*')
          .eq('product_id', productId)
          .or('customer_id.eq.$customerId,seller_id.eq.$customerId')
          .or('customer_id.eq.$sellerId,seller_id.eq.$sellerId');
      
      print('🔍 [SUPABASE] ${existingChats.length} chats trouvés pour ce produit impliquant ces utilisateurs');
      
      if (existingChats.isNotEmpty) {
        // Afficher tous les chats pour debug
        for (final chatData in existingChats) {
          print('🔍 [SUPABASE] Chat trouvé: ${chatData['id']} - customer: ${chatData['customer_id']}, seller: ${chatData['seller_id']}');
        }
        
        // Trouver le chat où ce client et ce vendeur discutent de ce produit
        for (final chatData in existingChats) {
          final chat = Chat.fromJson(chatData);
          // Vérifier que ce chat implique exactement ce client et ce vendeur
          if ((chat.customerId == customerId && chat.sellerId == sellerId) ||
              (chat.customerId == sellerId && chat.sellerId == customerId)) {
            print('✅ [SUPABASE] Chat existant trouvé: ${chat.id}');
            return chat;
          }
        }
      }
      
      print('💬 [SUPABASE] Aucun chat existant trouvé, création d\'un nouveau chat');
      
      final chatId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      
      final chatData = {
        'id': chatId,
        'customer_id': customerId,
        'customer_name': customerName,
        'seller_id': sellerId,
        'seller_name': sellerName,
        'product_id': productId,
        'product_name': productName,
        'product_image_url': productImageUrl,
        'created_at': now.toIso8601String(),
        'last_message_at': now.toIso8601String(),
        'is_active': true,
        'unread_count': 0,
        'status': 'active',
      };

      await _supabase
          .from('chats')
          .insert(chatData);
      
      print('✅ [SUPABASE] Nouveau chat créé avec succès');
      
      // Envoyer un message automatique de démarrage pour les nouveaux chats
      await _sendWelcomeMessage(chatId, customerId, customerName, productName);
      
      return Chat.fromJson(chatData);
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la création/récupération du chat: $e');
      return null;
    }
  }

  /// Envoie un message de bienvenue automatique
  static Future<void> _sendWelcomeMessage(
    String chatId, 
    String customerId, 
    String customerName, 
    String productName
  ) async {
    try {
      final welcomeMessages = [
        "Bonjour ! Je suis intéressé par votre produit \"$productName\". Est-il encore disponible ?",
        "Salut ! J'aimerais en savoir plus sur \"$productName\". Pouvez-vous me donner plus d'informations ?",
        "Bonjour ! Votre produit \"$productName\" m'intéresse. Quel est le prix final ?",
        "Salut ! J'ai vu votre annonce pour \"$productName\". Est-ce qu'on peut discuter des détails ?",
        "Bonjour ! Votre produit \"$productName\" correspond à ce que je cherche. Est-il en bon état ?",
      ];
      
      final randomMessage = welcomeMessages[DateTime.now().millisecondsSinceEpoch % welcomeMessages.length];
      
      await sendMessage(
        chatId: chatId,
        senderId: customerId,
        senderName: customerName,
        senderType: 'customer',
        message: randomMessage,
        type: MessageType.text,
      );
      
      print('✅ [SUPABASE] Message de bienvenue envoyé automatiquement');
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de l\'envoi du message de bienvenue: $e');
    }
  }

  /// Récupère les chats de l'utilisateur
  static Future<List<Chat>> getUserChats(String userId) async {
    try {
      print('💬 [SUPABASE] Récupération des chats pour l\'utilisateur: $userId');
      
      final response = await _supabase
          .from('chats')
          .select('*')
          .or('customer_id.eq.$userId,seller_id.eq.$userId')
          .order('last_message_at', ascending: false);
      
      final chats = response.map((json) => Chat.fromJson(json)).toList();
      print('✅ [SUPABASE] ${chats.length} chats récupérés');
      return chats;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des chats: $e');
      return [];
    }
  }

  /// Récupère les messages d'un chat
  static Future<List<ChatMessage>> getChatMessages(String chatId) async {
    try {
      print('💬 [SUPABASE] Récupération des messages pour le chat: $chatId');
      
      final response = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('chat_id', chatId)
          .order('timestamp', ascending: true);
      
      final messages = response.map((json) => ChatMessage.fromJson(json)).toList();
      print('✅ [SUPABASE] ${messages.length} messages récupérés');
      return messages;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des messages: $e');
      return [];
    }
  }

  /// Envoie un message
  static Future<ChatMessage?> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
    String? imageUrl,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    String? replyToMessageText,
  }) async {
    try {
      print('💬 [SUPABASE] Envoi d\'un message dans le chat: $chatId');
      print('🔍 [SUPABASE] Détails du message - sender_id: $senderId, sender_name: $senderName, message: $message');
      
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      
      final messageData = {
        'id': messageId,
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_type': senderType,
        'message': message,
        'image_url': imageUrl,
        'timestamp': now.toIso8601String(),
        'is_read': false,
        'type': type.toString().split('.').last,
        'reply_to_message_id': replyToMessageId,
        'reply_to_message_text': replyToMessageText,
      };

      print('🔍 [SUPABASE] Données du message à insérer: $messageData');

      final insertedMessage = await _supabase
          .from('chat_messages')
          .insert(messageData)
          .select()
          .single();

      print('🔍 [SUPABASE] Message inséré avec succès: $insertedMessage');

      // Mettre à jour le timestamp du dernier message dans le chat
      await _supabase
          .from('chats')
          .update({'last_message_at': now.toIso8601String()})
          .eq('id', chatId);
      
      print('✅ [SUPABASE] Message envoyé avec succès');
      return ChatMessage.fromJson(insertedMessage);
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de l\'envoi du message: $e');
      return null;
    }
  }

  /// Marque les messages comme lus
  static Future<bool> markMessagesAsRead(String chatId, String userId) async {
    try {
      print('💬 [SUPABASE] Marquage des messages comme lus pour le chat: $chatId');
      
      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', userId);

      // Mettre à jour le compteur de messages non lus
      await _supabase
          .from('chats')
          .update({'unread_count': 0})
          .eq('id', chatId);
      
      print('✅ [SUPABASE] Messages marqués comme lus');
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors du marquage des messages: $e');
      return false;
    }
  }

  /// S'abonne aux messages d'un chat en temps réel
  static Stream<List<ChatMessage>> subscribeToChatMessages(String chatId) {
    try {
      print('📡 [SUPABASE] Abonnement aux messages en temps réel pour le chat: $chatId');
      
      return _supabase
          .from('chat_messages')
          .stream(primaryKey: ['id'])
          .eq('chat_id', chatId)
          .order('timestamp', ascending: true)
          .map((response) {
            final messages = response.map((json) => ChatMessage.fromJson(json)).toList();
            print('📨 [SUPABASE] ${messages.length} messages reçus en temps réel');
            return messages;
          });
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de l\'abonnement aux messages: $e');
      return Stream.value([]);
    }
  }

  /// Génère une URL d'image par défaut pour une catégorie
  static String getDefaultImageUrl(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return 'https://via.placeholder.com/400x400/2196F3/FFFFFF?text=Électronique';
      case 'fashion':
        return 'https://via.placeholder.com/400x400/E91E63/FFFFFF?text=Mode';
      case 'home':
        return 'https://via.placeholder.com/400x400/4CAF50/FFFFFF?text=Maison';
      case 'sports':
        return 'https://via.placeholder.com/400x400/FF9800/FFFFFF?text=Sports';
      case 'beauty':
        return 'https://via.placeholder.com/400x400/9C27B0/FFFFFF?text=Beauté';
      case 'books':
        return 'https://via.placeholder.com/400x400/795548/FFFFFF?text=Livres';
      default:
        return 'https://via.placeholder.com/400x400/CCCCCC/666666?text=Produit';
    }
  }

  // ===== SOUS-CATÉGORIES =====
  
  /// Récupère toutes les sous-catégories pour une catégorie donnée
  static Future<List<Subcategory>> getSubcategories(String categoryId) async {
    try {
      print('📂 [SUPABASE] Récupération des sous-catégories pour la catégorie: $categoryId');
      
      final response = await _supabase
          .from('subcategories')
          .select('*')
          .eq('category_id', categoryId)
          .order('name');
      
      final subcategories = response.map((json) => Subcategory.fromJson(json)).toList();
      print('✅ [SUPABASE] ${subcategories.length} sous-catégories récupérées');
      return subcategories;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des sous-catégories: $e');
      return [];
    }
  }

  /// Crée une nouvelle sous-catégorie
  static Future<Subcategory?> createSubcategory(String name, String categoryId) async {
    try {
      print('📝 [SUPABASE] Création de la sous-catégorie: $name pour la catégorie: $categoryId');
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return null;
      }
      
      final response = await _supabase
          .from('subcategories')
          .insert({
            'name': name.trim(),
            'category_id': categoryId,
            'created_by': user.id,
          })
          .select()
          .single();
      
      final subcategory = Subcategory.fromJson(response);
      print('✅ [SUPABASE] Sous-catégorie créée avec succès: ${subcategory.id}');
      return subcategory;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la création de la sous-catégorie: $e');
      return null;
    }
  }

  /// Vérifie si une sous-catégorie existe déjà
  static Future<bool> subcategoryExists(String name, String categoryId) async {
    try {
      final response = await _supabase
          .from('subcategories')
          .select('id')
          .eq('name', name.trim())
          .eq('category_id', categoryId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Récupère les produits de l'utilisateur connecté
  static Future<List<Product>> getMyProducts() async {
    try {
      print('📦 [SUPABASE] Récupération des produits de l\'utilisateur');
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [SUPABASE] Aucun utilisateur authentifié');
        return [];
      }
      
      print('🔍 [SUPABASE] Recherche des produits pour l\'utilisateur: ${user.id}');
      
      // Filtrer les produits par seller_id (propriétaire du produit)
      final response = await _supabase
          .from(SupabaseConfig.productsTable)
          .select('*')
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);
      
      final products = response.map((json) => Product.fromJson(json)).toList();
      print('✅ [SUPABASE] ${products.length} produits récupérés pour l\'utilisateur');
      return products;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération des produits: $e');
      return [];
    }
  }

  /// S'assure qu'un utilisateur existe dans la table users
  static Future<bool> ensureUserExists(String userId, String email, String firstName, String lastName) async {
    try {
      print('👤 [SUPABASE] Vérification de l\'existence de l\'utilisateur: $userId');
      
      // Vérifier si l'ID est un UUID valide
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      if (!uuidRegex.hasMatch(userId)) {
        print('⚠️ [SUPABASE] ID invalide: $userId');
        return false;
      }
      
      // Vérifier si l'utilisateur existe déjà dans la table users
      final existingUser = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (existingUser != null) {
        print('✅ [SUPABASE] Utilisateur existe déjà dans users: $userId');
        return true;
      }
      
      // Vérifier si l'utilisateur existe dans auth.users
      try {
        final authUser = await _supabase.auth.admin.getUserById(userId);
        if (authUser.user != null) {
          print('✅ [SUPABASE] Utilisateur existe dans auth.users, création dans users: $userId');
          
          // Créer l'utilisateur dans la table users
          await _supabase
              .from(SupabaseConfig.usersTable)
              .insert({
                'id': userId,
                'email': authUser.user!.email ?? email,
                'first_name': firstName,
                'last_name': lastName,
                'created_at': DateTime.now().toIso8601String(),
              });
          
          print('✅ [SUPABASE] Utilisateur créé avec succès: $userId');
          return true;
        }
      } catch (authError) {
        print('⚠️ [SUPABASE] Utilisateur n\'existe pas dans auth.users: $userId');
        return false;
      }
      
      return false;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la vérification/création de l\'utilisateur: $e');
      return false;
    }
  }

  /// Récupère le nom complet d'un utilisateur
  static Future<String?> getUserFullName(String userId) async {
    try {
      print('🔍 [SUPABASE] Récupération du nom pour l\'utilisateur: $userId');
      
      // Vérifier si l'ID est un UUID valide
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      if (!uuidRegex.hasMatch(userId)) {
        print('⚠️ [SUPABASE] ID invalide, impossible de récupérer le nom: $userId');
        return null;
      }
      
      // Essayer de récupérer depuis la table users
      final userData = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('first_name, last_name')
          .eq('id', userId)
          .maybeSingle();
      
      if (userData != null && userData['first_name'] != null && userData['last_name'] != null) {
        final fullName = '${userData['first_name']} ${userData['last_name']}';
        print('✅ [SUPABASE] Nom trouvé dans users: $fullName');
        return fullName;
      }
      
      // Si pas trouvé dans users, essayer de récupérer depuis auth.users
      try {
        final authUser = await _supabase.auth.admin.getUserById(userId);
        if (authUser.user != null) {
          final email = authUser.user!.email ?? '';
          final name = email.split('@').first; // Utiliser la partie avant @ de l'email
          print('✅ [SUPABASE] Nom trouvé dans auth.users: $name');
          return name;
        }
      } catch (authError) {
        print('⚠️ [SUPABASE] Utilisateur n\'existe pas dans auth.users: $userId');
      }
      
      print('⚠️ [SUPABASE] Utilisateur non trouvé: $userId');
      return null;
    } catch (e) {
      print('❌ [SUPABASE] Erreur lors de la récupération du nom: $e');
      return null;
    }
  }

  /// Envoie une notification de livraison aux livreurs
  static void _sendDeliveryNotification(SimpleOrder order) {
    // Dans une vraie application, cela utiliserait Firebase Cloud Messaging
    // ou un autre service de notifications push
    print('🚚 [DELIVERY] Notification envoyée pour la commande #${order.id.substring(0, 8)}');
    print('📍 [DELIVERY] Adresse de livraison: ${order.shippingAddress}');
    print('💰 [DELIVERY] Montant: ${order.totalAmount.toStringAsFixed(2)} €');
    
    // TODO: Intégrer avec le service de notifications
    // DeliveryNotificationService().sendDeliveryNotification(order);
  }

}
