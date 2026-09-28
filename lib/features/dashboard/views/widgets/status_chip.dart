part of '../barber_dashboard_page.dart';

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    String text;

    switch (status) {
      case BookingStatus.pending:
        text = loc.pending;
        break;
      case BookingStatus.confirmed:
        text = loc.confirmed;
        break;
      case BookingStatus.completed:
        text = loc.completed;
        break;
      case BookingStatus.cancelled:
        text = loc.cancelled;
        break;
      case BookingStatus.noShow:
        text = loc.noShow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
