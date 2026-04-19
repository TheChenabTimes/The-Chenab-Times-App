import 'package:crypto/crypto.dart';

String getUserAvatar(String email, String? photo) {
  final trimmedPhoto = photo?.trim() ?? '';
  if (trimmedPhoto.isNotEmpty) {
    return trimmedPhoto;
  }

  final normalizedEmail = email.trim().toLowerCase();
  final hash = md5.convert(normalizedEmail.codeUnits).toString();
  return 'https://www.gravatar.com/avatar/$hash?s=200&d=identicon';
}
