import 'package:characters/characters.dart';

/// String extension helpers.
extension StringExtensions on String {
  /// Returns a 1–2 character initials string from a full name (e.g. 'John Doe' → 'JD').
  String get initials {
    final cleaned = toValidUtf16().trim();
    if (cleaned.isEmpty) return '?';

    final chars = cleaned.characters;
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length == 1) {
      return chars.first.toUpperCase();
    }

    final first = words.first.characters.first;
    final last = words.last.characters.first;
    return '$first$last'.toUpperCase();
  }

  /// Removes unpaired UTF-16 surrogate characters that crash Flutter text rendering.
  String toValidUtf16() {
    final units = codeUnits;
    final buffer = StringBuffer();

    for (var i = 0; i < units.length; i++) {
      final unit = units[i];

      if (unit >= 0xD800 && unit <= 0xDBFF) {
        if (i + 1 < units.length) {
          final next = units[i + 1];
          if (next >= 0xDC00 && next <= 0xDFFF) {
            buffer.writeCharCode(unit);
            buffer.writeCharCode(next);
            i++;
            continue;
          }
        }
        continue;
      }

      if (unit >= 0xDC00 && unit <= 0xDFFF) {
        continue;
      }

      buffer.writeCharCode(unit);
    }

    return buffer.toString().characters.toString();
  }

  /// Returns only the digit characters from the string.
  String get digitsOnly => replaceAll(RegExp(r'\D'), '');
}
