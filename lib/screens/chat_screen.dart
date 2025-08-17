import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/services/app_state.dart';
import 'package:ecommerce/models/chat.dart';
import 'package:ecommerce/widgets/chat_message_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
// import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({
    super.key,
    required this.chat,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Timer? _refreshTimer;
  
  // Variables pour la réponse aux messages
  ChatMessage? _replyingToMessage;
  final TextEditingController _replyTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _replyTextController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();
      final messages = await appState.getChatMessages(widget.chat.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final appState = context.read<AppState>();
      final user = appState.currentUser;
      if (user != null) {
        await appState.markChatMessagesAsRead(widget.chat.id, user.id);
      }
    } catch (e) {
      print('Erreur lors du marquage des messages: $e');
    }
  }

  void _startRefreshTimer() {
    // Rafraîchir les messages toutes les 3 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isLoading && mounted) {
        _refreshMessages();
      }
    });
  }

  Future<void> _refreshMessages() async {
    try {
      final appState = context.read<AppState>();
      final messages = await appState.getChatMessages(widget.chat.id);
      
      // Vérifier s'il y a de nouveaux messages
      if (messages.length != _messages.length) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Erreur lors du rafraîchissement des messages: $e');
    }
  }



  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final appState = context.read<AppState>();
      final user = appState.currentUser;
      
      if (user != null) {
        final isCustomer = widget.chat.customerId == user.id;
        final senderType = isCustomer ? 'customer' : 'seller';
        
        final sentMessage = await appState.sendChatMessage(
          chatId: widget.chat.id,
          senderId: user.id,
          senderName: user.fullName,
          senderType: senderType,
          message: messageText,
          replyToMessageId: _replyingToMessage?.id,
          replyToMessageText: _replyingToMessage?.message,
        );

        if (sentMessage != null) {
          // Ajouter le message à la liste locale immédiatement
          setState(() {
            _messages.add(sentMessage);
            _replyingToMessage = null; // Réinitialiser la réponse
          });
          _messageController.clear();
          _scrollToBottom();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isSending = true;
        });

        final appState = context.read<AppState>();
        final user = appState.currentUser;
        
        if (user != null) {
          final isCustomer = widget.chat.customerId == user.id;
          final senderType = isCustomer ? 'customer' : 'seller';
          
          final sentMessage = await appState.sendChatMessageWithImage(
            chatId: widget.chat.id,
            senderId: user.id,
            senderName: user.fullName,
            senderType: senderType,
            imageFile: File(image.path),
          );

          if (sentMessage != null) {
            // Ajouter le message à la liste locale immédiatement
            setState(() {
              _messages.add(sentMessage);
              _replyingToMessage = null; // Réinitialiser la réponse
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // Méthode pour répondre à un message
  void _replyToMessage(ChatMessage message) {
    setState(() {
      _replyingToMessage = message;
    });
    // Focus sur le champ de texte
    FocusScope.of(context).requestFocus(FocusNode());
  }

  // Méthode pour annuler la réponse
  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  // Méthode pour afficher le menu contextuel d'un message
  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Répondre'),
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier'),
              onTap: () {
                Navigator.pop(context);
                // Copier le texte dans le presse-papiers
                // Clipboard.setData(ClipboardData(text: message.message));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copié')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final isCustomer = user != null ? widget.chat.customerId == user.id : false;
    final otherUserName = isCustomer ? widget.chat.sellerName : widget.chat.customerName;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherUserName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.chat.productName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les messages',
          ),
          IconButton(
            onPressed: () {
              // TODO: Afficher les détails du produit
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête du produit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      widget.chat.productImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surface,
                        child: Icon(
                          Icons.image_not_supported,
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chat.productName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Conversation avec ${isCustomer ? 'le vendeur' : 'le client'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget(theme)
                    : _buildMessagesList(theme, user),
          ),

          // Zone de saisie
          _buildMessageInput(theme, user),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
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
            onPressed: _loadMessages,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ThemeData theme, user) {
    if (_messages.isEmpty) {
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
              'Commencez la conversation !',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMyMessage = user != null && message.senderId == user.id;
        
        return ChatMessageWidget(
          message: message,
          isCurrentUser: isMyMessage,
          onLongPress: () => _showMessageOptions(message),
        );
      },
    );
  }



  Widget _buildMessageInput(ThemeData theme, user) {
    return Column(
      children: [
        // Zone de réponse (si on répond à un message)
        if (_replyingToMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Réponse à ${_replyingToMessage!.senderName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _replyingToMessage!.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _cancelReply,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        
        // Zone de saisie principale
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              // Bouton pour ajouter une image
              IconButton(
                onPressed: _sendImage,
                icon: const Icon(Icons.image),
                color: theme.colorScheme.primary,
                tooltip: 'Ajouter une image',
              ),
              
              // Bouton pour prendre une photo
              IconButton(
                onPressed: () async {
                  try {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    
                    if (image != null) {
                      setState(() {
                        _isSending = true;
                      });

                      final appState = context.read<AppState>();
                      final user = appState.currentUser;
                      
                      if (user != null) {
                        final isCustomer = widget.chat.customerId == user.id;
                        final senderType = isCustomer ? 'customer' : 'seller';
                        
                        final sentMessage = await appState.sendChatMessageWithImage(
                          chatId: widget.chat.id,
                          senderId: user.id,
                          senderName: user.fullName,
                          senderType: senderType,
                          imageFile: File(image.path),
                        );

                        if (sentMessage != null) {
                          setState(() {
                            _messages.add(sentMessage);
                            _replyingToMessage = null;
                          });
                          _scrollToBottom();
                        }
                      }
                      
                      setState(() {
                        _isSending = false;
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de l\'envoi de l\'image: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    setState(() {
                      _isSending = false;
                    });
                  }
                },
                icon: const Icon(Icons.camera_alt),
                color: theme.colorScheme.primary,
                tooltip: 'Prendre une photo',
              ),
              
              // Champ de texte
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: _replyingToMessage != null 
                        ? 'Répondre au message...' 
                        : 'Tapez votre message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Bouton d'envoi
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

