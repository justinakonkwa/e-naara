import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/services/auth_service.dart';

class SessionRestoreWidget extends StatefulWidget {
  final Widget child;

  const SessionRestoreWidget({
    super.key,
    required this.child,
  });

  @override
  State<SessionRestoreWidget> createState() => _SessionRestoreWidgetState();
}

class _SessionRestoreWidgetState extends State<SessionRestoreWidget> {
  bool _isRestoring = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final authService = context.read<AuthService>();
      
      // Attendre un peu pour laisser le temps à Supabase de restaurer la session
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Vérifier si une session existe et la restaurer si nécessaire
      if (authService.isAuthenticated) {
        print('✅ [SESSION] Session restaurée automatiquement');
      } else {
        print('ℹ️ [SESSION] Aucune session à restaurer');
      }
    } catch (e) {
      print('❌ [SESSION] Erreur lors de la restauration: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoring) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Restauration de la session...'),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}


