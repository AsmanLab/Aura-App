import 'package:aura_app/core/domain/entities/knowledge_doc.dart';
import 'package:aura_app/core/domain/repositories/knowledge_repository.dart';
import '../seed/knowledge_docs.dart';

class SeedKnowledgeRepository implements KnowledgeRepository {
  @override
  Future<List<KnowledgeDoc>> getDocs() async => KnowledgeDocs.docs;

  @override
  Future<KnowledgeDoc?> getDoc(String id) async {
    for (final d in KnowledgeDocs.docs) {
      if (d.id == id) return d;
    }
    return null;
  }
}
