class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String settings = '/settings';
  
  // Main app routes
  static const String home = '/';
  static const String notes = '/notes';
  static const String newNote = '/notes/new';
  static const String editNote = '/notes/:id';
  
  // Folder routes
  static const String folders = '/folders';
  static const String folderNotes = '/folders/:folderId/notes';
  
  // Tag routes
  static const String tags = '/tags';
  static const String taggedNotes = '/tags/:tagName/notes';
  
  // Sync routes
  static const String sync = '/sync';
  static const String syncSettings = '/sync/settings';
  
  // Utility methods
  static String noteRoute(String noteId) => '/notes/$noteId';
  static String folderNotesRoute(String folderId) => '/folders/$folderId/notes';
  static String taggedNotesRoute(String tagName) => '/tags/$tagName/notes';
}