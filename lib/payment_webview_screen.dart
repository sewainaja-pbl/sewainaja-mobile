import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;

  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _canPop = false;
  bool _isPopped = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            _checkUrl(url);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _checkUrl(url);
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              try {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                debugPrint('Error launching deep link: $e');
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _checkUrl(String url) {
    if (_isPopped) return;
    final lowerUrl = url.toLowerCase();
    
    // Check for success redirects
    if (lowerUrl.contains('status_code=200') ||
        lowerUrl.contains('transaction_status=settlement') ||
        lowerUrl.contains('/finish') ||
        lowerUrl.contains('success')) {
      if (mounted) {
        _isPopped = true;
        Navigator.pop(context, true);
      }
    } 
    // Check for pending/unfinish/error redirects
    else if (lowerUrl.contains('unfinish') ||
             lowerUrl.contains('status_code=201') ||
             lowerUrl.contains('transaction_status=pending')) {
      if (mounted) {
        _isPopped = true;
        Navigator.pop(context, false);
      }
    } else if (lowerUrl.contains('error') ||
               lowerUrl.contains('status_code=202') ||
               lowerUrl.contains('transaction_status=deny') ||
               lowerUrl.contains('cancel')) {
      if (mounted) {
        _isPopped = true;
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final canGoBack = await _controller.canGoBack();
        if (canGoBack) {
          await _controller.goBack();
        } else {
          setState(() {
            _canPop = true;
          });
          if (context.mounted) {
            _isPopped = true;
            Navigator.pop(context, false);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF9F4),
        appBar: AppBar(
          title: const Text(
            'Pembayaran Online',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Color(0xFF012D1D),
            ),
          ),
          backgroundColor: const Color(0xFFFDF9F4),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF012D1D)),
            onPressed: () {
              _isPopped = true;
              Navigator.pop(context, false);
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: const Color(0xFFC1C8C2), height: 1.0),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF012D1D)),
              ),
          ],
        ),
      ),
    );
  }
}
