import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/screens/product_detail_screen.dart';
import 'package:ecommerce/screens/search_screen.dart';
import 'package:ecommerce/screens/create_product_screen.dart';
import 'package:ecommerce/screens/cart_screen.dart';
import 'package:ecommerce/screens/auth_screen.dart';
import 'package:ecommerce/screens/categories_screen.dart';
import 'package:ecommerce/screens/profile_screen.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/services/auth_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/product_card_widget.dart';

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
    return dataService.products.map((product) => {
      'imageUrl': product.imageUrl,
      'title': product.name,
      'originalPrice': product.originalPrice.toStringAsFixed(2),
      'discountedPrice': product.price.toStringAsFixed(2),
      'discount': product.discountPercentage / 100,
      'product': product, // Garder la référence au produit original
    }).toList();
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
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  return GestureDetector(
                    onTap: () {
                      if (authService.isAuthenticated) {
                        // Si connecté, aller au profil
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      } else {
                        // Si pas connecté, aller à l'authentification
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AuthScreen(),
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.person,
                          color: Color(0xFF1A1A1A), // Very dark gray for better contrast
                        ),
                        Text(
                          authService.isAuthenticated ? 'Profil' : 'Se connecter',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1A1A1A), // Very dark gray for better contrast
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
                      color: Color(0xFF1A1A1A), // Very dark gray for better contrast
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
                        color: const Color(0xFF1A1A1A), // Very dark gray for better contrast
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
                  Center(
                    child: Container(
                      height: 160,
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
                                         errorBuilder: (context, error, stackTrace) => Container(
                                           color: Colors.grey[300],
                                           child: Column(
                                             mainAxisAlignment: MainAxisAlignment.center,
                                             children: [
                                               Icon(Icons.image_not_supported, size: 50, color: Colors.grey[600]),
                                               SizedBox(height: 8),
                                               Text(
                                                 'Image non disponible',
                                                 style: TextStyle(color: Colors.grey[600]),
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
                                           crossAxisAlignment: CrossAxisAlignment.start,
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
                    child:                     Text(
                      'Nos Meilleures Offres',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A), // Very dark gray for better contrast
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
                             builder: (context) => ProductDetailScreen(product: product),
                           ),
                         );
                       },
                       child: ProductCardWidget(
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
                               content: Text(
                                 dataService.isInWishlist(product.id) 
                                   ? '${product.name} retiré des favoris'
                                   : '${product.name} ajouté aux favoris'
                               ),
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
            heroTag: "home_add_product", // Tag unique pour éviter les conflits
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
            heroTag: "home_whatsapp", // Tag unique pour éviter les conflits
            onPressed: () async {
              try {
                await openWhatsApp(
                  '+243975024769',
                  'Bonjour, je vous contacte depuis mon application naara !',
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
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const CategoriesScreen())
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final Function openDrawer;

  _HeaderDelegate({required this.openDrawer});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.all(10.0),
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
                  color: Color(0xFF1A1A1A), // Very dark gray for better contrast
                ),
                                  Text(
                    'Produits',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFF1A1A1A), // Very dark gray for better contrast
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
                      color: const Color(0xFF666666), // Medium gray for secondary text
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.search,
                    color: Color(0xFF666666), // Medium gray for secondary elements
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
  double get maxExtent => 60.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
