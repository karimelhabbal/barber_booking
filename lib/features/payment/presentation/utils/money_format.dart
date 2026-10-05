/// 12550 piasters -> "125.50". No floating point involved.
String formatPiasters(int piasters) {
  final sign = piasters < 0 ? '-' : '';
  final abs = piasters.abs();
  final pounds = abs ~/ 100;
  final rem = (abs % 100).toString().padLeft(2, '0');
  return '$sign$pounds.$rem';
}

String formatEgp(int piasters) => '${formatPiasters(piasters)} ج.م';
