import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';

/// ILP / PAP guide. Content is a simplified summary — the screen repeatedly
/// tells users to confirm with official sources.
class PermitsScreen extends StatefulWidget {
  const PermitsScreen({super.key, this.initialIndian});

  final bool? initialIndian;

  @override
  State<PermitsScreen> createState() => _PermitsScreenState();
}

class _PermitsScreenState extends State<PermitsScreen> {
  static final _ilpPortal = Uri.parse('https://arunachalilp.com/');

  late bool? _indian = widget.initialIndian;
  final Set<int> _checked = {};

  Future<void> _openPortal() async {
    final ok = await launchUrl(
      _ilpPortal,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) showSoonSnack(context, 'Could not open the portal');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const FadeIn(
          child: PageHeading(
            'Permits',
            subtitle:
                'Inner Line Permit (ILP) for Indian visitors and Protected Area '
                'Permit (PAP) for foreign nationals.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: FadeIn(
            index: 1,
            child: OutlineCard(
              color: AppColors.yellowTint.withValues(alpha: 0.5),
              borderColor: const Color(0xFFF6E3A6),
              child: const InfoNote(
                'This is a simplified guide. Rules, fees and restricted areas '
                'change — always verify with official government sources '
                'before you travel.',
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ),
        ),
        FadeIn(
          index: 2,
          child: const SectionHeader(
            'Are you an Indian citizen or a foreign national?',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeIn(
            index: 3,
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                emptySelectionAllowed: true,
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.person_outline),
                    label: Text('Indian citizen'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.public),
                    label: Text('Foreign national'),
                  ),
                ],
                selected: {?_indian},
                onSelectionChanged: (s) => setState(() {
                  _indian = s.isEmpty ? null : s.first;
                  _checked.clear();
                }),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SizeTransition(
              sizeFactor: a,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
          child: switch (_indian) {
            null => Padding(
              key: const ValueKey('none'),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
              child: Column(
                children: [
                  const TintIcon(Icons.badge_outlined, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Choose one to see what you need',
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            true => _PermitGuide(
              key: const ValueKey('ilp'),
              info: _ilp,
              checked: _checked,
              onToggle: (i) => setState(
                () =>
                    _checked.contains(i) ? _checked.remove(i) : _checked.add(i),
              ),
              onOpenPortal: _openPortal,
            ),
            false => _PermitGuide(
              key: const ValueKey('pap'),
              info: _pap,
              checked: _checked,
              onToggle: (i) => setState(
                () =>
                    _checked.contains(i) ? _checked.remove(i) : _checked.add(i),
              ),
              onOpenPortal: _openPortal,
            ),
          },
        ),
      ],
    );
  }
}

class _PermitInfo {
  const _PermitInfo({
    required this.code,
    required this.name,
    required this.who,
    required this.documents,
    required this.steps,
    required this.facts,
    required this.portalLabel,
  });

  final String code;
  final String name;
  final String who;
  final List<String> documents;
  final List<String> steps;
  final List<(String, String)> facts;
  final String portalLabel;
}

const _ilp = _PermitInfo(
  code: 'ILP',
  name: 'Inner Line Permit',
  who: 'Needed by Indian citizens from outside Arunachal Pradesh to enter the state.',
  documents: [
    'Government photo ID (Aadhaar, Voter ID, passport or driving licence)',
    'Recent passport-size photo (digital for e-ILP)',
    'Travel dates and places you plan to visit',
    'For groups: details of each traveller',
  ],
  steps: [
    'Apply online on the official e-ILP portal',
    'Upload ID and photo, pay the fee online',
    'Download / print the e-ILP once approved',
    'Show it at the entry check gate (e.g. Bhalukpong, Banderdewa)',
    'Carry printouts and ID throughout the trip',
  ],
  facts: [
    (
      'Typical validity',
      'Tourist ILP for a limited period (often up to 30 days)',
    ),
    ('Approx. fee', 'Small fee per person — check the portal'),
    ('Processing', 'Often same day to a few days'),
  ],
  portalLabel: 'Apply on official ILP portal',
);

const _pap = _PermitInfo(
  code: 'PAP',
  name: 'Protected Area Permit',
  who:
      'Needed by foreign nationals to visit Arunachal Pradesh. Some '
      'nationalities need prior approval from the Ministry of Home Affairs.',
  documents: [
    'Valid passport and Indian visa',
    'Recent passport-size photos',
    'Planned itinerary and entry/exit points',
    'Booking with a registered tour operator, where required',
  ],
  steps: [
    'Check current rules with your Indian Mission or official portal',
    'Apply via a registered tour operator, Indian Mission, MHA/FRRO, or the '
        'Resident Commissioner of Arunachal Pradesh',
    'Keep the approved PAP with your passport',
    'Register on arrival where asked and carry photocopies',
    'Do not enter areas not listed on your permit',
  ],
  facts: [
    ('Typical validity', 'Limited period for listed circuits only'),
    ('Approx. fee', 'Varies — confirm with the issuing office'),
    ('Groups', 'Often arranged through a registered tour operator'),
  ],
  portalLabel: 'Official Arunachal permit portal',
);

class _PermitGuide extends StatelessWidget {
  const _PermitGuide({
    super.key,
    required this.info,
    required this.checked,
    required this.onToggle,
    required this.onOpenPortal,
  });

  final _PermitInfo info;
  final Set<int> checked;
  final ValueChanged<int> onToggle;
  final VoidCallback onOpenPortal;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    var i = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeIn(
            index: i++,
            child: OutlineCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TintIcon(
                    Icons.badge_outlined,
                    color: info.code == 'ILP'
                        ? AppColors.blue
                        : AppColors.green,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${info.name} (${info.code})',
                          style: t.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info.who,
                          style: t.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        FadeIn(
          index: i++,
          child: SectionHeader(
            'Documents checklist',
            subtitle: '${checked.length} of ${info.documents.length} ready',
          ),
        ),
        for (final (n, d) in info.documents.indexed)
          FadeIn(
            index: i++,
            child: CheckboxListTile(
              value: checked.contains(n),
              onChanged: (_) => onToggle(n),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(d, style: t.bodyMedium),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        FadeIn(index: i++, child: const SectionHeader('Steps')),
        for (final (n, s) in info.steps.indexed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: FadeIn(
              index: i++,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Text(
                      '${n + 1}',
                      style: t.labelSmall?.copyWith(color: AppColors.blue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(s, style: t.bodyMedium),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SectionHeader('Good to know'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlineCard(
            child: Column(
              children: [
                for (final (n, f) in info.facts.indexed) ...[
                  if (n > 0) const Divider(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(f.$1, style: t.bodySmall),
                      ),
                      Expanded(child: Text(f.$2, style: t.bodyMedium)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: FilledButton.icon(
            onPressed: onOpenPortal,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(info.portalLabel),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: OutlinedButton.icon(
            onPressed: () =>
                showSoonSnack(context, 'In-app application is coming soon'),
            icon: const Icon(Icons.edit_note_outlined, size: 18),
            label: const Text('Start in-app application (soon)'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: InfoNote(
            'Official ILP portal: arunachalilp.com. Verify current rules, '
            'fees and permitted areas there or with the issuing authority.',
          ),
        ),
      ],
    );
  }
}
