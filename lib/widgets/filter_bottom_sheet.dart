import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/services/data_service.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _filters;
  
  // Filtres de prix
  RangeValues _priceRange = const RangeValues(0, 2000);
  double _maxPrice = 2000;
  
  // Filtres de catégorie
  String? _selectedCategory;
  List<String> _selectedCategories = [];
  
  // Filtres de marque
  List<String> _selectedBrands = [];
  List<String> _availableBrands = [];
  
  // Tri
  String _sortBy = 'relevance';
  
  // Disponibilité
  bool _inStockOnly = false;
  bool _onSaleOnly = false;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.initialFilters);
    _loadInitialFilters();
    _loadAvailableBrands();
  }

  void _loadInitialFilters() {
    // Prix
    _priceRange = RangeValues(
      _filters['minPrice']?.toDouble() ?? 0,
      _filters['maxPrice']?.toDouble() ?? _maxPrice,
    );
    
    // Catégories
    _selectedCategories = List<String>.from(_filters['categories'] ?? []);
    if (_selectedCategories.isNotEmpty) {
      _selectedCategory = _selectedCategories.first;
    }
    
    // Marques
    _selectedBrands = List<String>.from(_filters['brands'] ?? []);
    
    // Tri
    _sortBy = _filters['sortBy'] ?? 'relevance';
    
    // Disponibilité
    _inStockOnly = _filters['inStockOnly'] ?? false;
    _onSaleOnly = _filters['onSaleOnly'] ?? false;
  }

  void _loadAvailableBrands() {
    final dataService = context.read<DataService>();
    _availableBrands = dataService.products
        .map((product) => product.brand)
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _applyFilters() {
    final newFilters = <String, dynamic>{
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
      'categories': _selectedCategories,
      'brands': _selectedBrands,
      'sortBy': _sortBy,
      'inStockOnly': _inStockOnly,
      'onSaleOnly': _onSaleOnly,
    };
    
    widget.onFiltersChanged(newFilters);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _priceRange = RangeValues(0, _maxPrice);
      _selectedCategories.clear();
      _selectedCategory = null;
      _selectedBrands.clear();
      _sortBy = 'relevance';
      _inStockOnly = false;
      _onSaleOnly = false;
    });
  }

  void _clearFilters() {
    _resetFilters();
    widget.onFiltersChanged({});
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.read<DataService>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Filtres',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Effacer tout'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prix
                  _buildPriceFilter(theme),
                  const SizedBox(height: 24),

                  // Catégories
                  _buildCategoryFilter(theme, dataService),
                  const SizedBox(height: 24),

                  // Marques
                  _buildBrandFilter(theme),
                  const SizedBox(height: 24),

                  // Tri
                  _buildSortFilter(theme),
                  const SizedBox(height: 24),

                  // Disponibilité
                  _buildAvailabilityFilter(theme),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prix',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: _maxPrice,
          divisions: 40,
          labels: RangeLabels(
            '${_priceRange.start.round()}€',
            '${_priceRange.end.round()}€',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_priceRange.start.round()}€',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              '${_priceRange.end.round()}€',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(ThemeData theme, DataService dataService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégories',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dataService.categories.map((category) {
            final isSelected = _selectedCategories.contains(category.id);
            return FilterChip(
              label: Text(category.name.split(' ').skip(1).join(' ')),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category.id);
                  } else {
                    _selectedCategories.remove(category.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBrandFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marques',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (_availableBrands.isEmpty)
          Text(
            'Aucune marque disponible',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableBrands.map((brand) {
              final isSelected = _selectedBrands.contains(brand);
              return FilterChip(
                label: Text(brand),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedBrands.add(brand);
                    } else {
                      _selectedBrands.remove(brand);
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSortFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trier par',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildSortOption(theme, 'relevance', 'Pertinence', Icons.sort),
            _buildSortOption(theme, 'price_low', 'Prix croissant', Icons.arrow_upward),
            _buildSortOption(theme, 'price_high', 'Prix décroissant', Icons.arrow_downward),
            _buildSortOption(theme, 'newest', 'Plus récents', Icons.new_releases),
            _buildSortOption(theme, 'popularity', 'Popularité', Icons.trending_up),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOption(ThemeData theme, String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return RadioListTile<String>(
      value: value,
      groupValue: _sortBy,
      onChanged: (newValue) {
        setState(() {
          _sortBy = newValue!;
        });
      },
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildAvailabilityFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disponibilité',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('En stock uniquement'),
          value: _inStockOnly,
          onChanged: (value) {
            setState(() {
              _inStockOnly = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('En promotion uniquement'),
          value: _onSaleOnly,
          onChanged: (value) {
            setState(() {
              _onSaleOnly = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }
}
