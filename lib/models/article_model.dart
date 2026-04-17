import 'dart:developer';

class Article {
  final int? id;
  final String? title;
  final String? excerpt;
  final String? content;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? link;
  final String? author;
  final DateTime? date;
  final List<int> categoryIds;

  Article({
    this.id,
    this.title,
    this.excerpt,
    this.content,
    this.imageUrl,
    this.thumbnailUrl,
    this.link,
    this.author,
    this.date,
    this.categoryIds = const [],
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    String? getRendered(dynamic obj) {
      if (obj is Map && obj.containsKey('rendered')) {
        return obj['rendered'].toString();
      }
      if (obj is String) {
        return obj;
      }
      return null;
    }

    String? featuredImage;
    String? thumbnailImage;

    try {
      if (json.containsKey('_embedded') &&
          json['_embedded'] is Map &&
          (json['_embedded'] as Map).containsKey('wp:featuredmedia')) {
        final media = json['_embedded']['wp:featuredmedia'] as List;
        if (media.isNotEmpty && media[0] is Map) {
          final mediaItem = media[0] as Map;
          if (mediaItem.containsKey('source_url')) {
            featuredImage = mediaItem['source_url'] as String?;
          }
          if (mediaItem.containsKey('media_details') &&
              (mediaItem['media_details'] as Map).containsKey('sizes') &&
              (mediaItem['media_details']['sizes'] as Map).containsKey('thumbnail')) {
            thumbnailImage = mediaItem['media_details']['sizes']['thumbnail']['source_url'] as String?;
          }
        }
      }
    } catch (e) {
      log('Error parsing WP image: $e');
    }

    if (featuredImage == null) {
      if (json['image'] != null) {
        featuredImage = json['image'];
      } else if (json['image_url'] != null) featuredImage = json['image_url'];
      else if (json['imageUrl'] != null) featuredImage = json['imageUrl'];
      thumbnailImage ??= featuredImage;
    }

    int? parsedId;
    if (json['id'] is int) {
      parsedId = json['id'];
    } else if (json['id'] is String) {
      parsedId = int.tryParse(json['id']);
    }

    String? authorName;
    try {
        if (json.containsKey('_embedded') &&
            json['_embedded'] is Map &&
            (json['_embedded'] as Map).containsKey('author')) {
            final authorList = json['_embedded']['author'] as List;
            if (authorList.isNotEmpty && authorList[0] is Map) {
                authorName = authorList[0]['name'] as String?;
            }
        }
    } catch (e) {
        log('Error parsing author name: $e');
    }

    final parsedCategories = <int>[];
    final rawCategories = json['categories'];
    if (rawCategories is List) {
      for (final category in rawCategories) {
        if (category is int) {
          parsedCategories.add(category);
        } else if (category is String) {
          final parsed = int.tryParse(category);
          if (parsed != null) {
            parsedCategories.add(parsed);
          }
        }
      }
    }

    return Article(
      id: parsedId,
      title: getRendered(json['title']),
      excerpt: getRendered(json['excerpt']),
      content: getRendered(json['content']),
      imageUrl: featuredImage,
      thumbnailUrl: thumbnailImage,
      link: json['link'] as String?,
      author: authorName ?? json['author_name'] ?? json['author'] as String?,
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      categoryIds: parsedCategories,
    );
  }


  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      title: map['title'] as String?,
      excerpt: map['excerpt'] as String?,
      content: map['content'] as String?,
      imageUrl: map['imageUrl'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      link: map['link'] as String?,
      author: map['author'] as String?,
      date: map['date'] != null ? DateTime.tryParse(map['date']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'link': link,
      'author': author,
      'date': date?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => {
    ...toMap(),
    'categories': categoryIds,
  };
}
