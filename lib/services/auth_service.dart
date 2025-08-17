import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/user.dart';
import 'package:ecommerce/models/user_role.dart';

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Écoute les changements d'authentification
    SupabaseService.authStateChanges.listen((data) async {
      print('🔄 [AUTH] Événement d\'authentification: ${data.event}');
      
      if (data.event == AuthChangeEvent.signedIn || 
          data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.initialSession) {
        await _loadCurrentUser();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        UserRoleManager.clearRole();
        notifyListeners();
      }
    });
    
    // Vérifier s'il y a une session existante au démarrage
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    try {
      print('🔍 [AUTH] Vérification de la session existante...');
      final currentSession = SupabaseService.getCurrentSession();
      
      if (currentSession != null) {
        print('✅ [AUTH] Session existante trouvée, chargement de l\'utilisateur...');
        await _loadCurrentUser();
      } else {
        print('ℹ️ [AUTH] Aucune session existante');
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('❌ [AUTH] Erreur lors de la vérification de session: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('👤 [AUTH] Chargement de l\'utilisateur actuel...');
      _currentUser = await SupabaseService.getCurrentUser();
      
      if (_currentUser != null) {
        print('✅ [AUTH] Utilisateur chargé: ${_currentUser!.email}');
        print('🎭 [AUTH] Rôle utilisateur: ${_currentUser!.role?.displayName ?? 'Client'}');
        
        // Mettre à jour le gestionnaire de rôles
        UserRoleManager.setRole(_currentUser!.role, _currentUser!.id);
        
        _error = null;
      } else {
        print('⚠️ [AUTH] Aucun utilisateur trouvé');
        _error = 'Aucun utilisateur trouvé';
      }
    } catch (e) {
      print('❌ [AUTH] Erreur lors du chargement de l\'utilisateur: $e');
      _error = 'Erreur lors du chargement de l\'utilisateur: $e';
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      print('🔄 [AUTH] Début de l\'inscription pour: $email');
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('📧 [AUTH] Création du compte pour: $email');
      // Création du compte utilisateur
      final authResponse = await SupabaseService.signUp(
        email: email,
        password: password,
      );

      if (authResponse?.user == null) {
        print('❌ [AUTH] Échec de la création du compte');
        _error = 'Erreur lors de la création du compte';
        return false;
      }

      print('✅ [AUTH] Compte créé avec succès');
      
      // Créer le profil utilisateur dans notre base de données
      _currentUser = await SupabaseService.createUserWithId(
        userId: authResponse!.user!.id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      if (_currentUser == null) {
        print('❌ [AUTH] Échec de la création du profil utilisateur');
        _error = 'Erreur lors de la création du profil utilisateur';
        return false;
      }

      print('✅ [AUTH] Inscription complète réussie');
      return true;
    } catch (e) {
      print('💥 [AUTH] Exception lors de l\'inscription: $e');
      _error = 'Erreur lors de l\'inscription: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final authResponse = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (authResponse?.user == null) {
        _error = 'Email ou mot de passe incorrect';
        return false;
      }

      await _loadCurrentUser();
      return _currentUser != null;
    } catch (e) {
      _error = 'Erreur lors de la connexion: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🚪 [AUTH] Déconnexion...');
      await SupabaseService.signOut();
      _currentUser = null;
      _error = null;
      print('✅ [AUTH] Déconnexion réussie');
    } catch (e) {
      print('❌ [AUTH] Erreur lors de la déconnexion: $e');
      _error = 'Erreur lors de la déconnexion: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshSession() async {
    try {
      print('🔄 [AUTH] Rafraîchissement de la session...');
      final success = await SupabaseService.refreshSession();
      
      if (success) {
        await _loadCurrentUser();
        print('✅ [AUTH] Session rafraîchie avec succès');
      } else {
        print('❌ [AUTH] Échec du rafraîchissement de session');
      }
      
      return success;
    } catch (e) {
      print('❌ [AUTH] Erreur lors du rafraîchissement: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;

      final success = await SupabaseService.updateUser(updates);
      
      if (success) {
        await _loadCurrentUser();
      }

      return success;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du profil: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      print('🔐 [AUTH] Vérification OTP pour: $email');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final authResponse = await SupabaseService.verifyOTP(
        email: email,
        token: token,
      );

      if (authResponse?.user == null) {
        print('❌ [AUTH] Échec de la vérification OTP');
        _error = 'Code OTP invalide';
        return false;
      }

      print('✅ [AUTH] OTP vérifié, utilisateur connecté: ${authResponse!.user!.id}');
      
      // L'utilisateur est maintenant connecté, créer le profil
      _currentUser = await SupabaseService.createUser(
        email: email,
        firstName: '', // Ces données devront être récupérées ou stockées temporairement
        lastName: '',
        phoneNumber: null,
      );

      if (_currentUser == null) {
        print('❌ [AUTH] Échec de la création du profil utilisateur après OTP');
        _error = 'Erreur lors de la création du profil utilisateur';
        return false;
      }

      print('✅ [AUTH] Inscription complète réussie après OTP');
      return true;
    } catch (e) {
      print('💥 [AUTH] Exception lors de la vérification OTP: $e');
      _error = 'Erreur lors de la vérification: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> checkAuthenticationStatus() async {
    try {
      await _loadCurrentUser();
      return _currentUser != null;
    } catch (e) {
      return false;
    }
  }
}
