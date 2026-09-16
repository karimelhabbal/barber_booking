part of '../barber_dashboard_page.dart';

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.barberName, required this.shopName});

  final String barberName;
  final String shopName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.content_cut, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $barberName',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(shopName, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
