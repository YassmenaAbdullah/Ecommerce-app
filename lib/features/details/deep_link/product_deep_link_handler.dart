import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../screens/product_details_loader_screen.dart';
import 'product_deep_link_parser.dart';

/// Routes incoming product deep links to [ProductDetailsLoaderScreen] on
/// top of whatever the app is currently showing, using plain [Navigator]
/// (the project's only routing mechanism - no second routing system).
///
/// Two paths into the app are handled, matching how Android/iOS actually
/// deliver links:
///  - [listen]: links received while the process is already running
///    (foreground or background) - safe to act on immediately.
///  - [handleInitialLink]: the link that cold-launched the app, if any.
///    Call this once, after the existing splash screen has already
///    navigated away (e.g. from `LoginScreen.initState`) - never while
///    splash's own `pushReplacement` is still pending, since pushing a
///    route on top of splash would make that `pushReplacement` swap out
///    this screen instead of splash's.
class ProductDeepLinkHandler {
  factory ProductDeepLinkHandler() => _instance;

  ProductDeepLinkHandler._internal({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  static final ProductDeepLinkHandler _instance =
      ProductDeepLinkHandler._internal();

  final AppLinks _appLinks;
  Uri? _lastHandledUri;

  StreamSubscription<Uri> listen(GlobalKey<NavigatorState> navigatorKey) {
    return _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri, navigatorKey.currentState),
      onError: (_) {},
    );
  }

  Future<void> handleInitialLink(NavigatorState? navigatorState) async {
    final uri = await _appLinks.getInitialLink();
    if (uri == null) return;
    _handle(uri, navigatorState);
  }

  void _handle(Uri uri, NavigatorState? navigatorState) {
    if (navigatorState == null) return;
    // Ignore a repeat of the same link (e.g. platforms that redeliver the
    // cold-start link via the stream too) so we never push a duplicate
    // Product Details screen for one incoming link.
    if (_lastHandledUri == uri) return;

    final productId = parseProductDeepLinkId(uri);
    if (productId == null) return;

    _lastHandledUri = uri;
    navigatorState.push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsLoaderScreen(productId: productId),
      ),
    );
  }
}
