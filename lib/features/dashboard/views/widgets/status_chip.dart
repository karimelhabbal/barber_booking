part of '../barber_dashboard_page.dart';

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
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

    return Text(text, style: Theme.of(context).textTheme.labelMedium);
  }
}
