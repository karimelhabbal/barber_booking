import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../payment_config.dart';

/// Hosts the provider's hosted checkout. Closing/reaching the return URL only signals the UI to start
/// server-side verification. It never reports success.
class PaymobCheckoutPage extends StatefulWidget {
  const PaymobCheckoutPage({super.key, required this.url});

  final String url;

  static Route<bool> route(String url) =>
      MaterialPageRoute<bool>(fullscreenDialog: true, builder: (_) => PaymobCheckoutPage(url: url));

  @override
  State<PaymobCheckoutPage> createState() => _PaymobCheckoutPageState();
}

class _PaymobCheckoutPageState extends State<PaymobCheckoutPage> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || uri.scheme != 'https') return NavigationDecision.prevent;
            if (request.url.startsWith(PaymentConfig.returnUrlPrefix)) {
              if (mounted) Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(false)),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress == 0 ? null : _progress / 100),
              )
            : null,
      ),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
