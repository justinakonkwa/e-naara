// Script de diagnostic pour les problèmes de connexion Supabase
// À utiliser dans le code pour diagnostiquer les problèmes

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce/config/supabase_config.dart';

class SupabaseDiagnostic {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Test de connexion basique
  static Future<bool> testBasicConnection() async {
    try {
      print('🔍 [DIAGNOSTIC] Test de connexion basique...');
      
      // Test simple de requête
      final response = await _supabase
          .from('products')
          .select('count')
          .limit(1);
      
      print('✅ [DIAGNOSTIC] Connexion basique réussie');
      return true;
    } catch (e) {
      print('❌ [DIAGNOSTIC] Erreur de connexion basique: $e');
      return false;
    }
  }

  /// Test de l'authentification
  static Future<bool> testAuthentication() async {
    try {
      print('🔍 [DIAGNOSTIC] Test de l\'authentification...');
      
      final user = _supabase.auth.currentUser;
      if (user != null) {
        print('✅ [DIAGNOSTIC] Utilisateur authentifié: ${user.email}');
        return true;
      } else {
        print('⚠️ [DIAGNOSTIC] Aucun utilisateur authentifié');
        return false;
      }
    } catch (e) {
      print('❌ [DIAGNOSTIC] Erreur d\'authentification: $e');
      return false;
    }
  }

  /// Test de la table users
  static Future<bool> testUsersTable() async {
    try {
      print('🔍 [DIAGNOSTIC] Test de la table users...');
      
      final response = await _supabase
          .from('users')
          .select('count')
          .limit(1);
      
      print('✅ [DIAGNOSTIC] Table users accessible');
      return true;
    } catch (e) {
      print('❌ [DIAGNOSTIC] Erreur table users: $e');
      return false;
    }
  }

  /// Test de la table chats
  static Future<bool> testChatsTable() async {
    try {
      print('🔍 [DIAGNOSTIC] Test de la table chats...');
      
      final response = await _supabase
          .from('chats')
          .select('count')
          .limit(1);
      
      print('✅ [DIAGNOSTIC] Table chats accessible');
      return true;
    } catch (e) {
      print('❌ [DIAGNOSTIC] Erreur table chats: $e');
      return false;
    }
  }

  /// Test complet de diagnostic
  static Future<Map<String, bool>> runFullDiagnostic() async {
    print('🚀 [DIAGNOSTIC] Démarrage du diagnostic complet...');
    
    final results = <String, bool>{};
    
    results['basic_connection'] = await testBasicConnection();
    results['authentication'] = await testAuthentication();
    results['users_table'] = await testUsersTable();
    results['chats_table'] = await testChatsTable();
    
    print('📊 [DIAGNOSTIC] Résultats du diagnostic:');
    results.forEach((test, result) {
      print('  ${result ? '✅' : '❌'} $test');
    });
    
    return results;
  }

  /// Vérification de la configuration
  static void checkConfiguration() {
    print('🔧 [DIAGNOSTIC] Vérification de la configuration...');
    
    try {
      // Utiliser la configuration depuis le fichier de config
      final url = SupabaseConfig.supabaseUrl;
      final key = SupabaseConfig.supabaseAnonKey;
      
      print('  URL: $url');
      print('  Key: ${key.substring(0, 20)}...');
      
      if (url.contains('ckocfgadkxbkiocyiirb')) {
        print('✅ [DIAGNOSTIC] URL correcte');
      } else {
        print('❌ [DIAGNOSTIC] URL incorrecte');
      }
      
      if (key.isNotEmpty) {
        print('✅ [DIAGNOSTIC] Clé présente');
      } else {
        print('❌ [DIAGNOSTIC] Clé manquante');
      }
    } catch (e) {
      print('❌ [DIAGNOSTIC] Erreur lors de la vérification de la configuration: $e');
    }
  }
}
