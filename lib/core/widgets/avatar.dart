import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Deterministic gradient palette for initials avatars. See commands/04 §4.3.
const _avatarGrads = <List<Color>>[
  [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
  [Color(0xFFF472B6), Color(0xFFA855F7)],
  [Color(0xFF34D399), Color(0xFF06B6D4)],
  [Color(0xFFFBBF24), Color(0xFFFB7185)],
  [Color(0xFF60A5FA), Color(0xFF818CF8)],
  [Color(0xFFF59E0B), Color(0xFFEF4444)],
  [Color(0xFF2DD4BF), Color(0xFF3B82F6)],
  [Color(0xFFC084FC), Color(0xFFEC4899)],
  [Color(0xFF4ADE80), Color(0xFF22D3EE)],
  [Color(0xFFFB923C), Color(0xFFF43F5E)],
  [Color(0xFFA78BFA), Color(0xFF38BDF8)],
  [Color(0xFFF0ABFC), Color(0xFF6366F1)],
];

List<Color> gradFor(String id) {
  var h = 0;
  for (final r in id.codeUnits) {
    h = (h * 31 + r) & 0x7fffffff;
  }
  return _avatarGrads[h % _avatarGrads.length];
}

String initialsOf(String name) {
  final p = name.trim().split(RegExp(r'\s+'));
  final first = p.isNotEmpty && p[0].isNotEmpty ? p[0][0] : '';
  final second = p.length > 1 && p[1].isNotEmpty ? p[1][0] : '';
  return (first + second).toUpperCase();
}

/// Initials avatar on a deterministic gradient, optional 3px gradient ring.
///
/// Decoupled from the `Person` model (Stage 3) — takes `id` + `name` so it can
/// be used in Stage 2 before the data layer exists.
class Avatar extends StatelessWidget {
  final String id;
  final String name;
  final double size;
  final bool ring;

  /// Optional network photo (e.g. Google account picture). Falls back to
  /// gradient initials when null/empty or if it fails to load.
  final String? photoUrl;

  const Avatar({
    super.key,
    required this.id,
    required this.name,
    this.size = 44,
    this.ring = false,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final grad = gradFor(id);
    final initials = Text(
      initialsOf(name),
      style: TextStyle(fontFamily: 'Manrope', 
        fontSize: 0.38 * size,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final disc = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: grad,
        ),
      ),
      child: hasPhoto
          ? CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorWidget: (_, __, ___) => Center(child: initials),
              placeholder: (_, __) => const SizedBox.shrink(),
            )
          : initials,
    );

    if (!ring) return disc;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: grad,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: 2,
          ),
        ),
        child: disc,
      ),
    );
  }
}
