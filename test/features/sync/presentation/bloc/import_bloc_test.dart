import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:cherry_note/features/sync/domain/services/import_service.dart';
import 'package:cherry_note/features/sync/presentation/bloc/import_bloc.dart';
import 'package:cherry_note/features/sync/presentation/bloc/import_event.dart';
import 'package:cherry_note/features/sync/presentation/bloc/import_state.dart';

import 'import_bloc_test.mocks.dart';

@GenerateMocks([ImportService])
void main() {
  group('ImportBloc', () {
    late ImportBloc importBloc;
    late MockImportService mockImportService;

    setUp(() {
      mockImportService = MockImportService();
      importBloc = ImportBloc(mockImportService);
    });

    tearDown(() {
      importBloc.close();
    });

    test('initial state is ImportInitial', () {
      expect(importBloc.state, equals(const ImportInitial()));
    });

    group('ImportFromFolderRequested', () {
      const localPath = '/test/import/path';
      const importOptions = ImportOptions(validateStructure: true);

      blocTest<ImportBloc, ImportState>(
        'emits [ImportInProgress, ImportSuccess] when import succeeds',
        build: () {
          when(mockImportService.isImporting).thenReturn(false);
          when(mockImportService.importFromFolder(
            localPath,
            options: importOptions,
            progressController: anyNamed('progressController'),
          )).thenAnswer((_) async => const ImportResult(
            success: true,
            importedFiles: 5,
            importedFolders: 2,
            skippedFiles: 0,
            errors: [],
            conflicts: [],
          ));
          return importBloc;
        },
        act: (bloc) => bloc.add(const ImportFromFolderRequested(
          localPath: localPath,
          options: importOptions,
        )),
        expect: () => [
          const ImportInProgress(),
          isA<ImportSuccess>().having(
            (state) => state.result.importedFiles,
            'importedFiles',
            equals(5),
          ),
        ],
      );

      blocTest<ImportBloc, ImportState>(
        'emits [ImportInProgress, ImportConflictDetected] when conflicts are detected',
        build: () {
          when(mockImportService.isImporting).thenReturn(false);
          when(mockImportService.importFromFolder(
            localPath,
            options: importOptions,
            progressController: anyNamed('progressController'),
          )).thenAnswer((_) async => ImportResult(
            success: true,
            importedFiles: 3,
            importedFolders: 1,
            skippedFiles: 0,
            errors: const [],
            conflicts: [
              FileConflict(
                filePath: 'test.md',
                existingContent: 'existing',
                newContent: 'new',
                existingModified: DateTime.now(),
                newModified: DateTime.now(),
              ),
            ],
          ));
          return importBloc;
        },
        act: (bloc) => bloc.add(const ImportFromFolderRequested(
          localPath: localPath,
          options: importOptions,
        )),
        expect: () => [
          const ImportInProgress(),
          isA<ImportConflictDetected>().having(
            (state) => state.conflicts.length,
            'conflicts.length',
            equals(1),
          ),
        ],
      );

      blocTest<ImportBloc, ImportState>(
        'emits [ImportInProgress, ImportFailure] when import fails',
        build: () {
          when(mockImportService.isImporting).thenReturn(false);
          when(mockImportService.importFromFolder(
            localPath,
            options: importOptions,
            progressController: anyNamed('progressController'),
          )).thenThrow(Exception('Import failed'));
          return importBloc;
        },
        act: (bloc) => bloc.add(const ImportFromFolderRequested(
          localPath: localPath,
          options: importOptions,
        )),
        expect: () => [
          const ImportInProgress(),
          isA<ImportFailure>().having(
            (state) => state.message,
            'message',
            contains('Import failed'),
          ),
        ],
      );

      blocTest<ImportBloc, ImportState>(
        'emits ImportFailure when import is already in progress',
        build: () {
          when(mockImportService.isImporting).thenReturn(true);
          return importBloc;
        },
        act: (bloc) => bloc.add(const ImportFromFolderRequested(
          localPath: localPath,
          options: importOptions,
        )),
        expect: () => [
          const ImportFailure(message: 'Import operation already in progress'),
        ],
      );
    });

    group('ImportValidationRequested', () {
      const testPath = '/test/path';

      blocTest<ImportBloc, ImportState>(
        'emits [ImportValidating, ImportValidationComplete] when validation succeeds',
        build: () {
          when(mockImportService.validateImportStructure(testPath))
              .thenAnswer((_) async => const ValidationResult(
                isValid: true,
                errors: [],
                warnings: [],
                detectedFiles: 5,
                detectedFolders: 2,
              ));
          return importBloc;
        },
        act: (bloc) => bloc.add(const ImportValidationRequested(testPath)),
        expect: () => [
          const ImportValidating(),
          isA<ImportValidationComplete>().having(
            (state) => state.result.detectedFiles,
            'detectedFiles',
            equals(5),
          ),
        ],
      );

      blocTest<ImportBloc, ImportState>(
        'emits [ImportValidating, ImportFailure] when validation fails',
        build: () {
          when(mockImportService.validateImportStructure(testPath))
              .thenThrow(Exception('Validation failed'));
          return importBloc;
        },
        act: (bloc) => bloc.add(const ImportValidationRequested(testPath)),
        expect: () => [
          const ImportValidating(),
          isA<ImportFailure>().having(
            (state) => state.message,
            'message',
            contains('Validation failed'),
          ),
        ],
      );
    });

    group('ImportCancelRequested', () {
      blocTest<ImportBloc, ImportState>(
        'emits ImportCancelled when cancel succeeds',
        build: () {
          when(mockImportService.cancelImport()).thenAnswer((_) async {});
          return importBloc;
        },
        act: (bloc) => bloc.add(const ImportCancelRequested()),
        expect: () => [const ImportCancelled()],
      );

      blocTest<ImportBloc, ImportState>(
        'emits ImportFailure when cancel fails',
        build: () {
          when(mockImportService.cancelImport()).thenThrow(Exception('Cancel failed'));
          return importBloc;
        },
        act: (bloc) => bloc.add(const ImportCancelRequested()),
        expect: () => [
          isA<ImportFailure>().having(
            (state) => state.message,
            'message',
            contains('Cancel failed'),
          ),
        ],
      );
    });

    group('ImportProgressUpdated', () {
      const progress = ImportProgress(
        totalFiles: 10,
        processedFiles: 5,
        currentFile: 'test.md',
        percentage: 0.5,
      );

      blocTest<ImportBloc, ImportState>(
        'emits ImportInProgress with updated progress',
        build: () => importBloc,
        act: (bloc) => bloc.add(const ImportProgressUpdated(progress)),
        expect: () => [
          isA<ImportInProgress>().having(
            (state) => state.progress?.percentage,
            'progress.percentage',
            equals(0.5),
          ),
        ],
      );
    });
  });
}