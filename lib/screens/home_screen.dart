import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/data/sample_data.dart';
import 'package:ecommerce/components/product_card.dart';
import 'package:ecommerce/components/category_card.dart';
import 'package:ecommerce/components/search_bar.dart';
import 'package:ecommerce/screens/product_detail_screen.dart';
import 'package:ecommerce/screens/search_screen.dart';
import 'package:ecommerce/screens/create_product_screen.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/services/auth_service.dart';
import 'package:ecommerce/services/recommendation_service.dart';
import 'package:ecommerce/screens/categories_screen.dart';
import 'package:ecommerce/screens/recommendations_screen.dart';
import 'package:ecommerce/screens/qr_scanner_screen.dart';
import 'package:ecommerce/screens/qr_code_display_screen.dart';
import 'package:ecommerce/screens/driver_qr_scanner_screen.dart';
import 'package:ecommerce/screens/qr_code_demo_screen.dart';
import 'package:ecommerce/screens/driver_dashboard_screen.dart';
import 'package:ecommerce/models/user_role.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<Product> _recommendedProducts = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    
    // Charger les produits recommandés
    _loadRecommendedProducts();
  }

  Future<void> _loadRecommendedProducts() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingRecommendations = true;
    });
    
    try {
      final recommendations = await RecommendationService.getRecommendedProducts(limit: 8);
      if (mounted) {
        setState(() {
          _recommendedProducts = recommendations;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    final dataService = context.read<DataService>();
    dataService.addToCart(product);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ajouté au panier'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () {
            // Navigate to cart
          },
        ),
      ),
    );
  }

  void _toggleWishlist(String productId) {
    final dataService = context.read<DataService>();
    dataService.toggleWishlist(productId);
  }

  Widget _buildQRCodeSection(BuildContext context) {
    final theme = Theme.of(context);
    final currentRole = UserRoleManager.currentRole;
    
    // Ne pas afficher pour les clients normaux, seulement pour les admins
    if (!UserRoleManager.isAdmin) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fonctionnalités QR Code',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Interface pour tous les utilisateurs
        SizedBox(
          width: double.infinity,
          child: _buildQRCodeCard(
            context,
            'Scanner QR Code',
            Icons.qr_code_scanner,
            Colors.blue,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DriverQRScannerScreen(),
              ),
            ),
          ),
        ),
        
        // Interface spécifique aux livreurs
        if (currentRole?.canAccessDriverFeatures == true && !UserRoleManager.isDriver) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildQRCodeCard(
              context,
              '🚚 Dashboard Livreur',
              Icons.dashboard,
              Colors.purple,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DriverDashboardScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildQRCodeCard(
              context,
              '📦 Scanner Livraison',
              Icons.local_shipping,
              Colors.green,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DriverQRScannerScreen(),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQRCodeCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();
    final authService = context.watch<AuthService>();
    
    final products = dataService.products;
    final featuredProducts = dataService.featuredProducts;
    final recentProducts = dataService.recentProducts;
    final categories = dataService.categories;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // App Bar fixe avec titre et notification
                SliverAppBar(
                  pinned: true,
                  backgroundColor: theme.colorScheme.surface,
                  // surfaceTintColor: Colors.transparent,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'E-Commerce',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Notification screen
                          },
                          icon: Stack(
                            children: [
                              Icon(
                                Icons.notifications_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Barre de recherche fixe
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    decoration: BoxDecoration(
                      // color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: 'search_bar',
                      child: Material(
                        color: Colors.transparent,
                        child: CustomSearchBar(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, _) => 
                                    const SearchScreen(),
                                transitionDuration: const Duration(milliseconds: 300),
                                transitionsBuilder: (context, animation, _, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenu principal
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Promotional Banner
                        _buildPromoBanner(context),
                        // const SizedBox(height: 10),

                        /*
                        // Section Catégories
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return Container(
                                width: 100,
                                margin: EdgeInsets.only(
                                  right: index < categories.length - 1 ? 12 : 0,
                                ),
                                child: CategoryCard(
                                  category: category,
                                  onTap: () {
                                    // Navigate to category products
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        */

                        // QR Code Section
                        _buildQRCodeSection(context),
                        const SizedBox(height: 30),

                        // Affichage conditionnel des produits
                        if (products.isEmpty) ...[
                          // Message quand aucun produit n'est disponible
                          _buildEmptyProductsMessage(context, 'Aucun produit disponible'),
                        ] else ...[
                          // Section Produits Phares - COMMENTÉE TEMPORAIREMENT
                          // TODO: Réactiver cette section une fois les produits phares configurés
                          /*
                          _buildSectionHeader(
                            theme,
                            title: 'Produits phares',
                            icon: Icons.star_rounded,
                            subtitle: 'Nos meilleures ventes',
                            onViewAll: () {
                              // Navigate to featured products
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: featuredProducts.length,
                              itemBuilder: (context, index) {
                                final product = featuredProducts[index];
                                return Container(
                                  width: 200,
                                  margin: EdgeInsets.only(
                                    right: index < featuredProducts.length - 1 ? 16 : 0,
                                  ),
                                  child: ProductCard(
                                    product: product,
                                    isInWishlist: dataService.isInWishlist(product.id),
                                    onTap: () => _navigateToProduct(product),
                                    onAddToCart: () => _addToCart(product),
                                    onToggleWishlist: () => _toggleWishlist(product.id),
                                  ),
                                );
                              },
                            ),
                          ),
                          */
                          
                          /*
                          // Message temporaire pour les produits phares
                          _buildComingSoonSection(
                            theme,
                            title: 'Produits phares',
                            description: 'Nos meilleures ventes seront bientôt disponibles',
                            icon: Icons.star_rounded,
                          ),
                          const SizedBox(height: 30),
                          */

                          // Section Nouveautés - Titre supprimé
                          if (recentProducts.isNotEmpty) ...[
                            // const SizedBox(height: 5),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),

                // Recent Products Grid - seulement si il y a des produits
                if (products.isNotEmpty && recentProducts.isNotEmpty)
                  SliverPadding(
                    
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.73,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = recentProducts[index];
                          return ProductCard(
                            product: product,
                            isInWishlist: dataService.isInWishlist(product.id),
                            onTap: () => _navigateToProduct(product),
                            onAddToCart: () => _addToCart(product),
                            onToggleWishlist: () => _toggleWishlist(product.id),
                          );
                        },
                        childCount: recentProducts.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyProductsMessage(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Les produits seront bientôt disponibles',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateProductScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ajouter des produits',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProduct(Product product) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => ProductDetailScreen(
          product: product,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  // Méthodes helper pour les composants UI modernes
  Widget _buildSectionHeader(
    ThemeData theme, {
    required String title,
    required IconData icon,
    String? subtitle,
    VoidCallback? onViewAll,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
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
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: Text(
                'Voir tout',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComingSoonSection(
    ThemeData theme, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
            theme.colorScheme.secondary,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Offres spéciales 🎉',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Jusqu\'à 50% de réduction\nsur une sélection de produits',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Découvrir',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
