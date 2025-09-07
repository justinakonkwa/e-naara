import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/wallet.dart';
import 'package:ecommerce/models/user.dart';

class WalletService extends ChangeNotifier {
  Wallet? _wallet;
  bool _isLoading = false;
  String? _error;

  Wallet? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Charger le portefeuille de l'utilisateur connecté
  Future<void> loadWallet() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await SupabaseService.getCurrentUser();
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer le portefeuille
      final response = await Supabase.instance.client
          .from('wallets')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        // Récupérer les transactions
        final transactionsResponse = await Supabase.instance.client
            .from('wallet_transactions')
            .select('*')
            .eq('wallet_id', response['id'])
            .order('created_at', ascending: false);

        final transactions = (transactionsResponse as List)
            .map((t) => WalletTransaction.fromJson(t))
            .toList();

        _wallet = Wallet.fromJson({
          ...response,
          'transactions': transactions,
        });
      } else {
        // Créer un nouveau portefeuille si il n'existe pas
        await _createWallet(user.id);
      }
    } catch (e) {
      print('❌ [WALLET] Erreur lors du chargement du portefeuille: $e');
      _error = 'Erreur lors du chargement du portefeuille: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Créer un nouveau portefeuille
  Future<void> _createWallet(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('wallets')
          .insert({
            'user_id': userId,
            'balance': 0.0,
            'currency': 'USD',
          })
          .select()
          .single();

      _wallet = Wallet.fromJson({
        ...response,
        'transactions': [],
      });
    } catch (e) {
      print('❌ [WALLET] Erreur lors de la création du portefeuille: $e');
      throw Exception('Erreur lors de la création du portefeuille');
    }
  }

  // Ajouter de l'argent au portefeuille (vente de produit)
  Future<void> addCredit(double amount, String description, {String? orderId}) async {
    try {
      if (_wallet == null) {
        throw Exception('Portefeuille non chargé');
      }

      // Créer la transaction
      final transactionResponse = await Supabase.instance.client
          .from('wallet_transactions')
          .insert({
            'wallet_id': _wallet!.id,
            'type': 'credit',
            'amount': amount,
            'description': description,
            'order_id': orderId,
            'status': 'completed',
          })
          .select()
          .single();

      // Mettre à jour le solde du portefeuille
      final newBalance = _wallet!.balance + amount;
      await Supabase.instance.client
          .from('wallets')
          .update({
            'balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _wallet!.id);

      // Mettre à jour le portefeuille local
      final transaction = WalletTransaction.fromJson(transactionResponse);
      _wallet = Wallet(
        id: _wallet!.id,
        userId: _wallet!.userId,
        balance: newBalance,
        currency: _wallet!.currency,
        createdAt: _wallet!.createdAt,
        updatedAt: DateTime.now(),
        transactions: [transaction, ..._wallet!.transactions],
      );

      notifyListeners();
    } catch (e) {
      print('❌ [WALLET] Erreur lors de l\'ajout de crédit: $e');
      throw Exception('Erreur lors de l\'ajout de crédit');
    }
  }

  // Retirer de l'argent du portefeuille
  Future<void> withdraw(double amount, String description) async {
    try {
      if (_wallet == null) {
        throw Exception('Portefeuille non chargé');
      }

      if (_wallet!.balance < amount) {
        throw Exception('Solde insuffisant');
      }

      // Créer la transaction
      final transactionResponse = await Supabase.instance.client
          .from('wallet_transactions')
          .insert({
            'wallet_id': _wallet!.id,
            'type': 'withdrawal',
            'amount': amount,
            'description': description,
            'status': 'pending',
          })
          .select()
          .single();

      // Mettre à jour le solde du portefeuille
      final newBalance = _wallet!.balance - amount;
      await Supabase.instance.client
          .from('wallets')
          .update({
            'balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _wallet!.id);

      // Mettre à jour le portefeuille local
      final transaction = WalletTransaction.fromJson(transactionResponse);
      _wallet = Wallet(
        id: _wallet!.id,
        userId: _wallet!.userId,
        balance: newBalance,
        currency: _wallet!.currency,
        createdAt: _wallet!.createdAt,
        updatedAt: DateTime.now(),
        transactions: [transaction, ..._wallet!.transactions],
      );

      notifyListeners();
    } catch (e) {
      print('❌ [WALLET] Erreur lors du retrait: $e');
      throw Exception('Erreur lors du retrait: $e');
    }
  }

  // Obtenir les statistiques du portefeuille
  Map<String, dynamic> getWalletStats() {
    if (_wallet == null) {
      return {
        'totalEarnings': 0.0,
        'totalWithdrawals': 0.0,
        'pendingWithdrawals': 0.0,
        'transactionCount': 0,
      };
    }

    double totalEarnings = 0.0;
    double totalWithdrawals = 0.0;
    double pendingWithdrawals = 0.0;

    for (final transaction in _wallet!.transactions) {
      if (transaction.isCredit) {
        totalEarnings += transaction.amount;
      } else if (transaction.isDebit) {
        totalWithdrawals += transaction.amount;
        if (transaction.status == TransactionStatus.pending) {
          pendingWithdrawals += transaction.amount;
        }
      }
    }

    return {
      'totalEarnings': totalEarnings,
      'totalWithdrawals': totalWithdrawals,
      'pendingWithdrawals': pendingWithdrawals,
      'transactionCount': _wallet!.transactions.length,
    };
  }

  // Vider le portefeuille
  void clearWallet() {
    _wallet = null;
    _error = null;
    notifyListeners();
  }
}
