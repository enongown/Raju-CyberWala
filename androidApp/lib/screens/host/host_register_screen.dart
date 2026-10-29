import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Mock registration form. Nothing is submitted anywhere.
class HostRegisterScreen extends StatefulWidget {
  const HostRegisterScreen({super.key});

  @override
  State<HostRegisterScreen> createState() => _HostRegisterScreenState();
}

class _HostRegisterScreenState extends State<HostRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final Set<HostType> _types = {HostType.homestay};
  bool _crafts = false;

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    showSoonSnack(
      context,
      'Saved. A local volunteer will call to verify (demo).',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Required' : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Tell travellers about you', style: t.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Takes about 2 minutes. You can edit later.',
              style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Your name'),
              validator: required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixText: '+91 ',
              ),
              keyboardType: TextInputType.phone,
              validator: required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Village / town'),
              validator: required,
            ),
            const SizedBox(height: 24),
            Text('What do you offer?', style: t.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in HostType.values)
                  FilterChip(
                    label: Text(type.label),
                    selected: _types.contains(type),
                    onSelected: (on) => setState(
                      () => on ? _types.add(type) : _types.remove(type),
                    ),
                  ),
                FilterChip(
                  label: const Text('Crafts / shop'),
                  selected: _crafts,
                  onSelected: (on) => setState(() => _crafts = on),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Price (per night / day)',
                prefixText: '₹ ',
                helperText: 'We show a fair local range to guide you',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Languages you speak',
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _submit,
              child: const Text('Submit for verification'),
            ),
            const SizedBox(height: 14),
            const InfoNote('Demo only — details are not sent anywhere.'),
          ],
        ),
      ),
    );
  }
}
