import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';

class PhrasesScreen extends StatefulWidget {
  const PhrasesScreen({super.key});

  @override
  State<PhrasesScreen> createState() => _PhrasesScreenState();
}

class _PhrasesScreenState extends State<PhrasesScreen> {
  int _lang = 0;
  String? _playing;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play(Phrase p) {
    _timer?.cancel();
    setState(() => _playing = p.local);
    showSoonSnack(context, 'Audio by local speakers is coming soon');
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _playing = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Legacy text-only list: voice-only languages live on Know the Locals.
    final languages = [
      for (final l in MockData.phraseLanguages)
        if (l.phrases.any((p) => p.hasLocalText)) l,
    ];
    final lang = languages[_lang];
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const FadeIn(
          child: PageHeading(
            'Phrases',
            subtitle: 'A few words go a long way. Works offline.',
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            children: [
              for (final (i, l) in languages.indexed)
                ChoiceChip(
                  showCheckmark: false,
                  label: Text(l.name),
                  selected: _lang == i,
                  onSelected: (_) => setState(() => _lang = i),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: DotLabel(lang.where, color: AppColors.blue),
        ),
        if (lang.needsVerification)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: InfoNote(
              'Sample phrases — spellings and pronunciation vary by village. '
              'To be verified with local speakers.',
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey(_lang),
            children: [
              for (final (n, p)
                  in lang.phrases.where((p) => p.hasLocalText).indexed)
                FadeIn(
                  index: n,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
                        title: Text(p.local, style: t.titleMedium),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('${p.english} · ${p.pronunciation}'),
                        ),
                        trailing: IconButton(
                          tooltip: 'Play audio',
                          onPressed: () => _play(p),
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (c, a) =>
                                ScaleTransition(scale: a, child: c),
                            child: _playing == p.local
                                ? const Icon(
                                    Icons.graphic_eq,
                                    key: ValueKey('on'),
                                    color: AppColors.blue,
                                  )
                                : const Icon(
                                    Icons.volume_up_outlined,
                                    key: ValueKey('off'),
                                  ),
                          ),
                        ),
                      ),
                      const Divider(indent: 20, endIndent: 20),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
