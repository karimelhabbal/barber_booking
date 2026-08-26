import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/settings/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.settings)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.language),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(onPressed: () => context.read<SettingsCubit>().changeLanguage('en'), child: const Text('EN')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () => context.read<SettingsCubit>().changeLanguage('ar'), child: const Text('AR')),
              ],
            ),
            const SizedBox(height: 16),
            Text(loc.theme),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => context.read<SettingsCubit>().toggleTheme(), child: Text(loc.theme)),
          ],
        ),
      ),
    );
  }
}
