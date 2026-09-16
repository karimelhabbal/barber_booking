part of '../barber_dashboard_page.dart';

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 8),
            Text('$value', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}
