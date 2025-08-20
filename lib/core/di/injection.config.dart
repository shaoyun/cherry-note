// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cherry_note/core/network/network_info.dart' as _i10;
import 'package:cherry_note/core/router/app_router.dart' as _i1038;
import 'package:cherry_note/core/services/s3_connection_test_service.dart'
    as _i620;
import 'package:cherry_note/core/services/secure_storage_service.dart' as _i394;
import 'package:cherry_note/core/services/settings_service.dart' as _i926;
import 'package:cherry_note/features/settings/data/services/settings_import_export_service.dart'
    as _i197;
import 'package:cherry_note/features/settings/presentation/bloc/settings_bloc.dart'
    as _i292;
import 'package:cherry_note/features/sync/data/repositories/s3_storage_repository_impl.dart'
    as _i450;
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart'
    as _i1020;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i1038.AppRouter>(() => _i1038.AppRouter());
    gh.lazySingleton<_i926.SettingsService>(() => _i926.SettingsServiceImpl());
    gh.lazySingleton<_i10.NetworkInfo>(() => _i10.NetworkInfoImpl());
    gh.lazySingleton<_i1020.S3StorageRepository>(
        () => _i450.S3StorageRepositoryImpl(gh<_i10.NetworkInfo>()));
    gh.lazySingleton<_i394.SecureStorageService>(
        () => _i394.SecureStorageServiceImpl());
    gh.lazySingleton<_i620.S3ConnectionTestService>(() =>
        _i620.S3ConnectionTestServiceImpl(gh<_i1020.S3StorageRepository>()));
    gh.lazySingleton<_i197.SettingsImportExportService>(() =>
        _i197.SettingsImportExportServiceImpl(gh<_i926.SettingsService>()));
    gh.factory<_i292.SettingsBloc>(() => _i292.SettingsBloc(
          gh<_i926.SettingsService>(),
          gh<_i620.S3ConnectionTestService>(),
          gh<_i197.SettingsImportExportService>(),
        ));
    return this;
  }
}
