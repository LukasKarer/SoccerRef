import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that handles the physical back button (button 2) on Wear OS devices.
/// This ensures consistent back navigation behavior across all screens.
class WearBackButtonHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBackPressed;
  final bool canPop;

  const WearBackButtonHandler({
    super.key,
    required this.child,
    this.onBackPressed,
    this.canPop = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) {
        if (!didPop && canPop) {
          _handleBackPress(context);
        }
      },
      child: child,
    );
  }

  void _handleBackPress(BuildContext context) {
    if (onBackPressed != null) {
      onBackPressed!();
    } else {
      // Default behavior: pop the current route
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}

/// A mixin that provides back button handling functionality to StatefulWidgets
mixin WearBackButtonMixin<T extends StatefulWidget> on State<T> {
  /// Override this method to handle back button presses
  void onBackPressed() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Wrap your build method content with this widget
  Widget buildWithBackButtonHandler(
    Widget child, {
    VoidCallback? onBackPressed,
  }) {
    return WearBackButtonHandler(
      onBackPressed: onBackPressed ?? this.onBackPressed,
      child: child,
    );
  }
}
