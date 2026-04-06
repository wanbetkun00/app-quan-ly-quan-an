import 'dart:io';

import 'package:do_an_mon_quanlyquanan/services/excel_export_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const openFileChannel = MethodChannel('open_file');

  late Directory tempDir;
  late int openFileType;
  late String openFileMessage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('excel_export_test_');
    openFileType = 0;
    openFileMessage = 'done';

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return tempDir.path;
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(openFileChannel, (call) async {
          return '{"type":$openFileType,"message":"$openFileMessage"}';
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(openFileChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ExcelExportService', () {
    test('creates unique file paths on consecutive exports', () async {
      final service = ExcelExportService();
      final report = TestFixtures.report();
      final menuItems = [TestFixtures.menuItem()];

      final first = await service.exportReportToExcel(
        report: report,
        menuItems: menuItems,
      );
      final second = await service.exportReportToExcel(
        report: report,
        menuItems: menuItems,
      );

      expect(first.filePath, isNot(second.filePath));
      expect(await File(first.filePath).exists(), isTrue);
      expect(await File(second.filePath).exists(), isTrue);
    });

    test('includes open_file message in export result', () async {
      final service = ExcelExportService();
      final report = TestFixtures.report();
      final menuItems = [TestFixtures.menuItem()];

      openFileType = 1;
      openFileMessage = 'No app found';
      final result = await service.exportReportToExcel(
        report: report,
        menuItems: menuItems,
      );

      expect(result.openMessage, 'No app found');
      expect(await File(result.filePath).exists(), isTrue);
    });
  });
}
