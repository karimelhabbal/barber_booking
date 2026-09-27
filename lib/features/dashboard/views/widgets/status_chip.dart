part of '../barber_dashboard_page.dart';

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String text;

    switch (status) {
      case BookingStatus.pending:
        text = 'Pending';
        break;
      case BookingStatus.confirmed:
        text = 'Confirmed';
        break;
      case BookingStatus.completed:
        text = 'Completed';
        break;
      case BookingStatus.cancelled:
        text = 'Cancelled';
        break;
      case BookingStatus.noShow:
        text = 'No-show';
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
