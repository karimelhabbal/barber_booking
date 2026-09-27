import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/barber_shop/domain/entities/barber_shop.dart';
import 'package:barber_booking/features/settings/views/settings_page.dart';
import 'package:flutter/material.dart';

import 'barber_appointments_page.dart';
import 'barber_availability_page.dart';
import 'barber_dashboard_page.dart';

/// In-dashboard workspace shell for barber users.
///
/// Owns the section navigation state locally, keeps every section alive with
/// an [IndexedStack] and never touches the GoRouter: `BarberDashboardPage`
/// stays the barber entry point and this shell only replaces its content.
class BarberWorkspaceShell extends StatefulWidget {
  const BarberWorkspaceShell({
    super.key,
    required this.barberId,
    required this.barberName,
    required this.shop,
  });

  final String barberId;
  final String barberName;
  final BarberShop shop;

  @override
  State<BarberWorkspaceShell> createState() => _BarberWorkspaceShellState();
}

class _BarberWorkspaceShellState extends State<BarberWorkspaceShell> {
  static const double _railBreakpoint = 720;

  int _selectedIndex = 0;

  void _selectSection(int index) {
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final sections = <_WorkspaceSection>[
      _WorkspaceSection(
        label: loc.dashboard,
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        page: BarberDashboardTab(
          barberId: widget.barberId,
          barberName: widget.barberName,
          shop: widget.shop,
        ),
      ),
      _WorkspaceSection(
        label: loc.appointments,
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        page: BarberAppointmentsPage(barberId: widget.barberId),
      ),
      _WorkspaceSection(
        label: loc.availability,
        icon: Icons.schedule_outlined,
        selectedIcon: Icons.schedule,
        page: BarberAvailabilityPage(barberId: widget.barberId),
      ),
      _WorkspaceSection(
        label: loc.settings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        page: const SettingsPage(),
      ),
    ];

    final content = IndexedStack(
      index: _selectedIndex,
      children: [
        for (final section in sections) section.page,
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _railBreakpoint) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: true,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _selectSection,
                    destinations: [
                      for (final section in sections)
                        NavigationRailDestination(
                          icon: Icon(section.icon),
                          selectedIcon: Icon(section.selectedIcon),
                          label: _SectionLabel(label: section.label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectSection,
            destinations: [
              for (final section in sections)
                NavigationDestination(
                  icon: Icon(section.icon),
                  selectedIcon: Icon(section.selectedIcon),
                  label: section.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkspaceSection {
  const _WorkspaceSection({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

/// Keeps rail labels from overflowing on narrow windows or in RTL.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
