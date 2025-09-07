class PriceFormatter {
  static String formatPrice(double price, String currency) {
    switch (currency) {
      case 'USD':
        return '\$${price.toStringAsFixed(2)}';
      case 'EUR':
        return '${price.toStringAsFixed(2)} €';
      case 'CDF':
        return '${price.toStringAsFixed(2)} FC';
      default:
        return '${price.toStringAsFixed(2)} \$';
    }
  }

  static String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'CDF':
        return 'FC';
      default:
        return '\$';
    }
  }
}
