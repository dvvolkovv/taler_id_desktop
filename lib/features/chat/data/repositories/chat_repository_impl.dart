import '../../domain/repositories/i_chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../../../../core/storage/secure_storage_service.dart';

class ChatRepositoryImpl implements IChatRepository {
  final ChatRemoteDataSource remote;
  final SecureStorageService storage;

  ChatRepositoryImpl({required this.remote, required this.storage});

  @override
  Stream<String> sendMessage(String prompt) async* {
    final userId = await storage.getUserId() ?? 'anonymous';
    yield* remote.sendMessage(prompt: prompt, userId: userId);
  }
}
