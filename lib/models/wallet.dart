import 'package:flutter/material.dart';

class Wallet {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WalletTransaction> transactions;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    required this.transactions,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      userId: json['user_id'],
      balance: (json['balance'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      transactions: (json['transactions'] as List<dynamic>?)
          ?.map((t) => WalletTransaction.fromJson(t))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }
}

class WalletTransaction {
  final String id;
  final String walletId;
  final String type; // 'credit', 'debit', 'withdrawal', 'refund'
  final double amount;
  final String description;
  final String? orderId;
  final String? reference;
  final TransactionStatus status;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.description,
    this.orderId,
    this.reference,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      walletId: json['wallet_id'],
      type: json['type'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      description: json['description'],
      orderId: json['order_id'],
      reference: json['reference'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.databaseValue == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'type': type,
      'amount': amount,
      'description': description,
      'order_id': orderId,
      'reference': reference,
      'status': status.databaseValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCredit => type == 'credit' || type == 'refund';
  bool get isDebit => type == 'debit' || type == 'withdrawal';
}

enum TransactionStatus {
  pending('pending'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const TransactionStatus(this.databaseValue);
  final String databaseValue;

  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.completed:
        return 'Terminé';
      case TransactionStatus.failed:
        return 'Échoué';
      case TransactionStatus.cancelled:
        return 'Annulé';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }
}


