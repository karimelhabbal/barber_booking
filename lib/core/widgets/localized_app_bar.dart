import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

PreferredAppBar(BuildContext context, {String? titleKey}) {
  final loc = AppLocalizations.of(context)!;
  final title = titleKey == null ? loc.appTitle : titleKey;
  return AppBar(title: Text(title));
}
