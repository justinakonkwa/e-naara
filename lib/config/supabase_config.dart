class SupabaseConfig {
  // =====================================================
  // 🔑 IDENTIFIANTS SUPABASE - CONFIGURÉS
  // =====================================================
  
  // URL de votre projet Supabase
  static const String supabaseUrl = 'https://ckocfgadkxbkiocyiirb.supabase.co';
  
  // Clé anonyme publique de votre projet
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrb2NmZ2Fka3hia2lvY3lpaXJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwOTgyNzgsImV4cCI6MjA3MDY3NDI3OH0._CTAnJe0Obz5BXUx1C24BNtsHuHIMtrRX5sj84f-1DM';
  
  // =====================================================
  // 📋 TABLES DE LA BASE DE DONNÉES
  // =====================================================
  static const String productsTable = 'products';
  static const String categoriesTable = 'categories';
  static const String usersTable = 'users';
  static const String cartItemsTable = 'cart_items';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
  static const String reviewsTable = 'reviews';
  static const String wishlistTable = 'wishlist';
  static const String promoCodesTable = 'promo_codes';
  
  // =====================================================
  // 🗂️ BUCKETS DE STOCKAGE
  // =====================================================
  static const String productImagesBucket = 'product-images';
  static const String userAvatarsBucket = 'user-avatars';
}
