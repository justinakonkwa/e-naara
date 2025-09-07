import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/screens/product_detail_screen.dart';
import 'package:ecommerce/widgets/shimmer_widgets.dart';
import 'package:ecommerce/widgets/product_card_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Product> _favoriteProducts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavoriteProducts();
  }

  Future<void> _loadFavoriteProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer la liste des IDs de favoris
      final favoriteIds = await SupabaseService.getWishlist();
      
      if (favoriteIds.isEmpty) {
        setState(() {
          _favoriteProducts = [];
          _isLoading = false;
        });
        return;
      }

      // Récupérer les détails des produits favoris
      final products = <Product>[];
      for (final productId in favoriteIds) {
        try {
          final product = await SupabaseService.getProductById(productId);
          if (product != null) {
            products.add(product);
          }
        } catch (e) {
          print('Erreur lors du chargement du produit $productId: $e');
        }
      }

      setState(() {
        _favoriteProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement de vos favoris: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(Product product) async {
    try {
      final dataService = context.read<DataService>();
      await dataService.toggleWishlist(product.id);
      
      // Recharger la liste
      await _loadFavoriteProducts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} retiré de vos favoris'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Annuler',
              textColor: Colors.white,
              onPressed: () async {
                await dataService.toggleWishlist(product.id);
                await _loadFavoriteProducts();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider les favoris'),
        content: const Text('Êtes-vous sûr de vouloir retirer tous les produits de vos favoris ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vider'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dataService = context.read<DataService>();
        for (final product in _favoriteProducts) {
          await dataService.toggleWishlist(product.id);
        }
        
        await _loadFavoriteProducts();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tous les favoris ont été supprimés'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (_favoriteProducts.isNotEmpty)
            IconButton(
              onPressed: _clearAllFavorites,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Vider tous les favoris',
            ),
          IconButton(
            onPressed: _loadFavoriteProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? _buildFavoritesList(theme) // Affiche le shimmer au lieu du CircularProgressIndicator
          : _error != null
              ? _buildErrorState(theme)
              : _favoriteProducts.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildFavoritesList(theme),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFavoriteProducts,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun favori',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore ajouté de produits à vos favoris.\nExplorez nos produits et ajoutez ceux qui vous plaisent !',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Retourner à l'écran principal
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explorer les produits'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(ThemeData theme) {
    return Column(
      children: [
        // Header avec statistiques
        Container(
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? Row(
                  children: [
                    Expanded(
                      child: _buildStatCardShimmer(theme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCardShimmer(theme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCardShimmer(theme),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Total',
                        '${_favoriteProducts.length}',
                        Icons.favorite,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Disponibles',
                        '${_favoriteProducts.where((p) => p.isAvailable).length}',
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'En promotion',
                        '${_favoriteProducts.where((p) => p.isOnSale).length}',
                        Icons.local_offer,
                      ),
                    ),
                  ],
                ),
        ),
        
        // Liste des favoris
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadFavoriteProducts,
            child: _isLoading
                ? GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68, // Même ratio que les vraies cartes
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 6, // Afficher 6 shimmer cards
                    itemBuilder: (context, index) {
                      return const ProductCardShimmer();
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68, // Réduit pour donner plus de hauteur
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _favoriteProducts.length,
                    itemBuilder: (context, index) {
                      final product = _favoriteProducts[index];
                      return _buildFavoriteCard(theme, product);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardShimmer(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            // Icône shimmer
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Valeur shimmer
            Container(
              width: 30,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            // Label shimmer
            Container(
              width: 50,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(ThemeData theme, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: ProductCardWidget(
        imageUrl: product.imageUrl,
        title: product.name,
        originalPrice: product.originalPrice.toStringAsFixed(2),
        discountedPrice: product.price.toStringAsFixed(2),
        discount: product.discountPercentage / 100,
        rating: product.rating,
        reviewCount: product.reviewCount,
        isInWishlist: true, // Toujours true car c'est l'écran des favoris
        showDeleteButton: true, // Afficher le bouton de suppression
        onAddToCart: () {
          // Action d'ajout au panier (même que la page d'accueil)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} ajouté au panier'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onToggleWishlist: () => _removeFromFavorites(product),
        onDelete: () => _removeFromFavorites(product),
      ),
    );
  }
}
