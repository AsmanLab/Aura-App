import '../../shared/domain/entities/knowledge_doc.dart';
import '../../shared/domain/repositories/knowledge_repository.dart';
import '../seed/seed_data.dart';

class SeedKnowledgeRepository implements KnowledgeRepository {
  @override
  Future<List<KnowledgeDoc>> getDocs() async => SeedData.docs;

  @override
  Future<KnowledgeDoc?> getDoc(String id) async {
    for (final d in SeedData.docs) {
      if (d.id == id) return d;
    }
    return null;
  }
}
