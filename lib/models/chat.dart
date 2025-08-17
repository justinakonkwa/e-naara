class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderType; // 'customer' ou 'seller'
  final String message;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? replyToMessageId; // ID du message auquel on répond
  final String? replyToMessageText; // Texte du message auquel on répond (pour affichage)

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.message,
    this.imageUrl,
    required this.timestamp,
    required this.isRead,
    this.type = MessageType.text,
    this.replyToMessageId,
    this.replyToMessageText,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderType: json['sender_type'],
      message: json['message'],
      imageUrl: json['image_url'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      replyToMessageId: json['reply_to_message_id'],
      replyToMessageText: json['reply_to_message_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_type': senderType,
      'message': message,
      'image_url': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'type': type.toString().split('.').last,
      'reply_to_message_id': replyToMessageId,
      'reply_to_message_text': replyToMessageText,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderType,
    String? message,
    String? imageUrl,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    String? replyToMessageId,
    String? replyToMessageText,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessageText: replyToMessageText ?? this.replyToMessageText,
    );
  }
}

enum MessageType {
  text,
  image,
  file,
  system,
}

class Chat {
  final String id;
  final String customerId;
  final String customerName;
  final String sellerId;
  final String sellerName;
  final String productId;
  final String productName;
  final String productImageUrl;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final bool isActive;
  final int unreadCount;
  final ChatStatus status;

  const Chat({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.sellerId,
    required this.sellerName,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.createdAt,
    required this.lastMessageAt,
    required this.isActive,
    required this.unreadCount,
    this.status = ChatStatus.active,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      sellerId: json['seller_id'],
      sellerName: json['seller_name'],
      productId: json['product_id'],
      productName: json['product_name'],
      productImageUrl: json['product_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      lastMessageAt: DateTime.parse(json['last_message_at']),
      isActive: json['is_active'] ?? true,
      unreadCount: json['unread_count'] ?? 0,
      status: ChatStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ChatStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'product_id': productId,
      'product_name': productName,
      'product_image_url': productImageUrl,
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
      'is_active': isActive,
      'unread_count': unreadCount,
      'status': status.toString().split('.').last,
    };
  }

  Chat copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? sellerId,
    String? sellerName,
    String? productId,
    String? productName,
    String? productImageUrl,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    bool? isActive,
    int? unreadCount,
    ChatStatus? status,
  }) {
    return Chat(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
    );
  }
}

enum ChatStatus {
  active,
  archived,
  blocked,
}

class ChatNotification {
  final String id;
  final String chatId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const ChatNotification({
    required this.id,
    required this.chatId,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatNotification.fromJson(Map<String, dynamic> json) {
    return ChatNotification(
      id: json['id'],
      chatId: json['chat_id'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }
}
