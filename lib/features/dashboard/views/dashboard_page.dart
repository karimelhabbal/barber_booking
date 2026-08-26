import 'package:flutter/material.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.dashboard)),
      body: Center(child: Text(loc.dashboard)),
    );
  }
}
