// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cherry_note/core/di/app_module.dart' as _i849;
import 'package:cherry_note/core/network/network_info.dart' as _i10;
import 'package:cherry_note/core/router/app_router.dart' as _i1038;
import 'package:cherry_note/core/services/s3_connection_test_service.dart'
    as _i620;
import 'package:cherry_note/core/services/secure_storage_service.dart' as _i394;
import 'package:cherry_note/core/services/settings_service.dart' as _i926;
import 'package:cherry_note/features/folders/data/datasources/folder_data_source.dart'
    as _i744;
import 'package:cherry_note/features/folders/data/repositories/folder_repository_impl.dart'
    as _i383;
import 'package:cherry_note/features/folders/domain/repositories/folder_repository.dart'
    as _i544;
import 'package:cherry_note/features/folders/presentation/bloc/folders_bloc.dart'
    as _i1046;
import 'package:cherry_note/features/notes/presentation/bloc/notes_bloc.dart'
    as _i1025;
import 'package:cherry_note/features/notes/presentation/bloc/web_notes_bloc.dart'
    as _i932;
import 'package:cherry_note/features/settings/data/services/settings_import_export_service.dart'
    as _i197;
import 'package:cherry_note/features/settings/presentation/bloc/settings_bloc.dart'
    as _i292;
import 'package:cherry_note/features/sync/data/repositories/s3_storage_repository_impl.dart'
    as _i450;
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart'
    as _i1020;
import 'package:cherry_note/features/tags/data/repositories/tag_repository_impl.dart'
    as _i291;
import 'package:cherry_note/features/tags/domain/repositories/tag_repository.dart'
    as _i400;
import 'package:cherry_note/features/tags/domain/usecases/create_tag.dart'
    as _i447;
import 'package:cherry_note/features/tags/domain/usecases/delete_tag.dart'
    as _i376;
import 'package:cherry_note/features/tags/domain/usecases/get_all_tags.dart'
    as _i242;
import 'package:cherry_note/features/tags/domain/usecases/get_tag_suggestions.dart'
    as _i697;
import 'package:cherry_note/features/tags/domain/usecases/search_tags.dart'
    as _i632;
import 'package:cherry_note/features/tags/presentation/bloc/tags_bloc.dart'
    as _i743;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final appModule = _$AppModule();
    gh.factory<_i932.WebNotesBloc>(() => _i932.WebNotesBloc());
    gh.singleton<_i1038.AppRouter>(() => _i1038.AppRouter());
    gh.lazySingleton<_i926.SettingsService>(() => _i926.SettingsServiceImpl());
    gh.lazySingleton<_i10.NetworkInfo>(() => _i10.NetworkInfoImpl());
    gh.lazySingleton<_i1020.S3StorageRepository>(
        () => _i450.S3StorageRepositoryImpl(gh<_i10.NetworkInfo>()));
    gh.lazySingleton<_i394.SecureStorageService>(
        () => _i394.SecureStorageServiceImpl());
    gh.lazySingleton<_i400.TagRepository>(() => _i291.TagRepositoryImpl());
    gh.factory<_i447.CreateTag>(
        () => _i447.CreateTag(gh<_i400.TagRepository>()));
    gh.factory<_i376.DeleteTag>(
        () => _i376.DeleteTag(gh<_i400.TagRepository>()));
    gh.factory<_i242.GetAllTags>(
        () => _i242.GetAllTags(gh<_i400.TagRepository>()));
    gh.factory<_i697.GetTagSuggestions>(
        () => _i697.GetTagSuggestions(gh<_i400.TagRepository>()));
    gh.factory<_i632.SearchTags>(
        () => _i632.SearchTags(gh<_i400.TagRepository>()));
    gh.lazySingleton<_i620.S3ConnectionTestService>(() =>
        _i620.S3ConnectionTestServiceImpl(gh<_i1020.S3StorageRepository>()));
    gh.lazySingleton<_i197.SettingsImportExportService>(() =>
        _i197.SettingsImportExportServiceImpl(gh<_i926.SettingsService>()));
    await gh.lazySingletonAsync<String>(
      () => appModule.notesDirectory(),
      instanceName: 'notesDirectory',
      preResolve: true,
    );
    gh.factory<_i1025.NotesBloc>(() => _i1025.NotesBloc(
        notesDirectory: gh<String>(instanceName: 'notesDirectory')));
    gh.factory<_i743.TagsBloc>(() => _i743.TagsBloc(
          tagRepository: gh<_i400.TagRepository>(),
          getAllTags: gh<_i242.GetAllTags>(),
          createTag: gh<_i447.CreateTag>(),
          searchTags: gh<_i632.SearchTags>(),
          getTagSuggestions: gh<_i697.GetTagSuggestions>(),
          deleteTag: gh<_i376.DeleteTag>(),
        ));
    gh.factory<_i292.SettingsBloc>(() => _i292.SettingsBloc(
          gh<_i926.SettingsService>(),
          gh<_i620.S3ConnectionTestService>(),
          gh<_i197.SettingsImportExportService>(),
        ));
    gh.lazySingleton<_i744.FolderDataSource>(() =>
        appModule.folderDataSource(gh<String>(instanceName: 'notesDirectory')));
    gh.lazySingleton<_i544.FolderRepository>(() =>
        _i383.FolderRepositoryImpl(dataSource: gh<_i744.FolderDataSource>()));
    gh.factory<_i1046.FoldersBloc>(() =>
        _i1046.FoldersBloc(folderRepository: gh<_i544.FolderRepository>()));
    return this;
  }
}

class _$AppModule extends _i849.AppModule {}
