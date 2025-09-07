import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/data/sample_data.dart';
import 'package:ecommerce/components/product_card.dart';
import 'package:ecommerce/screens/product_detail_screen.dart';
import 'package:ecommerce/screens/search_screen.dart';
import 'package:ecommerce/screens/create_product_screen.dart';
import 'package:ecommerce/screens/cart_screen.dart';
import 'package:ecommerce/screens/auth_screen.dart';
import 'package:ecommerce/screens/categories_screen.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/services/auth_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import '../widgets/shimmer_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Images du carrousel - seront remplacées par des images dynamiques

  // Données de produits dynamiques depuis le DataService
  List<Map<String, dynamic>> get products {
    final dataService = context.watch<DataService>();
    return dataService.products
        .map((product) => {
              'imageUrl': product.imageUrl,
              'title': product.name,
              'originalPrice': product.originalPrice.toStringAsFixed(2),
              'discountedPrice': product.price.toStringAsFixed(2),
              'discount': product.discountPercentage / 100,
              'product': product, // Garder la référence au produit original
            })
        .toList();
  }

  // Images du carrousel - utiliser des images dynamiques si disponibles
  List<String> get carouselImages {
    final dataService = context.watch<DataService>();
    final products = dataService.products;

    if (products.isNotEmpty) {
      // Utiliser les images des premiers produits comme carrousel
      return products.take(3).map((product) => product.imageUrl).toList();
    } else {
      // Images par défaut si aucun produit
      return [
        'https://via.placeholder.com/400x200/4A90E2/FFFFFF?text=Offres+Spéciales',
        'https://via.placeholder.com/400x200/50C878/FFFFFF?text=Nouveautés',
        'https://via.placeholder.com/400x200/FF6B6B/FFFFFF?text=Promotions',
      ];
    }
  }

  Future<void> openWhatsApp(String phoneNumber, String message) async {
    final link = WhatsAppUnilink(
      phoneNumber: phoneNumber,
      text: message,
    );

    try {
      await launch(link.toString());
    } catch (e) {
      print("Erreur : Impossible d'ouvrir WhatsApp via le lien.");
      throw 'Impossible d\'ouvrir WhatsApp';
    }
  }

  // Méthodes pour les titres du carrousel
  String _getCarouselTitle(int index) {
    final titles = [
      'Offres Spéciales',
      'Nouveautés',
      'Promotions',
    ];
    return titles[index % titles.length];
  }

  String _getCarouselSubtitle(int index) {
    final subtitles = [
      'Découvrez nos meilleures offres',
      'Les derniers produits ajoutés',
      'Jusqu\'à 50% de réduction',
    ];
    return subtitles[index % subtitles.length];
  }

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final authService = context.watch<AuthService>();

    // Gestion de l'état de chargement
    if (dataService.isLoading) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'E-Commerce',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: CustomScrollView(
          slivers: [
            // Header shimmer
            SliverPersistentHeader(
              pinned: true,
              floating: false,
              delegate: _HeaderDelegate(openDrawer: () {}),
            ),
            // Carrousel shimmer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const CarouselShimmer(),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Nos Meilleures Offres',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Grille de produits shimmer
            SliverPadding(
              padding: const EdgeInsets.all(10.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ProductCardShimmer(),
                  childCount: 6, // Afficher 6 cartes shimmer
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Gestion des erreurs
    if (dataService.error != null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'E-Commerce',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  dataService.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  dataService.loadProducts();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shopping_bag,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'E-Commerce',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthScreen(),
                    ),
                  );
                },
                child: Column(
                  children: [
                    const Icon(
                      CupertinoIcons.person,
                      color: Color(
                          0xFF1A1A1A), // Very dark gray for better contrast
                    ),
                    Text(
                      'Se connecter',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(
                            0xFF1A1A1A), // Very dark gray for better contrast
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Stack(
                      children: [
                        const Icon(
                          CupertinoIcons.cart,
                          color: Color(
                              0xFF1A1A1A), // Very dark gray for better contrast
                        ),
                        if (dataService.cartItems.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${dataService.cartItems.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      'Panier',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(
                            0xFF1A1A1A), // Very dark gray for better contrast
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
            ],
          )
        ],
        leading: Container(),
        leadingWidth: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: _HeaderDelegate(openDrawer: _openDrawer),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      height: 200,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).highlightColor,
                      ),
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemCount: carouselImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      carouselImages[index],
                                      fit: BoxFit.cover,
                                      width: MediaQuery.of(context).size.width,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: Colors.grey[300],
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_not_supported,
                                                size: 50,
                                                color: Colors.grey[600]),
                                            SizedBox(height: 8),
                                            Text(
                                              'Image non disponible',
                                              style: TextStyle(
                                                  color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Overlay avec texte
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getCarouselTitle(index),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _getCarouselSubtitle(index),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: _pageController,
                                count: carouselImages.length,
                                effect: ExpandingDotsEffect(
                                  activeDotColor: Colors.blue,
                                  dotColor: Colors.grey,
                                  dotHeight: 8,
                                  dotWidth: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Nos Meilleures Offres',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(
                            0xFF1A1A1A), // Very dark gray for better contrast
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Affichage conditionnel des produits
          if (products.isEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                height: 300,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun produit disponible',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les produits seront bientôt disponibles',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateProductScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter des produits'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            SliverPadding(
              padding: const EdgeInsets.all(10.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final productData = products[index];
                    final product = productData['product'] as Product;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      child: _ProductCard(
                        imageUrl: productData['imageUrl'],
                        title: productData['title'],
                        originalPrice: productData['originalPrice'],
                        discountedPrice: productData['discountedPrice'],
                        discount: productData['discount'],
                        rating: product.rating,
                        reviewCount: product.reviewCount,
                        isInWishlist: dataService.isInWishlist(product.id),
                        onAddToCart: () {
                          dataService.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} ajouté au panier'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onToggleWishlist: () {
                          dataService.toggleWishlist(product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(dataService.isInWishlist(product.id)
                                  ? '${product.name} retiré des favoris'
                                  : '${product.name} ajouté aux favoris'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateProductScreen(),
                ),
              );
            },
            shape: const CircleBorder(),
            backgroundColor: Colors.blue,
            child: const Icon(CupertinoIcons.add_circled),
          ),
          const SizedBox(height: 20),
          FloatingActionButton(
            onPressed: () async {
              try {
                await openWhatsApp(
                  '+243975929757',
                  'Bonjour, je vous contacte depuis mon application Kitunga !',
                );
              } catch (e) {
                print("Erreur lors de l'ouverture de WhatsApp: $e");
              }
            },
            elevation: 10,
            shape: const CircleBorder(),
            backgroundColor: Colors.blue,
            child: const Icon(CupertinoIcons.chat_bubble_2),
          ),
        ],
      ),
    );
  }

  void _openDrawer() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const CategoriesScreen()));
  }
}

