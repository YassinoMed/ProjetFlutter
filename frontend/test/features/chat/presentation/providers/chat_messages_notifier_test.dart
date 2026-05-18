/// Tests unitaires MessageThreadNotifier.
///
/// Couvre les flows de la timeline d'une conversation chiffrée:
/// build (chargement initial), sendMessage (optimiste + remplacement par
/// persisté), sendMessage rollback en cas d'erreur, acknowledgeMessage.
///
/// L'E2EE (ECDH + AES-GCM) est testé séparément dans
/// test/core/security/encryption_service_test.dart : ici on stubbe la
/// data source pour se concentrer sur la logique du notifier.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect_pro/features/auth/domain/entities/user_entity.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:mediconnect_pro/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';
import 'package:mediconnect_pro/features/chat/presentation/providers/chat_providers.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ──────────────────────────────────────────────────────

class _MockChatDataSource extends Mock implements ChatRemoteDataSource {}

// ── Fixtures ───────────────────────────────────────────────────

const _conversationId = 'consult-123';

const _meUser = User(
  id: 'user-me',
  name: 'Patient Test',
  email: 'patient@example.com',
  role: 'patient',
);

ChatMessage _incoming(String id, String content) => ChatMessage(
      id: id,
      conversationId: _conversationId,
      senderId: 'user-doctor',
      content: content,
      timestamp: DateTime.utc(2026, 5, 1, 10, 0).add(Duration(seconds: id.hashCode % 60)),
      isMe: false,
      isEncrypted: true,
      status: MessageStatus.delivered,
    );

ChatMessage _mine(String id, String content) => ChatMessage(
      id: id,
      conversationId: _conversationId,
      senderId: _meUser.id,
      content: content,
      timestamp: DateTime.utc(2026, 5, 1, 10, 5),
      isMe: true,
      isEncrypted: true,
      status: MessageStatus.sent,
    );

ProviderContainer _makeContainer({
  required _MockChatDataSource dataSource,
}) {
  return ProviderContainer(overrides: [
    chatRemoteDataSourceProvider.overrideWithValue(dataSource),
    // Override le current user pour que sendMessage ait un senderId stable.
    currentUserProvider.overrideWith((ref) => _meUser),
  ]);
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(MessageStatus.read);
  });

  late _MockChatDataSource dataSource;

  setUp(() {
    dataSource = _MockChatDataSource();
    when(() => dataSource.getConversations()).thenAnswer((_) async => const []);
    when(() => dataSource.acknowledgeMessage(
          consultationId: any(named: 'consultationId'),
          messageId: any(named: 'messageId'),
          status: any(named: 'status'),
        )).thenAnswer((_) async {});
  });

  group('MessageThreadNotifier.build()', () {
    test('charge les messages depuis le data source et les trie', () async {
      final earlier = _incoming('m1', 'Bonjour');
      final later = _mine('m2', 'Salut');
      when(() => dataSource.getMessages(_conversationId))
          .thenAnswer((_) async => [later, earlier]);

      final container = _makeContainer(dataSource: dataSource);
      addTearDown(container.dispose);

      final messages =
          await container.read(messagesProvider(_conversationId).future);

      expect(messages, hasLength(2));
      // Tri chronologique : earlier avant later.
      expect(messages.first.id, 'm1');
      expect(messages.last.id, 'm2');
    });

    test('liste vide → état AsyncData([])', () async {
      when(() => dataSource.getMessages(_conversationId))
          .thenAnswer((_) async => const []);

      final container = _makeContainer(dataSource: dataSource);
      addTearDown(container.dispose);

      final messages =
          await container.read(messagesProvider(_conversationId).future);

      expect(messages, isEmpty);
    });
  });

  group('MessageThreadNotifier.sendMessage()', () {
    test('insère un message optimiste puis le remplace par le persisté',
        () async {
      when(() => dataSource.getMessages(_conversationId))
          .thenAnswer((_) async => const []);
      final persisted = _mine('server-id-1', 'Hello doctor');
      when(() => dataSource.sendMessage(_conversationId, 'Hello doctor', true))
          .thenAnswer((_) async => persisted);

      final container = _makeContainer(dataSource: dataSource);
      addTearDown(container.dispose);

      await container.read(messagesProvider(_conversationId).future);

      final notifier =
          container.read(messagesProvider(_conversationId).notifier);
      await notifier.sendMessage('Hello doctor');

      final messages =
          container.read(messagesProvider(_conversationId)).value!;
      expect(messages, hasLength(1));
      expect(messages.first.id, 'server-id-1');
      expect(messages.first.content, 'Hello doctor');
      expect(messages.first.isPending, isFalse);
      verify(() =>
              dataSource.sendMessage(_conversationId, 'Hello doctor', true))
          .called(1);
    });

    test('rollback du message optimiste si le data source throw', () async {
      when(() => dataSource.getMessages(_conversationId))
          .thenAnswer((_) async => const []);
      when(() => dataSource.sendMessage(_conversationId, any(), any()))
          .thenThrow(Exception('Network down'));

      final container = _makeContainer(dataSource: dataSource);
      addTearDown(container.dispose);

      await container.read(messagesProvider(_conversationId).future);

      final notifier =
          container.read(messagesProvider(_conversationId).notifier);

      // L'erreur est rethrow → le notifier signale l'échec au caller.
      await expectLater(
        notifier.sendMessage('Hello'),
        throwsA(isA<Exception>()),
      );

      // Le message optimiste a bien été retiré.
      final messages =
          container.read(messagesProvider(_conversationId)).value!;
      expect(messages, isEmpty);
    });

    test('ignore les contenus vides ou whitespace only', () async {
      when(() => dataSource.getMessages(_conversationId))
          .thenAnswer((_) async => const []);

      final container = _makeContainer(dataSource: dataSource);
      addTearDown(container.dispose);

      await container.read(messagesProvider(_conversationId).future);

      final notifier =
          container.read(messagesProvider(_conversationId).notifier);
      await notifier.sendMessage('   ');

      verifyNever(() => dataSource.sendMessage(any(), any(), any()));
    });
  });

  group('MessageThreadNotifier.acknowledgeMessage()', () {
    test('passe le status à READ et appelle le data source', () async {
      final incoming = _incoming('m-inc', 'Coucou');
      when(() => dataSource.getMessages(_conversationId))
          .thenAnswer((_) async => [incoming]);

      final container = _makeContainer(dataSource: dataSource);
      addTearDown(container.dispose);

      await container.read(messagesProvider(_conversationId).future);

      await container
          .read(messagesProvider(_conversationId).notifier)
          .acknowledgeMessage('m-inc', MessageStatus.read);

      final messages =
          container.read(messagesProvider(_conversationId)).value!;
      expect(messages.first.status, MessageStatus.read);

      verify(() => dataSource.acknowledgeMessage(
            consultationId: _conversationId,
            messageId: 'm-inc',
            status: MessageStatus.read,
          )).called(1);
    });
  });
}
