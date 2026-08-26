import 'package:flutter/material.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';

AppBar buildLocalizedAppBar(BuildContext context, {String? titleKey}) {
  final loc = AppLocalizations.of(context)!;
  final title = titleKey ?? loc.appTitle;
  return AppBar(title: Text(title));
}
