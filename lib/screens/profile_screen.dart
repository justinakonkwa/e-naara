import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/services/auth_service.dart';
import 'package:ecommerce/screens/order_history_screen.dart';
import 'package:ecommerce/models/user_role.dart';
import 'package:ecommerce/services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final currentRole = UserRoleManager.currentRole;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Veuillez vous connecter'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du profil
            _buildProfileHeader(theme, user),
            const SizedBox(height: 32),

            // Informations du compte
            _buildAccountSection(theme, user),
            const SizedBox(height: 24),

            // Rôle actuel
            _buildRoleSection(theme, currentRole),
            const SizedBox(height: 24),

            // Menu principal
            _buildMainMenu(theme),
            const SizedBox(height: 24),

            // Bouton de déconnexion
            _buildLogoutButton(theme, authService),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
            child: Icon(
              Icons.person,
              size: 40,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getUserRoleDisplayName(user),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(ThemeData theme, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations du compte',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(theme, 'Nom complet', user.fullName),
        const SizedBox(height: 8),
        _buildInfoCard(theme, 'Email', user.email),
        if (user.phoneNumber != null) ...[
          const SizedBox(height: 8),
          _buildInfoCard(theme, 'Téléphone', user.phoneNumber!),
        ],
        const SizedBox(height: 8),
        _buildInfoCard(theme, 'Membre depuis', _formatDate(user.createdAt)),
      ],
    );
  }

  Widget _buildRoleSection(ThemeData theme, UserRole? currentRole) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rôle actuel',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getRoleIcon(currentRole),
                color: _getRoleColor(currentRole),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentRole?.displayName ?? 'Non défini',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRoleDescription(currentRole),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (currentRole != null)
                IconButton(
                  onPressed: _showRoleChangeDialog,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Changer de rôle',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainMenu(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuItem(
          theme,
          'Mes Commandes',
          Icons.shopping_bag,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const OrderHistoryScreen(),
            ),
          ),
        ),
        if (UserRoleManager.isAdmin)
          _buildMenuItem(
            theme,
            'Dashboard Livreur',
            Icons.dashboard,
            () {
              // Navigation vers le dashboard livreur
              // TODO: Implémenter la navigation
            },
          ),
        _buildMenuItem(
          theme,
          'Paramètres',
          Icons.settings,
          () {
            // Navigation vers les paramètres
            // TODO: Implémenter la navigation
          },
        ),
        _buildMenuItem(
          theme,
          'Aide et Support',
          Icons.help,
          () {
            // Navigation vers l'aide
            // TODO: Implémenter la navigation
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton(ThemeData theme, AuthService authService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _logout(authService),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Se déconnecter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    ThemeData theme,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getUserRoleDisplayName(dynamic user) {
    try {
      if (user == null) return 'Client';
      
      // Vérifier si user a une propriété role
      if (user.role == null) return 'Client';
      
      // Vérifier si role a une propriété displayName
      if (user.role.displayName != null) {
        return user.role.displayName;
      }
      
      // Fallback basé sur le type de role
      if (user.role is UserRole) {
        return user.role.displayName;
      }
      
      return 'Client';
    } catch (e) {
      return 'Client';
    }
  }

  IconData _getRoleIcon(UserRole? role) {
    switch (role) {
      case UserRole.user:
        return Icons.shopping_cart;
      case UserRole.driver:
        return Icons.local_shipping;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.user:
        return Colors.green;
      case UserRole.driver:
        return Colors.blue;
      case UserRole.admin:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDescription(UserRole? role) {
    switch (role) {
      case UserRole.user:
        return 'Accès aux fonctionnalités client';
      case UserRole.driver:
        return 'Accès aux fonctionnalités de livraison';
      case UserRole.admin:
        return 'Accès complet à la plateforme';
      default:
        return 'Rôle non défini';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showRoleChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer de rôle'),
        content: const Text(
          'Pour changer de rôle, veuillez contacter l\'administrateur ou vous reconnecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(AuthService authService) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}