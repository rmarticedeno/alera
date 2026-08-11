import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHub workflow configuration', () {
    test('keeps every test workflow and one release workflow', () {
      final workflows = Directory('.github/workflows')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .toList()
        ..sort();

      expect(workflows, <String>[
        'cloud.yml',
        'landing.yml',
        'merge-queue.yml',
        'pr.yml',
        'release-cut.yml',
        'startup-performance.yml',
      ]);
    });

    test('keeps all pull request and merge queue test gates', () {
      final pr = File('.github/workflows/pr.yml').readAsStringSync();
      final cloud = File('.github/workflows/cloud.yml').readAsStringSync();
      final landing = File('.github/workflows/landing.yml').readAsStringSync();
      final queue = File(
        '.github/workflows/merge-queue.yml',
      ).readAsStringSync();
      final performance = File(
        '.github/workflows/startup-performance.yml',
      ).readAsStringSync();

      expect(pr, contains('flutter test --coverage'));
      expect(pr, contains('cargo test --workspace'));
      expect(pr, contains('working-directory: mobile'));
      expect(cloud, contains('cargo test --workspace'));
      expect(cloud, contains('bun test'));
      expect(landing, contains('bun run build'));
      expect(queue, contains('flutter test test/golden'));
      expect(queue, contains('integration_test/*_test.dart'));
      expect(queue, isNot(contains('desktop_builds:')));
      expect(performance, contains('alera_performance.dart'));
    });

    test('builds only Windows x64 and Android release artifacts', () {
      final workflow = File(
        '.github/workflows/release-cut.yml',
      ).readAsStringSync();

      expect(workflow, contains('build_windows_x64:'));
      expect(workflow, contains('runs-on: windows-latest'));
      expect(workflow, contains("RUNNER_ARCH -ne 'X64'"));
      expect(workflow, contains('flutter build windows --release'));
      expect(workflow, contains('verify_desktop_runtime_bundle.dart'));
      expect(workflow, contains('build_android:'));
      expect(workflow, contains('flutter build apk --release'));
      expect(workflow, contains('flutter build apk --release --split-per-abi'));

      for (final removed in <String>[
        'macos-latest',
        'build_runtime_cross:',
        'package_runtime:',
        'Package Linux release',
        'publish_packages:',
        'publish_chocolatey:',
      ]) {
        expect(workflow, isNot(contains(removed)));
      }
    });

    test('publishes the complete Windows x64 asset set', () {
      final workflow = File(
        '.github/workflows/release-cut.yml',
      ).readAsStringSync();

      expect(
        workflow,
        contains('alera-\$env:RELEASE_VERSION-windows-x64.zip'),
      );
      expect(
        workflow,
        contains('alera-\$env:RELEASE_VERSION-windows-x64.tar.gz'),
      );
      expect(workflow, contains('Get-FileHash -Algorithm SHA256'));
      expect(workflow, contains('windows-x64-release-assets'));
    });

    test('publishes secret-free debug-signed Android APKs', () {
      final workflow = File(
        '.github/workflows/release-cut.yml',
      ).readAsStringSync();

      expect(workflow, contains('test ! -f android/key.properties'));
      expect(workflow, contains('apksigner'));
      expect(workflow, contains('android-arm64-v8a.apk'));
      expect(workflow, contains('android-armeabi-v7a.apk'));
      expect(workflow, contains('android-x86_64.apk'));
      expect(workflow, contains('sha256sum -c ./*.sha256'));

      for (final forbidden in <String>[
        r'${{ secrets.',
        r'${{ vars.',
        'ALERA_ANDROID_KEYSTORE',
        'ALERA_FIREBASE_',
      ]) {
        expect(workflow, isNot(contains(forbidden)));
      }
    });

    test('creates verified permanent GitHub Releases', () {
      final workflow = File(
        '.github/workflows/release-cut.yml',
      ).readAsStringSync();
      final publish = workflow.substring(workflow.indexOf('  publish:'));

      expect(publish, contains('- build_windows_x64'));
      expect(publish, contains('- build_android'));
      expect(publish, contains('Verify selected release assets'));
      expect(publish, contains('gh release create'));
      expect(publish, contains('--generate-notes'));
      expect(publish, contains('--prerelease'));
      expect(publish, isNot(contains('--draft')));
      expect(publish, isNot(contains('aws s3')));
      expect(publish, isNot(contains('release upload')));
    });
  });
}
