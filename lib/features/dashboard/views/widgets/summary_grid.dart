part of '../barber_dashboard_page.dart';

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.completed,
  });

  final int total;
  final int pending;
  final int confirmed;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _SummaryCard(title: 'Total', value: total, icon: Icons.calendar_today),
        _SummaryCard(title: 'Pending', value: pending, icon: Icons.schedule),
        _SummaryCard(
          title: 'Confirmed',
          value: confirmed,
          icon: Icons.check_circle_outline,
        ),
        _SummaryCard(
          title: 'Completed',
          value: completed,
          icon: Icons.done_all,
        ),
      ],
    );
  }
}
