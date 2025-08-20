import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/services/desktop_file_dialog_service.dart';

void main() {
  group('DesktopFileDialogService', () {
    late DesktopFileDialogService service;
    late List<MethodCall> methodCalls;

    setUp(() {
      service = DesktopFileDialogService();
      methodCalls = [];
      
      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('cherry_note/file_dialog'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'pickFile':
              return '/path/to/selected/file.md';
            case 'pickFiles':
              return ['/path/to/file1.md', '/path/to/file2.md'];
            case 'pickFolder':
              return '/path/to/selected/folder';
            case 'saveFile':
              return '/path/to/save/file.md';
            case 'showMessageDialog':
              return true;
            case 'showConfirmationDialog':
              return true;
            case 'openFileInDefaultApp':
              return true;
            case 'showFileInFileManager':
              return true;
            case 'getDocumentsDirectory':
              return '/home/user/Documents';
            case 'getDownloadsDirectory':
              return '/home/user/Downloads';
            default:
              throw PlatformException(
                code: 'UNIMPLEMENTED',
                message: 'Method ${methodCall.method} not implemented',
              );
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('cherry_note/file_dialog'),
        null,
      );
    });

    test('pickFile should call native method with correct parameters', () async {
      final result = await service.pickFile(
        title: 'Select Note',
        allowedExtensions: ['md', 'txt'],
        initialDirectory: '/home/user/Documents',
      );
      
      expect(result, equals('/path/to/selected/file.md'));
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('pickFile'));
      expect(methodCalls.first.arguments['title'], equals('Select Note'));
      expect(methodCalls.first.arguments['allowedExtensions'], equals(['md', 'txt']));
      expect(methodCalls.first.arguments['initialDirectory'], equals('/home/user/Documents'));
    });

    test('pickFiles should call native method and return multiple files', () async {
      final result = await service.pickFiles(
        title: 'Select Notes',
        allowedExtensions: ['md'],
      );
      
      expect(result, equals(['/path/to/file1.md', '/path/to/file2.md']));
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('pickFiles'));
    });

    test('pickFolder should call native method', () async {
      final result = await service.pickFolder(
        title: 'Select Folder',
        initialDirectory: '/home/user',
      );
      
      expect(result, equals('/path/to/selected/folder'));
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('pickFolder'));
    });

    test('saveFile should call native method with correct parameters', () async {
      final result = await service.saveFile(
        title: 'Save Note',
        defaultName: 'my-note.md',
        allowedExtensions: ['md'],
      );
      
      expect(result, equals('/path/to/save/file.md'));
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('saveFile'));
      expect(methodCalls.first.arguments['defaultName'], equals('my-note.md'));
    });

    test('showMessageDialog should call native method', () async {
      final result = await service.showMessageDialog(
        title: 'Information',
        message: 'File saved successfully',
        okButtonText: 'OK',
        showCancel: false,
      );
      
      expect(result, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('showMessageDialog'));
      expect(methodCalls.first.arguments['showCancel'], isFalse);
    });

    test('showConfirmationDialog should call native method', () async {
      final result = await service.showConfirmationDialog(
        title: 'Confirm',
        message: 'Delete this file?',
        yesButtonText: 'Delete',
        noButtonText: 'Cancel',
      );
      
      expect(result, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('showConfirmationDialog'));
    });

    test('openFileInDefaultApp should call native method', () async {
      final result = await service.openFileInDefaultApp('/path/to/file.md');
      
      expect(result, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('openFileInDefaultApp'));
      expect(methodCalls.first.arguments['filePath'], equals('/path/to/file.md'));
    });

    test('showFileInFileManager should call native method', () async {
      final result = await service.showFileInFileManager('/path/to/file.md');
      
      expect(result, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('showFileInFileManager'));
    });

    test('getDocumentsDirectory should call native method', () async {
      final result = await service.getDocumentsDirectory();
      
      expect(result, equals('/home/user/Documents'));
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('getDocumentsDirectory'));
    });

    test('getDownloadsDirectory should call native method', () async {
      final result = await service.getDownloadsDirectory();
      
      expect(result, equals('/home/user/Downloads'));
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('getDownloadsDirectory'));
    });

    test('should handle platform exceptions gracefully', () async {
      // Mock a platform exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('cherry_note/file_dialog'),
        (MethodCall methodCall) async {
          throw PlatformException(
            code: 'ERROR',
            message: 'Test error',
          );
        },
      );

      final result = await service.pickFile();
      expect(result, isNull);
    });
  });
}