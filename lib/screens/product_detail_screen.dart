import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/services/app_state.dart';
import 'package:ecommerce/components/product_card.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/services/recommendation_service.dart';
import 'package:ecommerce/screens/chat_screen.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/data/sample_data.dart';
import 'package:ecommerce/screens/edit_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _showFullDescription = false;
  List<Product> _similarProducts = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    
    _animationController.forward();
    
    // Enregistrer la consultation du produit
    _recordProductView();
    
    // Charger les produits similaires
    _loadSimilarProducts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _recordProductView() async {
    await RecommendationService.recordProductView(widget.product.id);
  }

  Future<void> _loadSimilarProducts() async {
    final similarProducts = await RecommendationService.getSimilarProducts(widget.product);
    setState(() {
      _similarProducts = similarProducts;
    });
  }

  void _addToCart() {
    final dataService = context.read<DataService>();
    dataService.addToCart(widget.product, quantity: _quantity);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} ajouté au panier'),
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

  void _toggleWishlist() {
    final dataService = context.read<DataService>();
    dataService.toggleWishlist(widget.product.id);
  }

  void _contactSeller() async {
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour contacter le vendeur'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Récupérer le vrai nom du vendeur depuis la base de données
      String sellerName = 'Vendeur';
      if (widget.product.sellerId != null && 
          widget.product.sellerId!.isNotEmpty && 
          widget.product.sellerId != 'default_seller') {
        try {
          // S'assurer que l'utilisateur existe dans la table users
          await SupabaseService.ensureUserExists(
            widget.product.sellerId!,
            'seller_${widget.product.sellerId}@example.com',
            'Vendeur',
            'Vendeur'
          );
          
          // Récupérer le nom complet
          final fullName = await SupabaseService.getUserFullName(widget.product.sellerId!);
          if (fullName != null) {
            sellerName = fullName;
          }
        } catch (e) {
          print('❌ [PRODUCT] Erreur lors de la récupération du nom du vendeur: $e');
        }
      }

      // Créer ou récupérer le chat existant
      final chat = await appState.createChat(
        customerId: user.id,
        customerName: user.fullName,
        sellerId: widget.product.sellerId ?? user.id, // Utiliser l'ID de l'utilisateur actuel si pas de vendeur
        sellerName: sellerName,
        productId: widget.product.id,
        productName: widget.product.name,
        productImageUrl: widget.product.imageUrl,
      );

      if (chat != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création du chat'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();
    final reviews = SampleData.sampleReviews
        .where((review) => review.productId == widget.product.id)
        .toList();
    final isInWishlist = dataService.isInWishlist(widget.product.id);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // App Bar with Image Gallery
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              backgroundColor: theme.colorScheme.surface,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              actions: [
                // Bouton d'édition (visible seulement pour le créateur du produit)
                if (_isProductOwner())
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditProductScreen(product: widget.product),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                  ),
                IconButton(
                  onPressed: _toggleWishlist,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? Colors.red : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Share product
                    _shareProduct();
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.share,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Image Gallery principale
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemCount: widget.product.images.length,
                      itemBuilder: (context, index) {
                        return Container(
                          // margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              widget.product.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: theme.colorScheme.surface,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  size: 80,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Miniatures en overlay à gauche
                    if (widget.product.images.length > 1)
                      Positioned(
                        left: 16,
                        top: 100, // Éviter le chevauchement avec les boutons de l'AppBar
                        bottom: 20,
                        child: Container(
                          width: 60,
                          child: ListView.builder(
                            itemCount: widget.product.images.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _currentImageIndex == index
                                          ? theme.colorScheme.primary
                                          : Colors.white,
                                      width: _currentImageIndex == index ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.network(
                                      widget.product.images[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: theme.colorScheme.surface,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    
                    // Image indicators en bas
                    if (widget.product.images.length > 1)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.product.images.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? theme.colorScheme.primary
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    

                  ],
                ),
              ),
            ),



            // Product Details
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Info
                    Text(
                      widget.product.brand,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rating and Reviews
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < widget.product.rating.toInt()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 20,
                              color: index < widget.product.rating.toInt()
                                  ? Colors.amber
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.product.rating} (${widget.product.reviewCount} avis)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price
                    Row(
                      children: [
                        if (widget.product.isOnSale) ...[
                          Text(
                            '${widget.product.originalPrice.toStringAsFixed(2)} €',
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          '${widget.product.price.toStringAsFixed(2)} €',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (widget.product.isOnSale) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '-${widget.product.discountPercentage.toInt()}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Seller Information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              widget.product.sellerName?.substring(0, 1).toUpperCase() ?? 'V',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vendu par',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  widget.product.sellerName ?? 'Vendeur',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isProductOwner())
                            ElevatedButton.icon(
                              onPressed: _contactSeller,
                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                              label: const Text('Contacter'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showFullDescription
                          ? widget.product.description
                          : widget.product.description.length > 150
                              ? '${widget.product.description.substring(0, 150)}...'
                              : widget.product.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                    if (widget.product.description.length > 150) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showFullDescription = !_showFullDescription;
                          });
                        },
                        child: Text(_showFullDescription ? 'Voir moins' : 'Voir plus'),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Stock Information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.product.isAvailable 
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.product.isAvailable 
                              ? theme.colorScheme.primary.withValues(alpha: 0.2)
                              : theme.colorScheme.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.product.isAvailable ? Icons.check_circle : Icons.cancel,
                            color: widget.product.isAvailable 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.isAvailable ? 'En stock' : 'Rupture de stock',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: widget.product.isAvailable 
                                        ? theme.colorScheme.primary 
                                        : theme.colorScheme.error,
                                  ),
                                ),
                                if (widget.product.isAvailable)
                                  Text(
                                    '${widget.product.stockQuantity} unités disponibles',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reviews Section
                    if (reviews.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            'Avis clients',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // Navigate to all reviews
                            },
                            child: Text(
                              'Voir tous les avis',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...reviews.take(3).map((review) => _buildReviewCard(review, theme)),
                      const SizedBox(height: 24),
                    ],

                    // Quantity Selector
                    Text(
                      'Quantité',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1 ? () {
                            setState(() {
                              _quantity--;
                            });
                          } : null,
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '$_quantity',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity < widget.product.stockQuantity ? () {
                            setState(() {
                              _quantity++;
                            });
                          } : null,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Section des produits similaires
            if (_similarProducts.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produits similaires',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _similarProducts.length,
                          itemBuilder: (context, index) {
                            final product = _similarProducts[index];
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 16),
                              child: ProductCard(
                                product: product,
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(product: product),
                                    ),
                                  );
                                },
                                showAddToCart: false,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Bouton Ajouter au panier
              Expanded(
                child: Container(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.product.isAvailable ? _addToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.product.isAvailable 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: widget.product.isAvailable 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.product.isAvailable ? Icons.shopping_cart_outlined : Icons.remove_shopping_cart,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.product.isAvailable ? 'Ajouter au panier' : 'Rupture de stock',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bouton Acheter maintenant
              Container(
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.product.isAvailable ? () {
                    _addToCart();
                    Navigator.of(context).pop();
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.product.isAvailable 
                        ? theme.colorScheme.secondary 
                        : theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: widget.product.isAvailable 
                        ? theme.colorScheme.onSecondary 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.product.isAvailable ? Icons.flash_on : Icons.flash_off,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Acheter',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(ProductReview review, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: index < review.rating 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatDate(review.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (review.isVerifiedPurchase) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Achat vérifié',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).round();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isProductOwner() {
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    return user != null && user.id == widget.product.sellerId;
  }

  void _shareProduct() {
    final String productUrl = 'https://example.com/product/${widget.product.id}';
    final String message = 'Découvrez ce produit incroyable : ${widget.product.name}\n\n${productUrl}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Partager le produit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Partager "${widget.product.name}"'),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
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
                // Copy to clipboard
                // In a real app, you would use Clipboard.setData()
                print('Copied to clipboard: $message');
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Lien copié dans le presse-papiers'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: const Text('Copier le lien'),
            ),
          ],
        );
      },
    );
  }
}