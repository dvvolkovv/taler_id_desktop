import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../api/auth_interceptor.dart';
import '../api/dio_client.dart';
import '../storage/secure_storage_service.dart';
import '../storage/cache_service.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Profile
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/i_profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

// KYC
import '../../features/kyc/data/datasources/kyc_remote_datasource.dart';
import '../../features/kyc/data/repositories/kyc_repository_impl.dart';
import '../../features/kyc/domain/repositories/i_kyc_repository.dart';
import '../../features/kyc/presentation/bloc/kyc_bloc.dart';

// Tenant
import '../../features/tenant/data/datasources/tenant_remote_datasource.dart';
import '../../features/tenant/data/repositories/tenant_repository_impl.dart';
import '../../features/tenant/domain/repositories/i_tenant_repository.dart';
import '../../features/tenant/presentation/bloc/tenant_bloc.dart';

// Sessions
import '../../features/sessions/data/datasources/sessions_remote_datasource.dart';
import '../../features/sessions/data/repositories/sessions_repository_impl.dart';
import '../../features/sessions/domain/repositories/i_session_repository.dart';
import '../../features/sessions/presentation/bloc/sessions_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Storage
  final storage = SecureStorageService();
  sl.registerSingleton<SecureStorageService>(storage);

  // Cache
  await CacheService.init();
  sl.registerSingleton<CacheService>(CacheService());

  // Dio (raw, for auth interceptor use)
  final rawDio = Dio(
    BaseOptions(
      baseUrl: 'https://id.taler.tirol',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final authInterceptor = AuthInterceptor(dio: rawDio, storage: storage);
  final dioClient = DioClient.create(authInterceptor: authInterceptor);
  sl.registerSingleton<DioClient>(dioClient);

  // Data sources
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => ProfileRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => KycRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => TenantRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => SessionsRemoteDataSource(sl<DioClient>()));

  // Repositories
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      storage: sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton<IProfileRepository>(
    () => ProfileRepositoryImpl(
      remote: sl<ProfileRemoteDataSource>(),
      cache: sl<CacheService>(),
    ),
  );
  sl.registerLazySingleton<IKycRepository>(
    () => KycRepositoryImpl(
      remote: sl<KycRemoteDataSource>(),
      cache: sl<CacheService>(),
    ),
  );
  sl.registerLazySingleton<ITenantRepository>(
    () => TenantRepositoryImpl(
      remote: sl<TenantRemoteDataSource>(),
      cache: sl<CacheService>(),
      storage: sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton<ISessionRepository>(
    () => SessionsRepositoryImpl(sl<SessionsRemoteDataSource>()),
  );

  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl<IAuthRepository>()));
  sl.registerFactory(() => ProfileBloc(repo: sl<IProfileRepository>()));
  sl.registerFactory(() => KycBloc(repo: sl<IKycRepository>()));
  sl.registerFactory(() => TenantBloc(repo: sl<ITenantRepository>()));
  sl.registerFactory(() => SessionsBloc(repo: sl<ISessionRepository>()));
}
