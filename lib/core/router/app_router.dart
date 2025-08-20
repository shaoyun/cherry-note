import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_routes.dart';
import '../../features/main/presentation/pages/main_screen.dart';
import '../../features/main/presentation/pages/settings_page.dart';
import '../../features/main/presentation/pages/about_page.dart';
import '../../features/notes/presentation/pages/notes_list_page.dart';
import '../../features/notes/presentation/pages/note_editor_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';

@singleton
class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const MainScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutPage(),
        ),
        GoRoute(
          path: AppRoutes.notes,
          builder: (context, state) => const NotesListPage(),
        ),
        GoRoute(
          path: AppRoutes.newNote,
          builder: (context, state) => const NoteEditorPage(),
        ),
        GoRoute(
          path: AppRoutes.editNote,
          builder: (context, state) {
            final noteId = state.pathParameters['id']!;
            return NoteEditorPage(noteId: noteId);
          },
        ),
      ],
    );
  }
}