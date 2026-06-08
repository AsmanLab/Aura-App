import 'package:flutter/widgets.dart';

/// Root navigator key — lets services (e.g. push) show overlays and deep-link
/// without a BuildContext. Wired into the GoRouter in aura_app.dart.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
