/// Tests unitaires AuthNotifier.
///
/// Couvre les flows critiques: build initial sans session, login succès,
/// login échec, logout. La construction du conteneur Riverpod injecte des
/// mocks pour toutes les dépendances (AuthRepository, BiometricService,
/// DeviceInfoHelper, SecureStorageService, use cases, E2EE service, Dio).
library;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';
import 'package:mediconnect_pro/core/network/dio_client.dart';
import 'package:mediconnect_pro/core/network/network_info.dart';
import 'package:mediconnect_pro/core/security/biometric_service.dart';
import 'package:mediconnect_pro/core/security/e2ee_chat_crypto_service.dart';
import 'package:mediconnect_pro/core/security/secure_storage_service.dart';
import 'package:mediconnect_pro/core/utils/device_info_helper.dart';
import 'package:mediconnect_pro/features/auth/domain/entities/user_entity.dart';
import 'package:mediconnect_pro/features/auth/domain/repositories/auth_repository.dart';
import 'package:mediconnect_pro/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ──────────────────────────────────────────────────────

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockDeviceInfoHelper extends Mock implements DeviceInfoHelper {}

class _MockSecureStorage extends Mock implements SecureStorageService {}

class _MockBiometricService extends Mock implements BiometricService {}

class _MockE2eeCrypto extends Mock implements E2eeChatCryptoService {}

