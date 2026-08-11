import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _dataPath = 'landing/src/data/releases.json';
const String _downloadPage = 'landing/src/pages/download.astro';
const String _workflow = '.github/workflows/release-cut.yml';

void main() {
  group('landing release links', () {
    test('pins a stable version and a matching tag per product', () {
      final data = jsonDecode(File(_dataPath).readAsStringSync())
          as Map<String, dynamic>;

      final desktop = data['desktop'] as Map<String, dynamic>;
      final mobile = data['mobile'] as Map<String, dynamic>;
      void expectStableCore(Object? value) {
        final parts = value.toString().split('.');
        expect(parts, hasLength(3));
        for (final part in parts) {
          expect(int.tryParse(part), isNotNull);
        }
      }

      expectStableCore(desktop['version']);
      expectStableCore(mobile['version']);
      expect(desktop['tag'], 'v${desktop['version']}');
      expect(mobile['tag'], 'v${mobile['version']}-mobile');
    });

    test('keeps the existing upstream download page internally consistent', () {
      final page = File(_downloadPage).readAsStringSync();

      expect(page, contains(r'alera-${releases.desktop.version}-macos.tar.gz'));
      expect(
          page, contains(r'alera-${releases.desktop.version}-windows.tar.gz'));
      expect(page, contains(r'alera-${releases.mobile.version}-android.apk'));
      expect(
        page,
        contains(
          r'https://github.com/leynier/alera/releases/download/${tag}/${file}',
        ),
      );
    });

    test('fork workflow publishes Windows x64 and Android assets only', () {
      final workflow = File(_workflow).readAsStringSync();

      expect(
        workflow,
        contains('alera-\$env:RELEASE_VERSION-windows-x64.tar.gz'),
      );
      expect(workflow, contains('alera-\${RELEASE_VERSION}-android.apk'));
      expect(workflow, isNot(contains('macos.tar.gz')));
      expect(workflow, isNot(contains('linux-x64')));
    });
  });
}
