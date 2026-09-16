import 'package:flutter/material.dart';

import 'package:barber_booking/core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.label});

  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    final displayLabel = label ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayLabel,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }

  Color _statusColor(BuildContext context, String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return AppColors.pending;
      case 'confirmed':
      case 'in-progress':
      case 'in progress':
        return AppColors.primaryHighlight;
      case 'completed':
      case 'success':
        return AppColors.success;
      case 'cancelled':
      case 'canceled':
      case 'error':
        return AppColors.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
