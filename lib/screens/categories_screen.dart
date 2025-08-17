import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/components/category_card.dart';
import 'package:ecommerce/components/product_card.dart';
import 'package:ecommerce/screens/create_product_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  String? _selectedSubcategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    final dataService = context.read<DataService>();
    var products = dataService.products;
    
    if (_selectedCategory != null) {
      products = products.where((p) => p.category == _selectedCategory).toList();
    }
    
    if (_selectedSubcategory != null) {
      products = products.where((p) => p.subcategory == _selectedSubcategory).toList();
    }
    
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Catégories'),
        backgroundColor: theme.colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Toutes les catégories'),
            Tab(text: 'Produits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(theme),
          _buildProductsTab(theme),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(ThemeData theme) {
    final dataService = context.read<DataService>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search suggestion
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recherchez parmi plus de ${dataService.products.length} produits',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Categories grid
          if (dataService.categories.isEmpty)
            _buildEmptyCategoriesMessage(theme)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: dataService.categories.length,
              itemBuilder: (context, index) {
                final category = dataService.categories[index];
                return CategoryCard(
                  category: category,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category.id;
                      _selectedSubcategory = null;
                    });
                    _tabController.animateTo(1);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(ThemeData theme) {
    final dataService = context.read<DataService>();
    final filteredProducts = _filteredProducts;
    final selectedCategoryData = _selectedCategory != null 
        ? dataService.categories.firstWhere((c) => c.id == _selectedCategory)
        : null;

    return Column(
      children: [
        // Filters
        if (selectedCategoryData != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      selectedCategoryData.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _selectedSubcategory = null;
                        });
                      },
                      child: const Text('Effacer'),
                    ),
                  ],
                ),
                
                // Subcategories
                if (selectedCategoryData.subcategories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedCategoryData.subcategories.length,
                      itemBuilder: (context, index) {
                        final subcategory = selectedCategoryData.subcategories[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < selectedCategoryData.subcategories.length - 1 ? 8 : 0,
                          ),
                          child: CategoryChip(
                            label: subcategory,
                            isSelected: _selectedSubcategory == subcategory,
                            onTap: () {
                              setState(() {
                                _selectedSubcategory = 
                                    _selectedSubcategory == subcategory ? null : subcategory;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ],

        // Products count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${filteredProducts.length} produit${filteredProducts.length > 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Toggle grid/list view
                },
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),

        // Products grid
        Expanded(
          child: filteredProducts.isEmpty 
              ? _buildEmptyState(theme)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          // Navigate to product detail
                        },
                        onAddToCart: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} ajouté au panier'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        onToggleWishlist: () {
                          // Toggle wishlist
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyCategoriesMessage(ThemeData theme) {
    return Container(
      height: 300,
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
            Icons.category_outlined,
            size: 64,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune catégorie disponible',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Les catégories seront bientôt disponibles',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Ajouter des catégories',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final dataService = context.read<DataService>();
    
    // Si aucun produit dans la base de données
    if (dataService.products.isEmpty) {
      return Container(
        height: 400,
        width: double.infinity,
        margin: const EdgeInsets.all(20),
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
              'Aucun produit disponible',
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
    
    // Si aucun produit trouvé avec les filtres actuels
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun produit trouvé',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Essayez de sélectionner une autre catégorie ou supprimez les filtres',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedSubcategory = null;
                });
              },
              child: const Text('Voir tous les produits'),
            ),
          ],
        ),
      ),
    );
  }
}