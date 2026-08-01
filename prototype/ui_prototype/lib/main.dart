// PROTOTYPE — throwaway UI prototype for grand-line (One Pace watch app).
// Three structurally different variants of the core UI, switchable via the
// floating bottom bar or the left/right arrow keys. Resize the window to a
// phone-ish width to judge the mobile layout. Answers wayfinder ticket
// .scratch/app-spec/issues/06-prototype-core-ui.md — not production code.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'variant_a.dart';
import 'variant_b.dart';
import 'variant_c.dart';
import 'variant_d.dart';
import 'variant_e.dart';

void main() => runApp(const PrototypeApp());

typedef _Variant = (String key, String label, WidgetBuilder builder);

final _variants = <_Variant>[
  ('A', VariantA.label, (_) => const VariantA()),
  ('B', VariantB.label, (_) => const VariantB()),
  ('C', VariantC.label, (_) => const VariantC()),
  ('D', VariantD.label, (_) => const VariantD()),
  ('E', VariantE.label, (_) => const VariantE()),
];

class PrototypeApp extends StatefulWidget {
  const PrototypeApp({super.key});

  @override
  State<PrototypeApp> createState() => _PrototypeAppState();
}

class _PrototypeAppState extends State<PrototypeApp> {
  int index = 0;

  void _cycle(int delta) =>
      setState(() => index = (index + delta) % _variants.length);

  @override
  Widget build(BuildContext context) {
    final (key, label, builder) = _variants[index];
    return MaterialApp(
      title: 'grand-line UI PROTOTYPE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _cycle(-1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _cycle(1),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              // Each variant lives in its own Navigator so pushed pages
              // (player, arc detail) stay under the switcher and reset on
              // variant change.
              KeyedSubtree(
                key: ValueKey(key),
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute(builder: builder),
                ),
              ),
              if (!kReleaseMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: _SwitcherPill(
                      label: '$key — $label',
                      onPrev: () => _cycle(-1),
                      onNext: () => _cycle(1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitcherPill extends StatelessWidget {
  const _SwitcherPill(
      {required this.label, required this.onPrev, required this.onNext});
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                color: Colors.black,
                icon: const Icon(Icons.chevron_left),
                onPressed: onPrev),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
                color: Colors.black,
                icon: const Icon(Icons.chevron_right),
                onPressed: onNext),
          ],
        ),
      ),
    );
  }
}
