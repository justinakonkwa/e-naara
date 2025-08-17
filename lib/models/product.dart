class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final List<String> images;
  final String category;
  final String subcategory;
  final String brand;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final int stockQuantity;
  final bool isFeatured;
  final List<String> tags;
  final Map<String, String> specifications;
  final DateTime createdAt;
  final String? sellerId;
  final String? sellerName;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.images,
    required this.category,
    required this.subcategory,
    required this.brand,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.stockQuantity,
    required this.isFeatured,
    required this.tags,
    required this.specifications,
    required this.createdAt,
    this.sellerId,
    this.sellerName,
  });

  bool get isOnSale => originalPrice > price;
  double get discountPercentage => 
      isOnSale ? ((originalPrice - price) / originalPrice * 100) : 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] ?? 0.0).toDouble(),
      originalPrice: (json['original_price'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      brand: json['brand'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      isAvailable: json['is_available'] ?? true,
      stockQuantity: json['stock_quantity'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      specifications: Map<String, String>.from(json['specifications'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      sellerId: json['seller_id'],
      sellerName: json['seller_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'images': images,
      'category': category,
      'subcategory': subcategory,
      'brand': brand,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'isFeatured': isFeatured,
      'tags': tags,
      'specifications': specifications,
      'createdAt': createdAt.toIso8601String(),
      'seller_id': sellerId,
      'seller_name': sellerName,
    };
  }
}

class ProductCategory {
  final String id;
  final String name;
  final String icon;
  final List<String> subcategories;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.subcategories,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      subcategories: List<String>.from(json['subcategories']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'subcategories': subcategories,
    };
  }
}

class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVerifiedPurchase;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isVerifiedPurchase,
  });
}