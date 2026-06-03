import 'package:equatable/equatable.dart';

enum BlockType { heading, paragraph, bullet, callout }

class DocBlock extends Equatable {
  final BlockType type;
  final String text;

  const DocBlock(this.type, this.text);

  @override
  List<Object?> get props => [type, text];
}

class KnowledgeDoc extends Equatable {
  final String id;
  final String title;
  final String titleRu;
  final String description;
  final String readTime; // "6 min"
  final String tag; // "Operations"
  final String icon; // glyph name
  final bool featured; // the "START HERE" card
  final List<DocBlock> body;

  const KnowledgeDoc({
    required this.id,
    required this.title,
    required this.titleRu,
    required this.description,
    required this.readTime,
    required this.tag,
    required this.icon,
    this.featured = false,
    this.body = const [],
  });

  @override
  List<Object?> get props => [
    id,
    title,
    titleRu,
    description,
    readTime,
    tag,
    icon,
    featured,
    body,
  ];
}
