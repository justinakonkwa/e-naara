import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Widget ProductCard adapté au design fourni (extrait de home_screen.dart)
class ProductCardWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String originalPrice;
  final String discountedPrice;
  final double discount;
  final double rating;
  final int reviewCount;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleWishlist;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleAvailability;
  final bool isInWishlist;
  final bool showDeleteButton;
  final bool showAvailabilityButton;
  final bool isAvailable;

  const ProductCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discount,
    required this.rating,
    required this.reviewCount,
    required this.onAddToCart,
    required this.onToggleWishlist,
    this.onDelete,
    this.onToggleAvailability,
    required this.isInWishlist,
    this.showDeleteButton = false,
    this.showAvailabilityButton = false,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
              height: MediaQuery.of(context).size.height * 0.16,
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
              // Bouton favoris ou disponibilité en haut à droite
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: showAvailabilityButton ? onToggleAvailability : onToggleWishlist,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      showAvailabilityButton 
                          ? (isAvailable ? Icons.check_circle : Icons.cancel)
                          : (isInWishlist ? Icons.favorite : Icons.favorite_border),
                      color: showAvailabilityButton 
                          ? (isAvailable ? Colors.green : Colors.red)
                          : (isInWishlist ? Colors.red : Colors.grey[600]),
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Bouton de suppression (si activé)
              if (showDeleteButton && onDelete != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A), // Very dark gray for better contrast
            ),
          ),
          const SizedBox(height: 6),
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
        ],
      ),
    );
  }
}
