import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps UI copy on-voice (see docs/09-design/voice.md). Scans every
/// single-quoted string literal under lib/ and fails on patterns the voice
/// guide bans, listing each offending file:line.
void main() {
  final literal = RegExp(r"'((?:[^'\\\n]|\\.)*)'");

  // Case-insensitive, whole-word matches.
  const bannedWords = [
    'gently',
    'journey',
    'heads-up',
    'no need to be exact',
    'beautifully',
    'legendary',
    'with care',
    'sideways',
    'kitchen',
    'said no',
    'thinking with you',
    'whenever you like',
    'please',
    'smart',
  ];
  final banned = RegExp(
    '\\b(${bannedWords.map(RegExp.escape).join('|')})\\b',
    caseSensitive: false,
  );

  List<String> scan() {
    final problems = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.contains('/e2e/'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('import ')) continue;
        if (line.contains('DateFormat(')) continue;
        for (final match in literal.allMatches(line)) {
          final text = match.group(1)!;
          if (text.startsWith('E2E')) continue;
          final where = '${file.path}:${i + 1}';
          if (text.contains('...')) problems.add('$where  "..." → use "…"');
          // A lone "—" is a placeholder for a missing value, which is fine.
          if (text.contains('—') && text.trim() != '—') {
            problems.add('$where  em dash in copy: $text');
          }
          if (text.contains(r"\'")) {
            problems.add('$where  straight apostrophe → use ’: $text');
          }
          final word = banned.firstMatch(text);
          if (word != null) {
            problems.add('$where  banned word "${word.group(0)}": $text');
          }
        }
      }
    }
    return problems;
  }

  test('UI copy follows the voice guide', () {
    final problems = scan();
    expect(problems, isEmpty, reason: '\n${problems.join('\n')}\n');
  });
}
