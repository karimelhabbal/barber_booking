part of '../customer_dashboard_page.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.customerName,
    required this.shopName,
    required this.loc,
  });

  final String? customerName;
  final String shopName;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting();

    final name = (customerName != null && customerName!.trim().isNotEmpty)
        ? customerName!.trim()
        : loc.customer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.primaryHighlight,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shopName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return loc.goodMorning;
    }

    if (hour < 18) {
      return loc.goodAfternoon;
    }

    return loc.goodEvening;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _BookAppointmentAction extends StatelessWidget {
  const _BookAppointmentAction({required this.shop, required this.barber});

  final BarberShop shop;
  final Barber? barber;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: double.infinity,
        child: AppButton(
          label: loc.bookNow,
          onPressed: barber == null
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CustomerServicesPage(shop: shop, barber: barber!),
                    ),
                  );
                },
        ),
      ),
    );
  }
}
