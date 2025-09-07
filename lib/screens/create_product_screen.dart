import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/product.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _brandController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedSubcategory;
  String _selectedCurrency = 'USD';
  bool _isAvailable = true;
  bool _isFeatured = false;
  List<String> _tags = [];
  final _tagController = TextEditingController();
  
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _error;

  // Liste des devises disponibles
  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'Dollar US (\$)'},
    {'code': 'EUR', 'name': 'Euro (€)'},
    {'code': 'CDF', 'name': 'Franc Congolais (FC)'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _brandController.dispose();
    _subcategoryController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text.trim());
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  List<String> _getSubcategoriesForCategory(String categoryId) {
    // Récupérer les sous-catégories depuis les données existantes
    final dataService = context.read<DataService>();
    final selectedCategory = dataService.categories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => const ProductCategory(id: '', name: '', icon: '', subcategories: []),
    );
    
    return List.from(selectedCategory.subcategories);
  }



  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir une image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Caméra'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });
      
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection des images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() {
        _error = 'Veuillez sélectionner une catégorie';
      });
      return;
    }
    
    // Validation de la sous-catégorie
    final subcategory = _subcategoryController.text.trim();
    if (subcategory.isEmpty) {
      setState(() {
        _error = 'Veuillez sélectionner ou saisir une sous-catégorie';
      });
      return;
    }
    
    if (_selectedImages.isEmpty) {
      setState(() {
        _error = 'Veuillez sélectionner au moins une image';
      });
      return;
    }

    try {
      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        originalPrice: double.parse(_originalPriceController.text),
        imageUrl: '', // Sera rempli par le service après upload
        images: [], // Sera rempli par le service après upload
        category: _selectedCategory!,
        subcategory: _subcategoryController.text.trim(),
        brand: _brandController.text.trim(),
        rating: 0.0,
        reviewCount: 0,
        isAvailable: _isAvailable,
        stockQuantity: int.parse(_stockController.text),
        isFeatured: _isFeatured,
        tags: _tags,
        specifications: {}, // Pour l'instant, vide
        createdAt: DateTime.now(),
        currency: _selectedCurrency,
      );

      final success = await SupabaseService.createProduct(product, imageFiles: _selectedImages);
      
      if (success) {
        // Recharger les produits
        final dataService = context.read<DataService>();
        await dataService.loadProducts();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produit créé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _error = 'Erreur lors de la création du produit';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Créer un produit'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Text(
                'Nouveau produit',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Remplissez les informations du produit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Message d'erreur
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              if (_error != null) const SizedBox(height: 16),

              // Nom du produit
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La description est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Catégorie
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie *',
                  border: OutlineInputBorder(),
                ),
                items: dataService.categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubcategory = null; // Réinitialiser la sélection
                    _subcategoryController.clear(); // Vider le champ texte
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une catégorie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

                            // Sous-catégorie
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sous-catégorie *',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Dropdown pour les sous-catégories existantes
                  if (_selectedCategory != null) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedSubcategory,
                      decoration: const InputDecoration(
                        labelText: 'Choisir une sous-catégorie existante',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('-- Choisir une sous-catégorie --'),
                        ),
                        ..._getSubcategoriesForCategory(_selectedCategory!).map((subcategory) {
                          return DropdownMenuItem(
                            value: subcategory,
                            child: Text(
                              subcategory,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        const DropdownMenuItem<String>(
                          value: 'custom',
                          child: Text('➕ Ajouter une nouvelle sous-catégorie'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSubcategory = value;
                          if (value == 'custom') {
                            _subcategoryController.clear();
                          } else if (value != null) {
                            _subcategoryController.text = value;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Champ texte pour sous-catégorie personnalisée
                  if (_selectedSubcategory == 'custom' || _selectedCategory == null)
                    TextFormField(
                      controller: _subcategoryController,
                      decoration: InputDecoration(
                        labelText: _selectedCategory == null 
                            ? 'Sous-catégorie *' 
                            : 'Nouvelle sous-catégorie *',
                        border: const OutlineInputBorder(),
                        helperText: _selectedCategory == null 
                            ? 'Entrez le nom de la sous-catégorie'
                            : 'Entrez le nom de votre nouvelle sous-catégorie',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La sous-catégorie est requise';
                        }
                        return null;
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),



              // Marque
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Marque *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La marque est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Devise
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Devise *',
                  border: OutlineInputBorder(),
                ),
                items: _currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency['code'],
                    child: Text(currency['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une devise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Prix
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Prix *',
                        border: const OutlineInputBorder(),
                        suffixText: _selectedCurrency,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le prix est requis';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Prix invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _originalPriceController,
                      decoration: InputDecoration(
                        labelText: 'Prix original',
                        border: const OutlineInputBorder(),
                        suffixText: _selectedCurrency,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Prix invalide';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stock
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Quantité en stock *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La quantité est requise';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Quantité invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sélection d'images
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Images du produit *',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _showImageSourceDialog,
                            icon: const Icon(Icons.add_a_photo),
                            tooltip: 'Ajouter une image',
                          ),
                          IconButton(
                            onPressed: _pickMultipleImages,
                            icon: const Icon(Icons.photo_library),
                            tooltip: 'Ajouter plusieurs images',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Affichage des images sélectionnées
                  if (_selectedImages.isNotEmpty) ...[
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.file(
                                    _selectedImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: theme.colorScheme.surface,
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Zone de sélection d'image
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surface,
                      ),
                      child: _isUploadingImage
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 32,
                                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajouter des images',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  '${_selectedImages.length} image(s) sélectionnée(s)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (_selectedImages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Au moins une image est requise',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  labelText: 'Ajouter un tag',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add),
                  ),
                ),
                onFieldSubmitted: (_) => _addTag(),
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),

              // Options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Options',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Disponible'),
                        subtitle: const Text('Le produit est en stock'),
                        value: _isAvailable,
                        onChanged: (value) {
                          setState(() {
                            _isAvailable = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Produit en vedette'),
                        subtitle: const Text('Afficher dans les produits phares'),
                        value: _isFeatured,
                        onChanged: (value) {
                          setState(() {
                            _isFeatured = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bouton de création
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createProduct,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Créer le produit',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
