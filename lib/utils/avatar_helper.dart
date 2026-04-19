import 'package:crypto/crypto.dart';

String getUserAvatar(String email, String? photo, {String? googlePhoto}) {
  final trimmedPhoto = photo?.trim() ?? '';
  if (trimmedPhoto.isNotEmpty) {
    return trimmedPhoto;
  }

  final trimmedGooglePhoto = googlePhoto?.trim() ?? '';
  if (trimmedGooglePhoto.isNotEmpty) {
    return trimmedGooglePhoto;
  }

  final normalizedEmail = email.trim().toLowerCase();
  final hash = md5.convert(normalizedEmail.codeUnits).toString();
  return 'https://www.gravatar.com/avatar/$hash?s=200&d=identicon';
}
