import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_routes.dart';
import '../../features/main/presentation/pages/main_screen.dart';
import '../../features/main/presentation/pages/settings_page.dart';
import '../../features/main/presentation/pages/about_page.dart';
import '../../features/notes/presentation/pages/notes_list_page.dart';
import '../../features/notes/presentation/pages/note_editor_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/folders/presentation/bloc/folders_bloc.dart';
import '../../features/notes/presentation/bloc/notes_bloc.dart';
import '../../features/notes/presentation/bloc/web_notes_bloc.dart';
import '../../features/tags/presentation/bloc/tags_bloc.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';

@singleton
class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) {
            final providers = <BlocProvider>[
              BlocProvider<FoldersBloc>(
                create: (context) => GetIt.instance<FoldersBloc>(),
              ),
              BlocProvider<TagsBloc>(
                create: (context) => GetIt.instance<TagsBloc>(),
              ),
            ];
            
            if (kIsWeb) {
              providers.add(BlocProvider<WebNotesBloc>(
                create: (context) => WebNotesBloc(),
              ));
            } else {
              providers.add(BlocProvider<NotesBloc>(
                create: (context) => NotesBloc(
                  notesDirectory: GetIt.instance<String>(instanceName: 'notesDirectory')
                ),
              ));
            }
            
            return MultiBlocProvider(
              providers: providers,
              child: const MainScreen(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => BlocProvider(
            create: (context) => GetIt.instance<SettingsBloc>(),
            child: const SettingsPage(),
          ),
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