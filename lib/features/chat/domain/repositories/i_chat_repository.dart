abstract class IChatRepository {
  Stream<String> sendMessage(String prompt);
}
