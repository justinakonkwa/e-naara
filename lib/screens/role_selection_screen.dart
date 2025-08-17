import 'package:flutter/material.dart';
import 'package:ecommerce/models/user_role.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/screens/main_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String userId;
  final String email;

  const RoleSelectionScreen({
    Key? key,
    required this.userId,
    required this.email,
  }) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.user;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir votre rôle'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            
            // En-tête
            const Icon(
              Icons.person_add,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            
            Text(
              'Bienvenue ${widget.email} !',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              'Choisissez votre rôle pour continuer',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Options de rôle
            _buildRoleCard(
              UserRole.user,
              'Client',
              'Achetez des produits et suivez vos commandes',
              Icons.shopping_cart,
              Colors.green,
            ),
            const SizedBox(height: 16),
            
            _buildRoleCard(
              UserRole.driver,
              'Livreur',
              'Livrez les commandes et gérez les livraisons',
              Icons.local_shipping,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            
            _buildRoleCard(
              UserRole.admin,
              'Administrateur',
              'Gérez l\'ensemble de la plateforme',
              Icons.admin_panel_settings,
              Colors.purple,
            ),
            
            const Spacer(),
            
            // Bouton de confirmation
            ElevatedButton(
              onPressed: _isLoading ? null : _confirmRole,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
                  : Text(
                      'Confirmer le rôle ${_selectedRole.displayName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    UserRole role,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRole() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mettre à jour le rôle de l'utilisateur dans la base de données
      final success = await SupabaseService.updateUserRole(
        widget.userId,
        _selectedRole,
      );

      if (success) {
        // Mettre à jour le gestionnaire de rôles local
        UserRoleManager.setRole(_selectedRole, widget.userId);
        
        // Naviguer vers l'écran principal
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur lors de la mise à jour du rôle'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [ROLE] Erreur lors de la confirmation du rôle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
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
