import 'dart:convert';
import 'dart:developer';
import 'package:the_chenab_times/models/article_model.dart';

class NotificationModel {
  final int? id;
  final String notificationId;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime receivedAt;
  final Article? article;
  final int? postId; // [NEW] Added to store the WordPress Post ID
  final String? postUrl;

  NotificationModel({
    this.id,
    required this.notificationId,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.receivedAt,
    this.article,
    this.postId,
    this.postUrl,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    Article? parsedArticle;

    if (map['article_data'] != null) {
      try {
        dynamic articleData = map['article_data'];
        if (articleData is String) {
          final decoded = json.decode(articleData);
          if (decoded is Map<String, dynamic>) {
            parsedArticle = Article.fromJson(decoded);
          }
        } else if (articleData is Map<String, dynamic>) {
          parsedArticle = Article.fromJson(articleData);
        }
      } catch (e) {
        log('Error parsing article_data in NotificationModel: $e');
      }
    }

    return NotificationModel(
      id: map['id'],
      notificationId: map['notification_id'] ?? '',
      title: map['title'] ?? 'No Title',
      body: map['body'] ?? 'No Body',
      imageUrl: map['image_url']?.toString(),
      receivedAt: map['received_at'] != null
          ? DateTime.tryParse(map['received_at']) ?? DateTime.now()
          : DateTime.now(),
      article: parsedArticle,
      postId: _parsePostId(map['post_id']),
      postUrl: map['post_url']?.toString(),
    );
  }

  static int? _parsePostId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notification_id': notificationId,
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'received_at': receivedAt.toIso8601String(),
      'article_data': article != null ? json.encode(article!.toJson()) : null,
      'post_id': postId, // Added to map
      'post_url': postUrl,
    };
  }
}