class _MockDio extends Mock implements Dio {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _MockLoginUseCase extends Mock implements LoginUseCase {}

class _MockLogoutUseCase extends Mock implements LogoutUseCase {}

class _FakeLoginParams extends Fake implements LoginParams {}

class _FakeDio extends Fake implements Dio {}

// ── Helpers ────────────────────────────────────────────────────

const _testUser = User(
  id: 'user-1',
  name: 'Dr. Test',
  email: 'doc@example.com',
  role: 'doctor',
  emailVerified: true,
);

ProviderContainer _makeContainer({
  required _MockAuthRepository repository,
  required _MockDeviceInfoHelper deviceInfo,
  required _MockSecureStorage secureStorage,
  required _MockBiometricService biometric,
  required _MockE2eeCrypto e2ee,
  required _MockDio dio,
  required _MockLoginUseCase loginUseCase,
  required _MockLogoutUseCase logoutUseCase,
}) {
  return ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repository),
    deviceInfoHelperProvider.overrideWithValue(deviceInfo),
    secureStorageProvider.overrideWithValue(secureStorage),
    biometricServiceProvider.overrideWithValue(biometric),
    e2eeChatCryptoServiceProvider.overrideWithValue(e2ee),
    dioProvider.overrideWithValue(dio),
    loginUseCaseProvider.overrideWithValue(loginUseCase),
    logoutUseCaseProvider.overrideWithValue(logoutUseCase),
  ]);
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeLoginParams());
    registerFallbackValue(_FakeDio());
  });

  late _MockAuthRepository repository;
  late _MockDeviceInfoHelper deviceInfo;
  late _MockSecureStorage secureStorage;
  late _MockBiometricService biometric;
  late _MockE2eeCrypto e2ee;
  late _MockDio dio;
  late _MockLoginUseCase loginUseCase;
  late _MockLogoutUseCase logoutUseCase;

  setUp(() {
    repository = _MockAuthRepository();
    deviceInfo = _MockDeviceInfoHelper();
    secureStorage = _MockSecureStorage();
    biometric = _MockBiometricService();
    e2ee = _MockE2eeCrypto();
    dio = _MockDio();
    loginUseCase = _MockLoginUseCase();
    logoutUseCase = _MockLogoutUseCase();

    // Defaults raisonnables: pas de token, pas de biométrie activée.
    when(() => repository.hasValidToken()).thenAnswer((_) async => false);
    when(() => repository.getCachedUser()).thenAnswer((_) async => null);
    when(() => repository.isBiometricEnabled()).thenAnswer((_) async => false);
    when(() => deviceInfo.getDeviceId()).thenAnswer((_) async => 'dev-1');
    when(() => deviceInfo.getDeviceInfo()).thenAnswer((_) async => (
          deviceId: 'dev-1',
          deviceName: 'Test Device',
          platform: 'test',
        ));
    when(() => secureStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => secureStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});
    when(() => e2ee.ensureOwnDeviceRegistered(any()))
        .thenAnswer((_) async {});
  });

  group('AuthNotifier.build()', () {
    test('sans token et sans biométrie -> état initial non authentifié',
        () async {
      final container = _makeContainer(
        repository: repository,
        deviceInfo: deviceInfo,
        secureStorage: secureStorage,
        biometric: biometric,
        e2ee: e2ee,
        dio: dio,
        loginUseCase: loginUseCase,
        logoutUseCase: logoutUseCase,
      );
      addTearDown(container.dispose);

      final state = await container.read(authNotifierProvider.future);

      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.biometricEnabled, isFalse);
      expect(state.canUseBiometricLogin, isFalse);
    });

    test('avec token valide + user cache -> état authentifié', () async {
      when(() => repository.hasValidToken()).thenAnswer((_) async => true);
      when(() => repository.getCachedUser()).thenAnswer((_) async => _testUser);

      final container = _makeContainer(
        repository: repository,
        deviceInfo: deviceInfo,
        secureStorage: secureStorage,
        biometric: biometric,
        e2ee: e2ee,
        dio: dio,
        loginUseCase: loginUseCase,
        logoutUseCase: logoutUseCase,
      );
      addTearDown(container.dispose);

      final state = await container.read(authNotifierProvider.future);

      expect(state.isAuthenticated, isTrue);
      expect(state.user?.id, 'user-1');
      expect(state.user?.role, 'doctor');
    });
  });

  group('AuthNotifier.login()', () {
    test('succès HTTP -> AsyncData avec isAuthenticated=true', () async {
      const token = '80|abcdef';
      when(() => loginUseCase(any())).thenAnswer(
        (_) async => Right<Failure, ({User user, String token})>(
          (user: _testUser, token: token),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        deviceInfo: deviceInfo,
        secureStorage: secureStorage,
        biometric: biometric,
        e2ee: e2ee,
        dio: dio,
        loginUseCase: loginUseCase,
        logoutUseCase: logoutUseCase,
      );
      addTearDown(container.dispose);

      // Attendre build initial.
      await container.read(authNotifierProvider.future);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login(
        identifier: 'doc@example.com',
        password: 'secret',
      );

      final state = container.read(authNotifierProvider).value!;
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.id, 'user-1');
      verify(() => loginUseCase(any())).called(1);
    });

    test('échec serveur -> AsyncError', () async {
      when(() => loginUseCase(any())).thenAnswer(
        (_) async => const Left<Failure, ({User user, String token})>(
          AuthFailure(message: 'Email ou mot de passe incorrect'),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        deviceInfo: deviceInfo,
        secureStorage: secureStorage,
        biometric: biometric,
        e2ee: e2ee,
        dio: dio,
        loginUseCase: loginUseCase,
        logoutUseCase: logoutUseCase,
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login(
        identifier: 'bad@example.com',
        password: 'wrong',
      );

      final asyncState = container.read(authNotifierProvider);
      expect(asyncState.hasError, isTrue);
      expect(
        asyncState.error.toString().toLowerCase(),
        contains('mot de passe'),
      );
    });

    test(
        'post-login: une exception sur les side-effects ne fait PAS échouer la session',
        () async {
      const token = '80|abcdef';
      when(() => loginUseCase(any())).thenAnswer(
        (_) async => Right<Failure, ({User user, String token})>(
          (user: _testUser, token: token),
        ),
      );
      // _isBiometricSessionAvailable throw → ne doit pas casser l'auth.
      when(() => repository.isBiometricEnabled())
          .thenThrow(StateError('secure storage hiccup'));
      // secureStorage.delete throw → idem
      when(() => secureStorage.delete(key: any(named: 'key')))
          .thenThrow(StateError('storage err'));

      final container = _makeContainer(
        repository: repository,
        deviceInfo: deviceInfo,
        secureStorage: secureStorage,
        biometric: biometric,
        e2ee: e2ee,
        dio: dio,
        loginUseCase: loginUseCase,
        logoutUseCase: logoutUseCase,
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).login(
            identifier: 'doc@example.com',
            password: 'secret',
          );

      // Malgré les exceptions sur les hooks post-login, l'utilisateur DOIT
      // être considéré comme authentifié — c'est le contrat du fix
      // appliqué dans le commit b078564.
      final state = container.read(authNotifierProvider).value!;
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.id, 'user-1');
    });
  });

  group('AuthNotifier.logout()', () {
    test('appelle logoutUseCase et passe en état non authentifié', () async {
      when(() => logoutUseCase()).thenAnswer(
        (_) async => const Right<Failure, void>(null),
      );

      final container = _makeContainer(
        repository: repository,
        deviceInfo: deviceInfo,
        secureStorage: secureStorage,
        biometric: biometric,
        e2ee: e2ee,
        dio: dio,
        loginUseCase: loginUseCase,
        logoutUseCase: logoutUseCase,
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).logout();

      final state = container.read(authNotifierProvider).value!;
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      verify(() => logoutUseCase()).called(1);
    });
  });
}
