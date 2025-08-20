import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../../domain/services/export_service.dart';
import '../bloc/export_bloc.dart';
import '../bloc/export_event.dart';
import '../bloc/export_state.dart';

class ExportDialog extends StatefulWidget {
  final List<String>? preselectedFolders;

  const ExportDialog({
    super.key,
    this.preselectedFolders,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final _formKey = GlobalKey<FormState>();
  String _exportPath = '';
  bool _exportAsZip = false;
  bool _includeMetadata = true;
  bool _includeHiddenFiles = false;
  List<String> _selectedFolders = [];

  @override
  void initState() {
    super.initState();
    _selectedFolders = widget.preselectedFolders ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExportBloc, ExportState>(
      listener: (context, state) {
        if (state is ExportSuccess) {
          Navigator.of(context).pop(state.result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Export completed successfully! '
                '${state.result.exportedFiles} files, '
                '${state.result.exportedFolders} folders exported.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ExportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is ExportCancelled) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      builder: (context, state) {
        return AlertDialog(
          title: const Text('Export Notes'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is ExportInProgress) ...[
                    _buildProgressIndicator(state),
                    const SizedBox(height: 16),
                  ],
                  
                  // Export path selection
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: _exportAsZip ? 'ZIP File Path' : 'Export Folder',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: state is ExportInProgress ? null : _selectPath,
                      ),
                    ),
                    controller: TextEditingController(text: _exportPath),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an export path';
                      }
                      return null;
                    },
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),

                  // Export format selection
                  Row(
                    children: [
                      Checkbox(
                        value: _exportAsZip,
                        onChanged: state is ExportInProgress
                            ? null
                            : (value) {
                                setState(() {
                                  _exportAsZip = value ?? false;
                                  _exportPath = ''; // Reset path when format changes
                                });
                              },
                      ),
                      const Text('Export as ZIP file'),
                    ],
                  ),

                  // Export options
                  Row(
                    children: [
                      Checkbox(
                        value: _includeMetadata,
                        onChanged: state is ExportInProgress
                            ? null
                            : (value) {
                                setState(() {
                                  _includeMetadata = value ?? true;
                                });
                              },
                      ),
                      const Text('Include metadata'),
                    ],
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: _includeHiddenFiles,
                        onChanged: state is ExportInProgress
                            ? null
                            : (value) {
                                setState(() {
                                  _includeHiddenFiles = value ?? false;
                                });
                              },
                      ),
                      const Text('Include hidden files'),
                    ],
                  ),

                  // Selected folders info
                  if (_selectedFolders.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Selected folders: ${_selectedFolders.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (state is ExportInProgress)
              TextButton(
                onPressed: () {
                  context.read<ExportBloc>().add(const ExportCancelRequested());
                },
                child: const Text('Cancel'),
              )
            else ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _startExport,
                child: const Text('Export'),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildProgressIndicator(ExportInProgress state) {
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
          const Text('Preparing export...'),
        ],
      ],
    );
  }

  Future<void> _selectPath() async {
    if (_exportAsZip) {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save export as ZIP',
        fileName: 'notes_export.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result != null) {
        setState(() {
          _exportPath = result;
        });
      }
    } else {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select export folder',
      );
      if (result != null) {
        setState(() {
          _exportPath = result;
        });
      }
    }
  }

  void _startExport() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final options = ExportOptions(
      selectedFolders: _selectedFolders.isEmpty ? null : _selectedFolders,
      includeMetadata: _includeMetadata,
      includeHiddenFiles: _includeHiddenFiles,
    );

    if (_exportAsZip) {
      context.read<ExportBloc>().add(ExportToZipRequested(
        zipPath: _exportPath,
        options: options,
      ));
    } else {
      context.read<ExportBloc>().add(ExportToFolderRequested(
        localPath: _exportPath,
        options: options,
      ));
    }
  }
}