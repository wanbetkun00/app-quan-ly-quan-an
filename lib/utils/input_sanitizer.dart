class InputSanitizer {
  static String normalizeWhitespace(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String sanitizeName(String value) {
    return normalizeWhitespace(value);
  }

  static String sanitizeUsername(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '');
  }

  static String sanitizePassword(String value) {
    return value.trim();
  }

  static String sanitizeNotes(String value) {
    return normalizeWhitespace(value);
  }

  static String sanitizeSearchQuery(String value) {
    return value.trim();
  }

  static String sanitizeUrl(String value) {
    return value.trim();
  }
}
