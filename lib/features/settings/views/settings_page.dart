import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:barber_booking/features/settings/settings_cubit.dart';
import 'package:barber_booking/core/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final loc = AppLocalizations.of(context)!;
        final isDarkMode = state.themeMode == ThemeMode.dark;
        final selectedLanguage = state.locale.languageCode == 'ar'
            ? 'ar'
            : 'en';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text(loc.settings)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              _SettingsSection(
                title: loc.language,
                icon: Icons.language_outlined,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(value: 'en', label: Text('EN')),
                    ButtonSegment<String>(value: 'ar', label: Text('AR')),
                  ],
                  selected: {selectedLanguage},
                  onSelectionChanged: (selection) {
                    context.read<SettingsCubit>().changeLanguage(
                      selection.first,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: loc.theme,
                icon: isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isDarkMode ? loc.dark : loc.light),
                  subtitle: Text(loc.theme),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (_) =>
                        context.read<SettingsCubit>().toggleTheme(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: Text(loc.logout),
                  onTap: () => context.read<AuthCubit>().logout(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
