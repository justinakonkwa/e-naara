import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/components/search_bar.dart';
import 'package:ecommerce/components/product_card.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/services/search_preferences_service.dart';
import 'package:ecommerce/services/recommendation_service.dart';
import 'package:ecommerce/widgets/filter_bottom_sheet.dart';
import 'package:ecommerce/screens/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  List<String> _recentSearches = [
    'iPhone',
    'Nike Air Max',
    'Casque Sony',
    'MacBook',
  ];
  List<Map<String, dynamic>> _searchHistory = [];
  bool _isSearching = false;
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadSearchHistory();
    // Auto-focus search bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus();
    });
  }

  Future<void> _loadPreferences() async {
    // Charger les recherches récentes
    final recentSearches = await SearchPreferencesService.getRecentSearches();
    setState(() {
      _recentSearches = recentSearches;
    });

    // Charger les filtres sauvegardés
    final savedFilters = await SearchPreferencesService.getSearchFilters();
    setState(() {
      _filters = savedFilters;
    });
  }

  Future<void> _loadSearchHistory() async {
    final history = await RecommendationService.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    final dataService = context.read<DataService>();
    
    setState(() {
      _isSearching = true;
      
      // Recherche de base
      List<Product> results = dataService.products.where((product) {
        final searchQuery = query.toLowerCase();
        return product.name.toLowerCase().contains(searchQuery) ||
            product.description.toLowerCase().contains(searchQuery) ||
            product.brand.toLowerCase().contains(searchQuery) ||
            product.category.toLowerCase().contains(searchQuery) ||
            product.subcategory.toLowerCase().contains(searchQuery);
      }).toList();

      // Appliquer les filtres
      results = _applyFiltersToResults(results);
      
      // Appliquer le tri
      results = _sortResults(results);
      
      _searchResults = results;
    });

    // Add to recent searches
    await SearchPreferencesService.addRecentSearch(query);
    final updatedSearches = await SearchPreferencesService.getRecentSearches();
    setState(() {
      _recentSearches = updatedSearches;
    });

    // Sauvegarder dans l'historique
    await RecommendationService.saveSearchHistory(query, _searchResults.length);
    await _loadSearchHistory();
  }

  List<Product> _applyFiltersToResults(List<Product> results) {
    // Filtre par prix
    if (_filters.containsKey('minPrice') || _filters.containsKey('maxPrice')) {
      final minPrice = _filters['minPrice']?.toDouble() ?? 0.0;
      final maxPrice = _filters['maxPrice']?.toDouble() ?? double.infinity;
      
      results = results.where((product) {
        return product.price >= minPrice && product.price <= maxPrice;
      }).toList();
    }

    // Filtre par catégories
    if (_filters.containsKey('categories') && _filters['categories'].isNotEmpty) {
      final selectedCategories = List<String>.from(_filters['categories']);
      results = results.where((product) {
        return selectedCategories.contains(product.category);
      }).toList();
    }

    // Filtre par marques
    if (_filters.containsKey('brands') && _filters['brands'].isNotEmpty) {
      final selectedBrands = List<String>.from(_filters['brands']);
      results = results.where((product) {
        return selectedBrands.contains(product.brand);
      }).toList();
    }

    // Filtre par disponibilité
    if (_filters['inStockOnly'] == true) {
      results = results.where((product) => product.isAvailable).toList();
    }

    // Filtre par promotion
    if (_filters['onSaleOnly'] == true) {
      results = results.where((product) => product.originalPrice > product.price).toList();
    }

    return results;
  }

  List<Product> _sortResults(List<Product> results) {
    final sortBy = _filters['sortBy'] ?? 'relevance';
    
    switch (sortBy) {
      case 'price_low':
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'popularity':
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'relevance':
      default:
        // Garder l'ordre de pertinence de la recherche
        break;
    }
    
    return results;
  }

  void _applyFilters(Map<String, dynamic> filters) async {
    setState(() {
      _filters = filters;
    });
    
    // Sauvegarder les filtres
    await SearchPreferencesService.saveSearchFilters(filters);
    
    // Re-rechercher avec les nouveaux filtres
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        onFiltersChanged: _applyFilters,
        initialFilters: _filters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
          ),
        ),
        title: Hero(
          tag: 'search_bar',
          child: Material(
            color: Colors.transparent,
            child: CustomSearchBar(
              controller: _searchController,
              onChanged: _performSearch,
              onFilterTap: _showFilterSheet,
              hintText: 'Que recherchez-vous ?',
            ),
          ),
        ),
      ),
      body: _buildBody(context, theme),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    if (!_isSearching && _searchController.text.isEmpty) {
      return _buildInitialState(theme);
    }

    if (_isSearching && _searchResults.isEmpty) {
      return _buildNoResults(theme);
    }

    return _buildSearchResults(theme);
  }

  Widget _buildInitialState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Text(
              'Recherches récentes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          search,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Search History
          if (_searchHistory.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Historique de recherche',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    // Supprimer tout l'historique
                    for (final item in _searchHistory) {
                      await RecommendationService.deleteSearchHistory(item['id']);
                    }
                    await _loadSearchHistory();
                  },
                  child: Text(
                    'Effacer',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_searchHistory.take(5).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SearchSuggestion(
                  text: item['query'],
                  icon: Icons.search,
                  subtitle: '${item['result_count']} résultats • ${_formatDate(item['created_at'])}',
                  onTap: () {
                    _searchController.text = item['query'];
                    _performSearch(item['query']);
                  },
                  onDelete: () async {
                    await RecommendationService.deleteSearchHistory(item['id']);
                    await _loadSearchHistory();
                  },
                ),
              );
            }).toList()),
            const SizedBox(height: 24),
          ],

          // Popular Categories
          Text(
            'Catégories populaires',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Builder(
              builder: (context) {
                final dataService = context.read<DataService>();
                if (dataService.categories.isEmpty) {
                  return _buildEmptyCategoriesMessage(theme);
                }
                return ListView.builder(
                  itemCount: dataService.categories.length,
                  itemBuilder: (context, index) {
                    final category = dataService.categories[index];
                    return SearchSuggestion(
                      text: category.name.split(' ').skip(1).join(' '),
                      icon: Icons.category,
                      onTap: () {
                        _searchController.text = category.name.split(' ').skip(1).join(' ');
                        _performSearch(_searchController.text);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCategoriesMessage(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
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
            Container(
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
          ],
        ),
      );
    }
    
    // Si aucun résultat de recherche trouvé
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
              'Aucun résultat trouvé',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Essayez avec d\'autres mots-clés ou consultez nos catégories populaires',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults.clear();
                  _isSearching = false;
                });
              },
              child: const Text('Retour à la recherche'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return Column(
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${_searchResults.length} résultat${_searchResults.length > 1 ? 's' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  if (_filters.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Filtré',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Afficher les filtres actifs
              if (_filters.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _buildActiveFilterChips(theme),
                ),
              ],
            ],
          ),
        ),

        // Results grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    // Navigate to product detail
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  onAddToCart: () {
                    // Add to cart
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

  List<Widget> _buildActiveFilterChips(ThemeData theme) {
    final chips = <Widget>[];
    final dataService = context.read<DataService>();

    // Prix
    if (_filters.containsKey('minPrice') || _filters.containsKey('maxPrice')) {
      final minPrice = _filters['minPrice']?.toDouble() ?? 0.0;
      final maxPrice = _filters['maxPrice']?.toDouble() ?? double.infinity;
      
      chips.add(
        _buildFilterChip(
          theme,
          'Prix: ${minPrice.round()}€ - ${maxPrice == double.infinity ? "∞" : "${maxPrice.round()}€"}',
          () => _removeFilter('price'),
        ),
      );
    }

    // Catégories
    if (_filters.containsKey('categories') && _filters['categories'].isNotEmpty) {
      final categories = List<String>.from(_filters['categories']);
      for (final categoryId in categories) {
        final category = dataService.categories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => const ProductCategory(id: '', name: '', icon: '', subcategories: []),
        );
        
        chips.add(
          _buildFilterChip(
            theme,
            category.name.split(' ').skip(1).join(' '),
            () => _removeCategoryFilter(categoryId),
          ),
        );
      }
    }

    // Marques
    if (_filters.containsKey('brands') && _filters['brands'].isNotEmpty) {
      final brands = List<String>.from(_filters['brands']);
      for (final brand in brands) {
        chips.add(
          _buildFilterChip(
            theme,
            brand,
            () => _removeBrandFilter(brand),
          ),
        );
      }
    }

    // Disponibilité
    if (_filters['inStockOnly'] == true) {
      chips.add(
        _buildFilterChip(
          theme,
          'En stock',
          () => _removeFilter('inStockOnly'),
        ),
      );
    }

    if (_filters['onSaleOnly'] == true) {
      chips.add(
        _buildFilterChip(
          theme,
          'En promotion',
          () => _removeFilter('onSaleOnly'),
        ),
      );
    }

    return chips;
  }

  Widget _buildFilterChip(ThemeData theme, String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  void _removeFilter(String filterKey) {
    setState(() {
      _filters.remove(filterKey);
    });
    
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  void _removeCategoryFilter(String categoryId) {
    setState(() {
      final categories = List<String>.from(_filters['categories'] ?? []);
      categories.remove(categoryId);
      if (categories.isEmpty) {
        _filters.remove('categories');
      } else {
        _filters['categories'] = categories;
      }
    });
    
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  void _removeBrandFilter(String brand) {
    setState(() {
      final brands = List<String>.from(_filters['brands'] ?? []);
      brands.remove(brand);
      if (brands.isEmpty) {
        _filters.remove('brands');
      } else {
        _filters['brands'] = brands;
      }
    });
    
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}