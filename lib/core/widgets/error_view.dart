import 'package:flutter/material.dart';

import 'package:barber_booking/core/widgets/app_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(label: retryLabel, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
