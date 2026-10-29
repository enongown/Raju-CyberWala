import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/tribe_lens_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/search_field.dart';
import '../../widgets/visuals.dart';

/// Know the Locals (replaces the old Phrases tab): tribe search with AI
/// camera search, tribe chips, a tribe info card and the phrase lists.
class KnowLocalsScreen extends StatefulWidget {
  const KnowLocalsScreen({super.key});

  /// Test hooks: replace the photo picker and the TribeLens service.
  @visibleForTesting
  static Future<Uint8List?> Function(ImageSource source)? debugPickImage;
  @visibleForTesting
  static TribeLensService? debugTribeLens;

  @override
  State<KnowLocalsScreen> createState() => _KnowLocalsScreenState();
}

class _KnowLocalsScreenState extends State<KnowLocalsScreen>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  String _query = '';
  int _tribe = 0;
  String? _playing;
  final _chipScroll = ScrollController();
  final _chipKeys = <int, GlobalKey>{};
  Timer? _timer;

  /// One shared player, created on the first tap, so only one recorded
  /// phrase plays at a time.
  AudioPlayer? _player;
  StreamSubscription<void>? _completeSub;

  /// Asset path of the voice clip that is playing, if any.
  String? _voicePlaying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop the clip when the app goes to the background.
    if (state != AppLifecycleState.resumed) _stopVoice();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _completeSub?.cancel();
    _player?.dispose();
    _search.dispose();
    _chipScroll.dispose();
    super.dispose();
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    // Phrase assets store full paths (assets/audio/...), so no prefix.
    final player = AudioPlayer()..audioCache = AudioCache(prefix: '');
    _completeSub = player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _voicePlaying = null);
    });
    return _player = player;
  }

  /// Plays a bundled voice clip, or stops it when it is already playing.
  /// Starting a clip stops any other one first.
  Future<void> _toggleVoice(Phrase p) async {
    final asset = p.audioAsset;
    if (asset == null) return;
    if (_voicePlaying == asset) {
      _stopVoice();
      return;
    }
    final player = _ensurePlayer();
    setState(() => _voicePlaying = asset);
    try {
      await player.stop();
      if (!mounted || _voicePlaying != asset) return;
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('Voice clip failed ($asset): $e');
      if (!mounted || _voicePlaying != asset) return;
      setState(() => _voicePlaying = null);
      showSoonSnack(context, 'Could not play this recording');
    }
  }

  void _stopVoice() {
    if (_voicePlaying != null && mounted) {
      setState(() => _voicePlaying = null);
    }
    _player?.stop();
  }

  void _play(Phrase p) {
    _timer?.cancel();
    setState(() => _playing = p.local);
    showSoonSnack(context, 'Audio by local speakers is coming soon');
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _playing = null);
    });
  }

  Future<void> _cameraSearch() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Search with your camera',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null) return;
    Uint8List? bytes;
    try {
      bytes = await _pickImage(source);
    } catch (_) {
      if (mounted) {
        showSoonSnack(context, 'Camera not available on this device');
      }
      return;
    }
    if (bytes == null || !mounted) return;
    final outcome = await showModalBottomSheet<_LensOutcome>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TribeLensSheet(
        bytes: bytes!,
        service: KnowLocalsScreen.debugTribeLens ?? TribeLensService(),
      ),
    );
    if (outcome == null || !mounted) return; // Sheet dismissed.
    final name = outcome.tribe;
    final index = name == null
        ? -1
        : MockData.tribes.indexWhere((t) => t.name == name);
    if (index < 0) {
      showSoonSnack(context, "Couldn't recognise the tribe. Try another photo.");
      return;
    }
    _selectTribe(index);
    showSoonSnack(context, 'Looks like $name attire');
  }

  Future<Uint8List?> _pickImage(ImageSource source) async {
    final hook = KnowLocalsScreen.debugPickImage;
    if (hook != null) return hook(source);
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    return file?.readAsBytes();
  }

  /// Selects the tribe chip at [index] (clearing the search so the chip is
  /// visible) and scrolls it into view.
  void _selectTribe(int index) {
    _stopVoice();
    _search.clear();
    setState(() {
      _query = '';
      _tribe = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_chipScroll.hasClients) return;
      var chip = _chipKeys[index]?.currentContext;
      if (chip == null) {
        // Not built yet (off screen): jump near it first.
        final pos = _chipScroll.position;
        final n = MockData.tribes.length;
        pos.jumpTo(pos.maxScrollExtent * index / (n > 1 ? n - 1 : 1));
        await WidgetsBinding.instance.endOfFrame;
        chip = _chipKeys[index]?.currentContext;
      }
      if (chip != null && chip.mounted) {
        await Scrollable.ensureVisible(
          chip,
          alignment: 0.5,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  PhraseLanguage? _languageNamed(String? name) {
    if (name == null) return null;
    for (final l in MockData.phraseLanguages) {
      if (l.name == name) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final q = _query.trim().toLowerCase();
    final tribes = MockData.tribes;
    final visible = [
      for (final (i, tr) in tribes.indexed)
        if (q.isEmpty ||
            '${tr.name} ${tr.region} ${tr.festivals}'.toLowerCase().contains(q))
          i,
    ];
    final selected = visible.contains(_tribe)
        ? _tribe
        : (visible.isEmpty ? _tribe : visible.first);
    final tribe = tribes[selected];
    final own = _languageNamed(tribe.phraseLanguage);
    final ownVoice = [...?own?.phrases.where((p) => p.hasAudio)];
    final ownText = [...?own?.phrases.where((p) => !p.hasAudio)];
    final hindi = _languageNamed('Hindi');
    bool phraseMatch(Phrase p) =>
        q.isEmpty ||
        tribe.name.toLowerCase().contains(q) ||
        '${p.english} ${p.local}'.toLowerCase().contains(q);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: FadeIn(
            child: AppSearchField(
              controller: _search,
              hint: 'Search Tribes or Use AI camera Search…',
              onChanged: (v) => setState(() => _query = v),
              trailing: IconButton(
                tooltip: 'AI camera search',
                icon: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.blue,
                ),
                onPressed: _cameraSearch,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeIn(
          index: 1,
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              controller: _chipScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, n) {
                final i = visible[n];
                final tr = tribes[i];
                return ChoiceChip(
                  key: _chipKeys.putIfAbsent(i, GlobalKey.new),
                  showCheckmark: false,
                  avatar: tr.nearYou
                      ? const Icon(Icons.near_me_outlined, size: 16)
                      : null,
                  label: Text(tr.name),
                  selected: selected == i,
                  onSelected: (_) {
                    _stopVoice();
                    setState(() => _tribe = i);
                  },
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: FadeIn(
            index: 2,
            child: DotLabel(
              'Suggested dialects according to your location '
              '(${MockData.mockLocationName})',
              color: AppColors.blue,
            ),
          ),
        ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No tribe matches "$_query". Try the camera search.',
              style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          child: Column(
            key: ValueKey('$selected$q'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: FadeIn(
                  index: 0,
                  child: _TribeCard(tribe: tribe, index: selected),
                ),
              ),
              if (own != null && ownVoice.isNotEmpty) ...[
                SectionHeader(
                  'Phrases with voice',
                  subtitle: '${own.name} · ${own.where}',
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: InfoNote(
                    'Tap a phrase to hear it. Recordings are saved in the '
                    'app and work offline.',
                    icon: Icons.headphones_outlined,
                  ),
                ),
                for (final (n, p) in ownVoice.where(phraseMatch).indexed)
                  FadeIn(index: n, child: _voiceTile(p, own.name)),
              ],
              if (own == null || ownText.isNotEmpty)
                SectionHeader(
                  own == null ? '${tribe.name} phrases' : '${own.name} phrases',
                  subtitle: own?.where ?? tribe.region,
                ),
              if (own == null)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: InfoNote(
                    'Phrases are being collected with local speakers. '
                    'Hindi works almost everywhere in the meantime.',
                    icon: Icons.record_voice_over_outlined,
                  ),
                )
              else ...[
                if (own.needsVerification && ownText.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: InfoNote(
                      'Sample phrases — spellings and pronunciation vary by '
                      'village. To be verified with local speakers.',
                    ),
                  ),
                for (final (n, p) in ownText.where(phraseMatch).indexed)
                  FadeIn(index: n, child: _phraseTile(p)),
              ],
              if (hindi != null) ...[
                SectionHeader('Hindi · link language', subtitle: hindi.where),
                for (final (n, p) in hindi.phrases.where(phraseMatch).indexed)
                  FadeIn(index: n, child: _phraseTile(p)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Row for a phrase with a recorded clip. Shows the English meaning (and
  /// the local wording when known) with a play / pause button.
  Widget _voiceTile(Phrase p, String language) {
    final t = Theme.of(context).textTheme;
    final playing = _voicePlaying == p.audioAsset;
    final hint = playing ? 'Playing in $language…' : 'Listen in $language';
    return Column(
      children: [
        ListTile(
          key: ValueKey('voice-${p.audioAsset}'),
          onTap: () => _toggleVoice(p),
          contentPadding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
          title: Text(
            p.hasLocalText ? p.local : p.english,
            style: t.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              child: Text(
                p.hasLocalText ? '${p.english} · $hint' : hint,
                key: ValueKey(playing),
                style: t.bodyMedium?.copyWith(
                  color: playing ? AppColors.blue : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          trailing: VoicePlayButton(
            playing: playing,
            tooltip: playing ? 'Stop' : 'Listen in $language',
            onPressed: () => _toggleVoice(p),
          ),
        ),
        const Divider(indent: 20, endIndent: 20),
      ],
    );
  }

  Widget _phraseTile(Phrase p) {
    final t = Theme.of(context).textTheme;
    return Column(
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
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: _playing == p.local
                  ? const Icon(
                      Icons.graphic_eq,
                      key: ValueKey('on'),
                      color: AppColors.blue,
                    )
                  : const Icon(Icons.volume_up_outlined, key: ValueKey('off')),
            ),
          ),
        ),
        const Divider(indent: 20, endIndent: 20),
      ],
    );
  }
}

/// Round speaker button for a recorded phrase. While [playing] it turns
/// blue, swaps to a pause icon and pulses a soft ring.
class VoicePlayButton extends StatefulWidget {
  const VoicePlayButton({
    super.key,
    required this.playing,
    required this.onPressed,
    this.tooltip,
  });

  final bool playing;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<VoicePlayButton> createState() => _VoicePlayButtonState();
}

class _VoicePlayButtonState extends State<VoicePlayButton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _pulse.repeat();
  }

  @override
  void didUpdateWidget(VoicePlayButton old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.playing && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.playing;
    final button = SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (playing)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final v = Curves.easeOut.transform(_pulse.value);
                return Container(
                  width: 40 + 12 * v,
                  height: 40 + 12 * v,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue.withValues(alpha: 0.22 * (1 - v)),
                  ),
                );
              },
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: playing ? AppColors.blue : AppColors.blueTint,
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onPressed,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) => ScaleTransition(
                      scale: a,
                      child: FadeTransition(opacity: a, child: c),
                    ),
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.volume_up_rounded,
                      key: ValueKey(playing),
                      size: 22,
                      color: playing ? Colors.white : AppColors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: widget.tooltip == null
          ? button
          : Tooltip(message: widget.tooltip!, child: button),
    );
  }
}

class _TribeCard extends StatelessWidget {
  const _TribeCard({required this.tribe, required this.index});
  final Tribe tribe;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final accent = AppColors.accents[index % AppColors.accents.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint(accent, 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint(accent, 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  tribe.name[0],
                  style: t.titleMedium?.copyWith(
                    color: Color.lerp(accent, Colors.black, 0.2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tribe.name, style: t.titleLarge),
                    Text(tribe.region, style: t.bodySmall),
                  ],
                ),
              ),
              if (tribe.nearYou)
                const TonePill(
                  'Near you',
                  color: AppColors.blue,
                  icon: Icons.near_me_outlined,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tribe.description, style: t.bodyMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.celebration_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Festivals: ${tribe.festivals}',
                  style: t.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Sample notes — to be verified with local speakers and community '
            'members.',
            style: t.labelSmall?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// What the TribeLens sheet returns: the tribe name, or null when the photo
/// was not recognised (timeout, no internet or an unknown answer).
class _LensOutcome {
  const _LensOutcome(this.tribe);
  final String? tribe;
}

/// Loading sheet shown while TribeLens identifies the photo: the photo with
/// a sweeping scan line, "Identifying tribe…" and a progress bar. Closes
/// itself with a [_LensOutcome]; swiping it away cancels.
class _TribeLensSheet extends StatefulWidget {
  const _TribeLensSheet({required this.bytes, required this.service});
  final Uint8List bytes;
  final TribeLensService service;

  @override
  State<_TribeLensSheet> createState() => _TribeLensSheetState();
}

class _TribeLensSheetState extends State<_TribeLensSheet>
    with SingleTickerProviderStateMixin {
  late final TribeLensClient _client = widget.service.createClient();
  late final _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final tribe = await widget.service.identify(_client, widget.bytes);
    if (mounted) Navigator.pop(context, _LensOutcome(tribe));
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      widget.bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: AppColors.surfaceSoft),
                    ),
                    ColoredBox(color: Colors.white.withValues(alpha: 0.12)),
                    AnimatedBuilder(
                      animation: _scan,
                      builder: (context, _) => Align(
                        alignment: Alignment(
                          0,
                          -1 + 2 * Curves.easeInOut.transform(_scan.value),
                        ),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue.withValues(alpha: 0.55),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined, color: AppColors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Identifying tribe…', style: t.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                'Matching the attire with Adi, Singpho and Khamti',
                style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.blue,
                backgroundColor: AppColors.blueTint,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // The TribeLens page runs here, kept 1×1 and out of sight.
                _client.buildHost(),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
