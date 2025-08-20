import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../../domain/services/import_service.dart';
import '../bloc/import_bloc.dart';
import '../bloc/import_event.dart';
import '../bloc/import_state.dart';

class ImportDialog extends StatefulWidget {
  final String? targetFolder;

  const ImportDialog({
    super.key,
    this.targetFolder,
  });

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final _formKey = GlobalKey<FormState>();
  String _importPath = '';
  bool _importFromZip = false;
  ConflictStrategy _conflictStrategy = ConflictStrategy.ask;
  bool _validateStructure = true;
  bool _preserveTimestamps = true;
  String? _targetFolder;

  @override
  void initState() {
    super.initState();
    _targetFolder = widget.targetFolder;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImportBloc, ImportState>(
      listener: (context, state) {
        if (state is ImportSuccess) {
          Navigator.of(context).pop(state.result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Import completed successfully! '
                '${state.result.importedFiles} files, '
                '${state.result.importedFolders} folders imported.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ImportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is ImportCancelled) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Import cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (state is ImportConflictDetected) {
          _showConflictResolutionDialog(context, state.conflicts);
        } else if (state is ImportValidationComplete) {
          _showValidationResults(context, state.result);
        }
      },
      builder: (context, state) {
        return AlertDialog(
          title: const Text('Import Notes'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is ImportInProgress) ...[
                    _buildProgressIndicator(state),
                    const SizedBox(height: 16),
                  ] else if (state is ImportValidating) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Validating import structure...'),
                    const SizedBox(height: 16),
                  ],
                  
                  // Import path selection
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: _importFromZip ? 'ZIP File Path' : 'Import Folder',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: _isOperationInProgress(state) ? null : _selectPath,
                      ),
                    ),
                    controller: TextEditingController(text: _importPath),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an import path';
                      }
                      return null;
                    },
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),

                  // Import format selection
                  Row(
                    children: [
                      Checkbox(
                        value: _importFromZip,
                        onChanged: _isOperationInProgress(state)
                            ? null
                            : (value) {
                                setState(() {
                                  _importFromZip = value ?? false;
                                  _importPath = ''; // Reset path when format changes
                                });
                              },
                      ),
                      const Text('Import from ZIP file'),
                    ],
                  ),

                  // Target folder
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Target Folder (optional)',
                      hintText: 'Leave empty to import to root',
                    ),
                    initialValue: _targetFolder,
                    onChanged: (value) {
                      _targetFolder = value.isEmpty ? null : value;
                    },
                    enabled: !_isOperationInProgress(state),
                  ),
                  const SizedBox(height: 16),

                  // Conflict strategy
                  DropdownButtonFormField<ConflictStrategy>(
                    decoration: const InputDecoration(
                      labelText: 'Conflict Resolution',
                    ),
                    value: _conflictStrategy,
                    items: ConflictStrategy.values.map((strategy) {
                      return DropdownMenuItem(
                        value: strategy,
                        child: Text(_getConflictStrategyLabel(strategy)),
                      );
                    }).toList(),
                    onChanged: _isOperationInProgress(state)
                        ? null
                        : (value) {
                            setState(() {
                              _conflictStrategy = value ?? ConflictStrategy.ask;
                            });
                          },
                  ),
                  const SizedBox(height: 16),

                  // Import options
                  Row(
                    children: [
                      Checkbox(
                        value: _validateStructure,
                        onChanged: _isOperationInProgress(state)
                            ? null
                            : (value) {
                                setState(() {
                                  _validateStructure = value ?? true;
                                });
                              },
                      ),
                      const Text('Validate structure'),
                    ],
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: _preserveTimestamps,
                        onChanged: _isOperationInProgress(state)
                            ? null
                            : (value) {
                                setState(() {
                                  _preserveTimestamps = value ?? true;
                                });
                              },
                      ),
                      const Text('Preserve timestamps'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (_isOperationInProgress(state))
              TextButton(
                onPressed: () {
                  context.read<ImportBloc>().add(const ImportCancelRequested());
                },
                child: const Text('Cancel'),
              )
            else ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              if (_importPath.isNotEmpty)
                TextButton(
                  onPressed: _validateImport,
                  child: const Text('Validate'),
                ),
              ElevatedButton(
                onPressed: _startImport,
                child: const Text('Import'),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildProgressIndicator(ImportInProgress state) {
    final progress = state.progress;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (progress != null) ...[
          LinearProgressIndicator(value: progress.percentage),
          const SizedBox(height: 8),
          Text(
            'Processing: ${progress.currentFile}',
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${progress.processedFiles} / ${progress.totalFiles} files',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('Preparing import...'),
        ],
      ],
    );
  }

  bool _isOperationInProgress(ImportState state) {
    return state is ImportInProgress || state is ImportValidating;
  }

  String _getConflictStrategyLabel(ConflictStrategy strategy) {
    switch (strategy) {
      case ConflictStrategy.ask:
        return 'Ask for each conflict';
      case ConflictStrategy.skip:
        return 'Skip conflicting files';
      case ConflictStrategy.overwrite:
        return 'Overwrite existing files';
      case ConflictStrategy.rename:
        return 'Rename new files';
      case ConflictStrategy.keepBoth:
        return 'Keep both versions';
    }
  }

  Future<void> _selectPath() async {
    if (_importFromZip) {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select ZIP file to import',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _importPath = result.files.single.path!;
        });
      }
    } else {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to import',
      );
      if (result != null) {
        setState(() {
          _importPath = result;
        });
      }
    }
  }

  void _validateImport() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<ImportBloc>().add(ImportValidationRequested(_importPath));
  }

  void _startImport() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final options = ImportOptions(
      targetFolder: _targetFolder,
      conflictStrategy: _conflictStrategy,
      validateStructure: _validateStructure,
      preserveTimestamps: _preserveTimestamps,
      allowedExtensions: ['.md', '.txt', '.json'],
    );

    if (_importFromZip) {
      context.read<ImportBloc>().add(ImportFromZipRequested(
        zipPath: _importPath,
        options: options,
      ));
    } else {
      context.read<ImportBloc>().add(ImportFromFolderRequested(
        localPath: _importPath,
        options: options,
      ));
    }
  }

  void _showValidationResults(BuildContext context, ValidationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.isValid ? 'Validation Passed' : 'Validation Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Files detected: ${result.detectedFiles}'),
            Text('Folders detected: ${result.detectedFolders}'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.errors.map((error) => Text('• $error')),
            ],
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.warnings.map((warning) => Text('• $warning')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConflictResolutionDialog(BuildContext context, List<FileConflict> conflicts) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConflictResolutionDialog(
        conflicts: conflicts,
        onConflictResolved: (filePath, strategy) {
          context.read<ImportBloc>().add(ImportConflictResolved(
            filePath: filePath,
            strategy: strategy,
          ));
        },
      ),
    );
  }
}

