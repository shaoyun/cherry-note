import 'package:flutter/material.dart';

class NotesListPage extends StatelessWidget {
  const NotesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: const Center(
        child: Text(
          'Notes List - Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to new note
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}