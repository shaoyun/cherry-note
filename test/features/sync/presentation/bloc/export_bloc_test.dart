import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:cherry_note/features/sync/domain/services/export_service.dart';
import 'package:cherry_note/features/sync/presentation/bloc/export_bloc.dart';
import 'package:cherry_note/features/sync/presentation/bloc/export_event.dart';
import 'package:cherry_note/features/sync/presentation/bloc/export_state.dart';

import 'export_bloc_test.mocks.dart';

@GenerateMocks([ExportService])
void main() {
  group('ExportBloc', () {
    late ExportBloc exportBloc;
    late MockExportService mockExportService;

    setUp(() {
      mockExportService = MockExportService();
      exportBloc = ExportBloc(mockExportService);
    });

    tearDown(() {
      exportBloc.close();
    });

    test('initial state is ExportInitial', () {
      expect(exportBloc.state, equals(const ExportInitial()));
    });

    group('ExportToFolderRequested', () {
      const localPath = '/test/export/path';
      const exportOptions = ExportOptions(includeMetadata: true);

      blocTest<ExportBloc, ExportState>(
        'emits [ExportInProgress, ExportSuccess] when export succeeds',
        build: () {
          when(mockExportService.isExporting).thenReturn(false);
          when(mockExportService.exportToFolder(
            localPath,
            options: exportOptions,
            progressController: anyNamed('progressController'),
          )).thenAnswer((_) async => const ExportResult(
            success: true,
            exportedFiles: 5,
            exportedFolders: 2,
            errors: [],
            exportPath: localPath,
          ));
          return exportBloc;
        },
        act: (bloc) => bloc.add(const ExportToFolderRequested(
          localPath: localPath,
          options: exportOptions,
        )),
        expect: () => [
          const ExportInProgress(),
          isA<ExportSuccess>().having(
            (state) => state.result.exportedFiles,
            'exportedFiles',
            equals(5),
          ),
        ],
      );

      blocTest<ExportBloc, ExportState>(
        'emits [ExportInProgress, ExportFailure] when export fails',
        build: () {
          when(mockExportService.isExporting).thenReturn(false);
          when(mockExportService.exportToFolder(
            localPath,
            options: exportOptions,
            progressController: anyNamed('progressController'),
          )).thenThrow(Exception('Export failed'));
          return exportBloc;
        },
        act: (bloc) => bloc.add(const ExportToFolderRequested(
          localPath: localPath,
          options: exportOptions,
        )),
        expect: () => [
          const ExportInProgress(),
          isA<ExportFailure>().having(
            (state) => state.message,
            'message',
            contains('Export failed'),
          ),
        ],
      );

      blocTest<ExportBloc, ExportState>(
        'emits ExportFailure when export is already in progress',
        build: () {
          when(mockExportService.isExporting).thenReturn(true);
          return exportBloc;
        },
        act: (bloc) => bloc.add(const ExportToFolderRequested(
          localPath: localPath,
          options: exportOptions,
        )),
        expect: () => [
          const ExportFailure(message: 'Export operation already in progress'),
        ],
      );

      blocTest<ExportBloc, ExportState>(
        'emits ExportFailure when export completes with errors',
        build: () {
          when(mockExportService.isExporting).thenReturn(false);
          when(mockExportService.exportToFolder(
            localPath,
            options: exportOptions,
            progressController: anyNamed('progressController'),
          )).thenAnswer((_) async => const ExportResult(
            success: false,
            exportedFiles: 3,
            exportedFolders: 1,
            errors: ['Error 1', 'Error 2'],
            exportPath: localPath,
          ));
          return exportBloc;
        },
        act: (bloc) => bloc.add(const ExportToFolderRequested(
          localPath: localPath,
          options: exportOptions,
        )),
        expect: () => [
          const ExportInProgress(),
          isA<ExportFailure>().having(
            (state) => state.errors,
            'errors',
            equals(['Error 1', 'Error 2']),
          ),
        ],
      );
    });

    group('ExportToZipRequested', () {
      const zipPath = '/test/export.zip';
      const exportOptions = ExportOptions(includeMetadata: false);

      blocTest<ExportBloc, ExportState>(
        'emits [ExportInProgress, ExportSuccess] when ZIP export succeeds',
        build: () {
          when(mockExportService.isExporting).thenReturn(false);
          when(mockExportService.exportToZip(
            zipPath,
            options: exportOptions,
            progressController: anyNamed('progressController'),
          )).thenAnswer((_) async => const ExportResult(
            success: true,
            exportedFiles: 10,
            exportedFolders: 3,
            errors: [],
            exportPath: zipPath,
          ));
          return exportBloc;
        },
        act: (bloc) => bloc.add(const ExportToZipRequested(
          zipPath: zipPath,
          options: exportOptions,
        )),
        expect: () => [
          const ExportInProgress(),
          isA<ExportSuccess>().having(
            (state) => state.result.exportedFiles,
            'exportedFiles',
            equals(10),
          ),
        ],
      );
    });

    group('ExportFolderRequested', () {
      const folderPath = 'test-folder';
      const localPath = '/test/export/path';

      blocTest<ExportBloc, ExportState>(
        'emits [ExportInProgress, ExportSuccess] when folder export succeeds',
        build: () {
          when(mockExportService.isExporting).thenReturn(false);
          when(mockExportService.exportFolder(
            folderPath,
            localPath,
            includeMetadata: true,
            progressController: anyNamed('progressController'),
          )).thenAnswer((_) async => const ExportResult(
            success: true,
            exportedFiles: 3,
            exportedFolders: 1,
            errors: [],
            exportPath: localPath,
          ));
          return exportBloc;
        },
        act: (bloc) => bloc.add(const ExportFolderRequested(
          folderPath: folderPath,
          localPath: localPath,
        )),
        expect: () => [
          const ExportInProgress(),
          isA<ExportSuccess>().having(
            (state) => state.result.exportedFolders,
            'exportedFolders',
            equals(1),
          ),
        ],
      );
    });

    group('ExportCancelRequested', () {
      blocTest<ExportBloc, ExportState>(
        'emits ExportCancelled when cancel succeeds',
        build: () {
          when(mockExportService.cancelExport()).thenAnswer((_) async {});
          return exportBloc;
        },
        act: (bloc) => bloc.add(const ExportCancelRequested()),
        expect: () => [const ExportCancelled()],
      );

      blocTest<ExportBloc, ExportState>(
        'emits ExportFailure when cancel fails',
        build: () {
          when(mockExportService.cancelExport()).thenThrow(Exception('Cancel failed'));
          return exportBloc;
        },
        act: (bloc) => bloc.add(const ExportCancelRequested()),
        expect: () => [
          isA<ExportFailure>().having(
            (state) => state.message,
            'message',
            contains('Cancel failed'),
          ),
        ],
      );
    });

    group('ExportProgressUpdated', () {
      const progress = ExportProgress(
        totalFiles: 10,
        processedFiles: 5,
        currentFile: 'test.md',
        percentage: 0.5,
      );

      blocTest<ExportBloc, ExportState>(
        'emits ExportInProgress with updated progress',
        build: () => exportBloc,
        act: (bloc) => bloc.add(const ExportProgressUpdated(progress)),
        expect: () => [
          isA<ExportInProgress>().having(
            (state) => state.progress?.percentage,
            'progress.percentage',
            equals(0.5),
          ),
        ],
      );
    });

    group('Progress handling', () {
      test('should handle progress updates during export', () async {
        // Arrange
        final progressController = StreamController<ExportProgress>();
        const localPath = '/test/export/path';
        
        when(mockExportService.isExporting).thenReturn(false);
        when(mockExportService.exportToFolder(
          localPath,
          options: anyNamed('options'),
          progressController: anyNamed('progressController'),
        )).thenAnswer((invocation) async {
          final controller = invocation.namedArguments[#progressController] as StreamController<ExportProgress>?;
          
          // Simulate progress updates
          controller?.add(const ExportProgress(
            totalFiles: 10,
            processedFiles: 3,
            currentFile: 'file1.md',
            percentage: 0.3,
          ));
          
          controller?.add(const ExportProgress(
            totalFiles: 10,
            processedFiles: 7,
            currentFile: 'file2.md',
            percentage: 0.7,
          ));

          return const ExportResult(
            success: true,
            exportedFiles: 10,
            exportedFolders: 2,
            errors: [],
            exportPath: localPath,
          );
        });

        // Act
        final states = <ExportState>[];
        exportBloc.stream.listen(states.add);
        
        exportBloc.add(const ExportToFolderRequested(localPath: localPath));
        
        // Wait for completion
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(states, hasLength(greaterThan(2)));
        expect(states.first, isA<ExportInProgress>());
        
        // Find the success state (might not be the last due to async timing)
        final successStates = states.whereType<ExportSuccess>();
        expect(successStates, isNotEmpty);
        
        // Check that progress updates were received
        final progressStates = states.whereType<ExportInProgress>().where((s) => s.progress != null);
        expect(progressStates, isNotEmpty);
      });
    });
  });
}