// Widget ProductCard adapté au design fourni
class _ProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String originalPrice;
  final String discountedPrice;
  final double discount;
  final double rating;
  final int reviewCount;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleWishlist;
  final bool isInWishlist;

  const _ProductCard({
    required this.imageUrl,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discount,
    required this.rating,
    required this.reviewCount,
    required this.onAddToCart,
    required this.onToggleWishlist,
    required this.isInWishlist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280, // Hauteur fixe pour éviter le débordement
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 120, // Hauteur fixe pour l'image
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),
                // Bouton favoris en haut à droite
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onToggleWishlist,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? Colors.red : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(
                    0xFF1A1A1A), // Very dark gray for better contrast
              ),
            ),
            const SizedBox(height: 8),
            // Étoiles de notation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < rating.floor() ? Icons.star : Icons.star_border,
                    size: 16,
                    color: index < rating.floor()
                        ? Colors.amber
                        : Colors.grey[400],
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  '($reviewCount)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$originalPrice\$',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).highlightColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '-${(discount * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$discountedPrice\$',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onAddToCart,
                  child: const CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    radius: 20,
                    child: Icon(CupertinoIcons.cart, color: Colors.white),
                  ),
                ),
              ],
            ),
          ]),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final Function openDrawer;

  _HeaderDelegate({required this.openDrawer});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              openDrawer();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.list_bullet_below_rectangle,
                  color:
                      Color(0xFF1A1A1A), // Very dark gray for better contrast
                ),
                Text(
                  'Produits',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(
                        0xFF1A1A1A), // Very dark gray for better contrast
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 45,
              width: MediaQuery.of(context).size.width * 0.75,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).highlightColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recherche',
                    style: TextStyle(
                      color: const Color(
                          0xFF666666), // Medium gray for secondary text
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.search,
                    color:
                        Color(0xFF666666), // Medium gray for secondary elements
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 70.0;

  @override
  double get minExtent => 70.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
