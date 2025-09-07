import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/services/app_state.dart';
import 'package:ecommerce/models/chat.dart';
import 'package:ecommerce/screens/chat_screen.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/services/supabase_diagnostic.dart';
import 'package:ecommerce/widgets/shimmer_widgets.dart';
// import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> _chats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();
      final user = appState.currentUser;

      if (user != null) {
        // Charger les chats directement sans mise à jour des noms
        final chats = await appState.getUserChats();

        setState(() {
          _chats = chats;
          _isLoading = false;
        });

        // Mettre à jour les noms en arrière-plan si nécessaire
        if (chats.isNotEmpty) {
          _updateChatNamesInBackground(chats);
        }
      } else {
        setState(() {
          _error = 'Utilisateur non connecté';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des chats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateChatNamesInBackground(List<Chat> chats) async {
    try {
      final updatedChats = await _updateChatNames(chats);
      if (mounted) {
        setState(() {
          _chats = updatedChats;
        });
      }
    } catch (e) {
      print('❌ [CHAT] Erreur lors de la mise à jour des noms: $e');
    }
  }

  Future<void> _runDiagnostic() async {
    try {
      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exécution du diagnostic...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Vérifier la configuration
      SupabaseDiagnostic.checkConfiguration();

      // Exécuter le diagnostic complet
      final results = await SupabaseDiagnostic.runFullDiagnostic();

      // Afficher les résultats
      final successCount = results.values.where((result) => result).length;
      final totalCount = results.length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Diagnostic terminé: $successCount/$totalCount tests réussis'),
          backgroundColor:
              successCount == totalCount ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

      // Si le diagnostic révèle des problèmes, recharger les chats
      if (successCount == totalCount) {
        _loadChats();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du diagnostic: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<List<Chat>> _updateChatNames(List<Chat> chats) async {
    final updatedChats = <Chat>[];

    for (final chat in chats) {
      String customerName = chat.customerName;
      String sellerName = chat.sellerName;

      // Fonction pour valider un UUID
      bool isValidUUID(String? id) {
        if (id == null || id.isEmpty) return false;
        final uuidRegex = RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            caseSensitive: false);
        return uuidRegex.hasMatch(id);
      }

      // Mettre à jour les noms seulement si nécessaire
      if ((customerName == 'Client' || customerName.isEmpty) &&
          isValidUUID(chat.customerId)) {
        try {
          final fullName =
              await SupabaseService.getUserFullName(chat.customerId);
          if (fullName != null && fullName.isNotEmpty) {
            customerName = fullName;
          }
        } catch (e) {
          print('❌ [CHAT] Erreur lors de la récupération du nom du client: $e');
        }
      }

      if ((sellerName == 'Vendeur' ||
              sellerName == 'Vendeur par défaut' ||
              sellerName.isEmpty) &&
          isValidUUID(chat.sellerId)) {
        try {
          final fullName = await SupabaseService.getUserFullName(chat.sellerId);
          if (fullName != null && fullName.isNotEmpty) {
            sellerName = fullName;
          }
        } catch (e) {
          print(
              '❌ [CHAT] Erreur lors de la récupération du nom du vendeur: $e');
        }
      }

      // Créer un nouveau chat avec les noms mis à jour
      final updatedChat = chat.copyWith(
        customerName: customerName,
        sellerName: sellerName,
      );

      updatedChats.add(updatedChat);
    }

    return updatedChats;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'À l\'instant';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadChats,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _runDiagnostic,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Diagnostic',
          ),
        ],
      ),
      body: user == null
          ? _buildNotAuthenticated(theme)
          : _buildChatList(theme, user),
    );
  }

  Widget _buildNotAuthenticated(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Non connecté',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez vous connecter pour voir vos messages',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(ThemeData theme, user) {
    if (_isLoading) {
      return _buildShimmerList(theme);
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChats,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun message',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de conversations',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final isCustomer = chat.customerId == user.id;
          final otherUserName =
              isCustomer ? chat.sellerName : chat.customerName;

          return _buildChatCard(theme, chat, otherUserName, isCustomer);
        },
      ),
    );
  }

  Widget _buildChatCard(
      ThemeData theme, Chat chat, String otherUserName, bool isCustomer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(chat: chat),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image du produit avec badge de statut
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          chat.productImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.image_not_supported,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Badge de statut
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isCustomer
                              ? Icons.sell_rounded
                              : Icons.person_rounded,
                          size: 12,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Informations du chat
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec nom et badge de notification
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUserName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary
                                        .withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Nom du produit
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          chat.productName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Informations du rôle et temps
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCustomer
                                  ? theme.colorScheme.secondaryContainer
                                  : theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCustomer
                                      ? Icons.sell_rounded
                                      : Icons.person_rounded,
                                  size: 14,
                                  color: isCustomer
                                      ? theme.colorScheme.onSecondaryContainer
                                      : theme.colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCustomer ? 'Vendeur' : 'Client',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isCustomer
                                        ? theme.colorScheme.onSecondaryContainer
                                        : theme.colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatTimeAgo(chat.lastMessageAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6, // Afficher 6 cartes shimmer
      itemBuilder: (context, index) => const ChatCardShimmer(),
    );
  }

}