class ConflictResolutionDialog extends StatefulWidget {
  final List<FileConflict> conflicts;
  final Function(String filePath, ConflictStrategy strategy) onConflictResolved;

  const ConflictResolutionDialog({
    super.key,
    required this.conflicts,
    required this.onConflictResolved,
  });

  @override
  State<ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  int _currentConflictIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.conflicts.isEmpty) {
      Navigator.of(context).pop();
      return const SizedBox.shrink();
    }

    final conflict = widget.conflicts[_currentConflictIndex];

    return AlertDialog(
      title: Text('File Conflict (${_currentConflictIndex + 1}/${widget.conflicts.length})'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${conflict.filePath}'),
            const SizedBox(height: 16),
            const Text('A file with this name already exists. How would you like to resolve this conflict?'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _resolveConflict(ConflictStrategy.skip),
          child: const Text('Skip'),
        ),
        TextButton(
          onPressed: () => _resolveConflict(ConflictStrategy.overwrite),
          child: const Text('Overwrite'),
        ),
        TextButton(
          onPressed: () => _resolveConflict(ConflictStrategy.rename),
          child: const Text('Rename'),
        ),
        TextButton(
          onPressed: () => _resolveConflict(ConflictStrategy.keepBoth),
          child: const Text('Keep Both'),
        ),
      ],
    );
  }

  void _resolveConflict(ConflictStrategy strategy) {
    final conflict = widget.conflicts[_currentConflictIndex];
    widget.onConflictResolved(conflict.filePath, strategy);
    Navigator.of(context).pop();
  }
}