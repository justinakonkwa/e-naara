import 'dart:async';
import 'dart:math';

/// Service de simulation de paiement pour les tests
class PaymentService {
  static final Random _random = Random();

  /// Simule un processus de paiement
  static Future<PaymentResult> processPayment({
    required double amount,
    required String paymentMethod,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    // Simulation d'un délai de traitement
    await Future.delayed(Duration(seconds: 2 + _random.nextInt(3)));

    // Simulation de différents scénarios
    final successRate = 0.85; // 85% de succès
    final isSuccess = _random.nextDouble() < successRate;

    if (isSuccess) {
      return PaymentResult.success(
        transactionId: _generateTransactionId(),
        amount: amount,
        paymentMethod: paymentMethod,
      );
    } else {
      // Simulation d'erreurs courantes
      final errorTypes = [
        PaymentError.insufficientFunds,
        PaymentError.invalidCard,
        PaymentError.networkError,
        PaymentError.expiredCard,
      ];
      
      final errorType = errorTypes[_random.nextInt(errorTypes.length)];
      
      return PaymentResult.failure(
        error: errorType,
        message: _getErrorMessage(errorType),
      );
    }
  }

  /// Simule une validation de carte
  static Future<CardValidationResult> validateCard({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));

    // Validation basique
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return CardValidationResult.invalid('Numéro de carte invalide');
    }

    if (cvv.length < 3 || cvv.length > 4) {
      return CardValidationResult.invalid('Code CVV invalide');
    }

    // Validation de la date d'expiration
    try {
      final parts = expiryDate.split('/');
      if (parts.length != 2) {
        return CardValidationResult.invalid('Format de date invalide (MM/YY)');
      }

      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);

      if (month < 1 || month > 12) {
        return CardValidationResult.invalid('Mois invalide');
      }

      final now = DateTime.now();
      final currentYear = now.year % 100;
      final currentMonth = now.month;

      if (year < currentYear || (year == currentYear && month < currentMonth)) {
        return CardValidationResult.invalid('Carte expirée');
      }
    } catch (e) {
      return CardValidationResult.invalid('Format de date invalide');
    }

    return CardValidationResult.valid();
  }

  /// Génère un ID de transaction unique
  static String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(10000);
    return 'TXN${timestamp}_$random';
  }

  /// Retourne le message d'erreur approprié
  static String _getErrorMessage(PaymentError error) {
    switch (error) {
      case PaymentError.insufficientFunds:
        return 'Fonds insuffisants sur votre compte';
      case PaymentError.invalidCard:
        return 'Informations de carte invalides';
      case PaymentError.networkError:
        return 'Erreur de réseau, veuillez réessayer';
      case PaymentError.expiredCard:
        return 'Votre carte a expiré';
      case PaymentError.unknown:
        return 'Une erreur inattendue s\'est produite';
    }
  }
}

/// Types d'erreurs de paiement
enum PaymentError {
  insufficientFunds,
  invalidCard,
  networkError,
  expiredCard,
  unknown,
}

/// Résultat d'un paiement
class PaymentResult {
  final bool isSuccess;
  final String? transactionId;
  final double? amount;
  final String? paymentMethod;
  final PaymentError? error;
  final String? message;

  PaymentResult._({
    required this.isSuccess,
    this.transactionId,
    this.amount,
    this.paymentMethod,
    this.error,
    this.message,
  });

  factory PaymentResult.success({
    required String transactionId,
    required double amount,
    required String paymentMethod,
  }) {
    return PaymentResult._(
      isSuccess: true,
      transactionId: transactionId,
      amount: amount,
      paymentMethod: paymentMethod,
    );
  }

  factory PaymentResult.failure({
    required PaymentError error,
    required String message,
  }) {
    return PaymentResult._(
      isSuccess: false,
      error: error,
      message: message,
    );
  }
}

/// Résultat de validation de carte
class CardValidationResult {
  final bool isValid;
  final String? errorMessage;

  CardValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  factory CardValidationResult.valid() {
    return CardValidationResult._(isValid: true);
  }

  factory CardValidationResult.invalid(String message) {
    return CardValidationResult._(
      isValid: false,
      errorMessage: message,
    );
  }
}
