import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce/models/product.dart';

class RecommendationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Sauvegarde une recherche dans l'historique
  static Future<void> saveSearchHistory(String query, int resultCount) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('search_history').insert({
        'user_id': user.id,
        'query': query,
        'result_count': resultCount,
      });
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'historique de recherche: $e');
    }
  }

  /// Récupère l'historique de recherche de l'utilisateur
  static Future<List<Map<String, dynamic>>> getSearchHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('search_history')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  /// Supprime un élément de l'historique de recherche
  static Future<void> deleteSearchHistory(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('search_history')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      print('Erreur lors de la suppression de l\'historique: $e');
    }
  }

  /// Enregistre une consultation de produit
  static Future<void> recordProductView(String productId, {int duration = 0}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('product_views').insert({
        'user_id': user.id,
        'product_id': productId,
        'view_duration': duration,
      });
    } catch (e) {
      print('Erreur lors de l\'enregistrement de la consultation: $e');
    }
  }

  /// Récupère les produits recommandés basés sur l'historique
  static Future<List<Product>> getRecommendedProducts({int limit = 10}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Récupérer les recommandations de la base de données
      final response = await _supabase
          .from('product_recommendations')
          .select('''
            recommended_product_id,
            score,
            reason,
            products!product_recommendations_recommended_product_id_fkey(*)
          ''')
          .eq('user_id', user.id)
          .order('score', ascending: false)
          .limit(limit);

      if (response.isEmpty) {
        // Si pas de recommandations, générer des recommandations basées sur l'historique
        return await _generateRecommendations(limit);
      }

      return response.map((item) => Product.fromJson(item['products'])).toList();
    } catch (e) {
      print('Erreur lors de la récupération des recommandations: $e');
      return await _generateRecommendations(limit);
    }
  }

  /// Génère des recommandations basées sur l'historique d'achat et de consultation
  static Future<List<Product>> _generateRecommendations(int limit) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Récupérer les catégories et marques préférées de l'utilisateur
      final viewHistory = await _supabase
          .from('product_views')
          .select('product_id')
          .eq('user_id', user.id)
          .order('viewed_at', ascending: false)
          .limit(50);

      if (viewHistory.isEmpty) {
        // Si pas d'historique, retourner des produits populaires
        return await _getPopularProducts(limit);
      }

      final productIds = viewHistory.map((item) => item['product_id'] as String).toList();
      
      // Récupérer les produits consultés pour analyser les préférences
      final products = await _supabase
          .from('products')
          .select('*')
          .inFilter('id', productIds);

      if (products.isEmpty) return await _getPopularProducts(limit);

      // Analyser les préférences
      final categories = <String, int>{};
      final brands = <String, int>{};

      for (final product in products) {
        categories[product['category'] as String] = (categories[product['category'] as String] ?? 0) + 1;
        brands[product['brand'] as String] = (brands[product['brand'] as String] ?? 0) + 1;
      }

      // Trouver les catégories et marques préférées
      final preferredCategories = categories.entries
          .where((e) => e.value > 1)
          .map((e) => e.key)
          .toList();

      final preferredBrands = brands.entries
          .where((e) => e.value > 1)
          .map((e) => e.key)
          .toList();

      // Récupérer des produits similaires
      List<Product> recommendations = [];

      if (preferredCategories.isNotEmpty) {
        final categoryProducts = await _supabase
            .from('products')
            .select('*')
            .inFilter('category', preferredCategories)
            .not('id', 'in', productIds)
            .limit(limit ~/ 2);

        recommendations.addAll(
          categoryProducts.map((p) => Product.fromJson(p)).toList()
        );
      }

      if (preferredBrands.isNotEmpty && recommendations.length < limit) {
        final brandProducts = await _supabase
            .from('products')
            .select('*')
            .inFilter('brand', preferredBrands)
            .not('id', 'in', productIds)
            .limit(limit - recommendations.length);

        recommendations.addAll(
          brandProducts.map((p) => Product.fromJson(p)).toList()
        );
      }

      // Si pas assez de recommandations, ajouter des produits populaires
      if (recommendations.length < limit) {
        final popularProducts = await _getPopularProducts(limit - recommendations.length);
        recommendations.addAll(popularProducts);
      }

      return recommendations.take(limit).toList();
    } catch (e) {
      print('Erreur lors de la génération des recommandations: $e');
      return await _getPopularProducts(limit);
    }
  }

  /// Récupère les produits populaires
  static Future<List<Product>> _getPopularProducts(int limit) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .order('rating', ascending: false)
          .limit(limit);

      return response.map((p) => Product.fromJson(p)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des produits populaires: $e');
      return [];
    }
  }

  /// Récupère les produits similaires à un produit donné
  static Future<List<Product>> getSimilarProducts(Product product, {int limit = 6}) async {
    try {
      // Rechercher des produits de la même catégorie et marque
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('category', product.category)
          .eq('brand', product.brand)
          .neq('id', product.id)
          .limit(limit);

      List<Product> similarProducts = response.map((p) => Product.fromJson(p)).toList();

      // Si pas assez de produits, ajouter des produits de la même catégorie
      if (similarProducts.length < limit) {
        final categoryProducts = await _supabase
            .from('products')
            .select('*')
            .eq('category', product.category)
            .neq('id', product.id)
            .not('id', 'in', similarProducts.map((p) => p.id).toList())
            .limit(limit - similarProducts.length);

        similarProducts.addAll(
          categoryProducts.map((p) => Product.fromJson(p)).toList()
        );
      }

      // Si encore pas assez, ajouter des produits de la même marque
      if (similarProducts.length < limit) {
        final brandProducts = await _supabase
            .from('products')
            .select('*')
            .eq('brand', product.brand)
            .neq('id', product.id)
            .not('id', 'in', similarProducts.map((p) => p.id).toList())
            .limit(limit - similarProducts.length);

        similarProducts.addAll(
          brandProducts.map((p) => Product.fromJson(p)).toList()
        );
      }

      return similarProducts.take(limit).toList();
    } catch (e) {
      print('Erreur lors de la récupération des produits similaires: $e');
      return [];
    }
  }

  /// Met à jour les recommandations pour un utilisateur
  static Future<void> updateRecommendations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Supprimer les anciennes recommandations
      await _supabase
          .from('product_recommendations')
          .delete()
          .eq('user_id', user.id);

      // Générer de nouvelles recommandations
      final recommendations = await _generateRecommendations(20);
      
      // Sauvegarder les nouvelles recommandations
      for (final product in recommendations) {
        await _supabase.from('product_recommendations').insert({
          'user_id': user.id,
          'product_id': product.id,
          'recommended_product_id': product.id,
          'score': 0.8, // Score par défaut
          'reason': 'view_history',
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des recommandations: $e');
    }
  }
}
