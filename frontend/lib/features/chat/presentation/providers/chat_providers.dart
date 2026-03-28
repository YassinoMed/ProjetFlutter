import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/network/dio_client.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:mediconnect_pro/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final currentUserId = ref.watch(currentUserProvider)?.id ?? '';

  return ChatRemoteDataSourceImpl(
    dio: dio,
    currentUserId: currentUserId,
  );
});

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return dataSource.getConversations();
});

final messagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, conversationId) {
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return dataSource.getMessages(conversationId);
});
