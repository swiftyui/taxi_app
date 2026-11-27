import 'dart:math' as math;

/// Matches each word in a destination query, including adjacent-letter swaps.
class DestinationQuery {
  DestinationQuery(String text) : normalized = normalize(text);

  final String normalized;
  late final List<String> _words = normalized.split(' ');
  final Map<(String, String), int?> _wordScores = {};

  static final _apostrophes = RegExp("['’]");
  static final _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static final _digits = RegExp(r'[0-9]');
  static const _accents = {
    'a': 'àáâãäå',
    'c': 'ç',
    'e': 'èéêë',
    'i': 'ìíîï',
    'n': 'ñ',
    'o': 'òóôõö',
    'u': 'ùúûü',
    'y': 'ýÿ',
  };
  static final _foldedLetters = {
    for (final group in _accents.entries)
      for (final rune in group.value.runes) rune: group.key.codeUnitAt(0),
  };

  static String normalize(String text) => String.fromCharCodes(
    text.toLowerCase().runes.map((rune) => _foldedLetters[rune] ?? rune),
  ).replaceAll(_apostrophes, '').replaceAll(_separators, ' ').trim();

  /// Lower scores are closer matches. A null score means a word did not match.
  int? score(String text) {
    if (normalized.isEmpty) {
      return null;
    }
    final candidate = normalize(text);
    if (candidate == normalized) {
      return 0;
    }
    if (candidate.startsWith(normalized)) {
      return 2;
    }
    final words = candidate.split(' ');
    var total = 5;
    for (final word in _words) {
      int? best;
      for (final other in words) {
        final score = _wordScores.putIfAbsent((
          word,
          other,
        ), () => _scoreWord(word, other));
        if (score != null && (best == null || score < best)) {
          best = score;
        }
      }
      if (best == null) {
        return null;
      }
      total += best;
    }
    return total;
  }

  static int? _scoreWord(String query, String candidate) {
    if (query == candidate) {
      return 0;
    }
    if (candidate.startsWith(query)) {
      return 2;
    }
    if (_digits.hasMatch(query) || _digits.hasMatch(candidate)) {
      return null;
    }
    if (query.length >= 3 && candidate.contains(query)) {
      return 4;
    }
    final tolerance = query.length < 3 ? 0 : (query.length < 7 ? 1 : 2);
    if (tolerance == 0) {
      return null;
    }
    final lengthDifference = candidate.length - query.length;
    if (lengthDifference.abs() <= tolerance) {
      final edits = _editDistance(query, candidate);
      if (edits <= tolerance) {
        return 8 + 3 * edits;
      }
    }
    if (query.length >= 4 && lengthDifference > 0 && query[0] == candidate[0]) {
      final prefixEdits = _editDistance(
        query,
        candidate.substring(0, query.length),
      );
      if (prefixEdits <= tolerance) {
        return 12 + 3 * prefixEdits;
      }
    }
    return null;
  }

  static int _editDistance(String query, String candidate) {
    var previous = List<int>.generate(candidate.length + 1, (index) => index);
    var beforePrevious = List<int>.filled(previous.length, 0);
    var current = List<int>.filled(previous.length, 0);
    for (var row = 1; row <= query.length; row++) {
      current[0] = row;
      for (var column = 1; column <= candidate.length; column++) {
        final cost = query[row - 1] == candidate[column - 1] ? 0 : 1;
        var edits = math.min(
          previous[column - 1] + cost,
          math.min(previous[column] + 1, current[column - 1] + 1),
        );
        if (row > 1 &&
            column > 1 &&
            query[row - 1] == candidate[column - 2] &&
            query[row - 2] == candidate[column - 1]) {
          edits = math.min(edits, beforePrevious[column - 2] + 1);
        }
        current[column] = edits;
      }
      final reusable = beforePrevious;
      beforePrevious = previous;
      previous = current;
      current = reusable;
    }
    return previous.last;
  }
}
