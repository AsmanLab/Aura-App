import '../entities/knowledge_doc.dart';

abstract class KnowledgeRepository {
  Future<List<KnowledgeDoc>> getDocs();
  Future<KnowledgeDoc?> getDoc(String id);
}
