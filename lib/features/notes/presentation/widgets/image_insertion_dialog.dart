import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ImageInsertionDialog extends StatefulWidget {
  final Function(String imageMarkdown) onImageInserted;

  const ImageInsertionDialog({
    super.key,
    required this.onImageInserted,
  });

  @override
  State<ImageInsertionDialog> createState() => _ImageInsertionDialogState();
}

class _ImageInsertionDialogState extends State<ImageInsertionDialog> {
  final _altTextController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isFromFile = false;
  String? _selectedFilePath;

  @override
  void dispose() {
    _altTextController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert Image'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image source selection
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('From URL'),
                    value: false,
                    groupValue: _isFromFile,
                    onChanged: (value) {
                      setState(() {
                        _isFromFile = value!;
                        _selectedFilePath = null;
                      });
                    },
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('From File'),
                    value: true,
                    groupValue: _isFromFile,
                    onChanged: (value) {
                      setState(() {
                        _isFromFile = value!;
                        _urlController.clear();
                      });
                    },
                    dense: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Alt text input
            TextField(
              controller: _altTextController,
              decoration: const InputDecoration(
                labelText: 'Alt Text',
                hintText: 'Describe the image',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // URL or file selection
            if (!_isFromFile) ...[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedFilePath ?? 'No file selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectImageFile,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('Browse'),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Preview section
            if (_canShowPreview()) ...[
              const Text(
                'Preview:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _generateMarkdown(),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canInsert() ? _insertImage : null,
          child: const Text('Insert'),
        ),
      ],
    );
  }

  Future<void> _selectImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePath = result.files.first.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  bool _canShowPreview() {
    return _altTextController.text.isNotEmpty && 
           ((!_isFromFile && _urlController.text.isNotEmpty) ||
            (_isFromFile && _selectedFilePath != null));
  }

  bool _canInsert() {
    return _altTextController.text.isNotEmpty && 
           ((!_isFromFile && _urlController.text.isNotEmpty) ||
            (_isFromFile && _selectedFilePath != null));
  }

  String _generateMarkdown() {
    final altText = _altTextController.text;
    final imageSource = _isFromFile ? _selectedFilePath! : _urlController.text;
    return '![${altText}](${imageSource})';
  }

  void _insertImage() {
    final markdown = _generateMarkdown();
    widget.onImageInserted(markdown);
    Navigator.of(context).pop();
  }
}

// Helper function to show the dialog
Future<void> showImageInsertionDialog(
  BuildContext context,
  Function(String imageMarkdown) onImageInserted,
) {
  return showDialog(
    context: context,
    builder: (context) => ImageInsertionDialog(
      onImageInserted: onImageInserted,
    ),
  );
}