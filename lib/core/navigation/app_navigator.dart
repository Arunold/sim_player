import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

/// Navigation helper extension on BuildContext
extension NavigationExtension on BuildContext {
  /// Navigate to a named route
  Future<T?> goTo<T>(String route) {
    return Navigator.pushNamed<T>(this, route);
  }

  /// Replace current route with a named route
  Future<T?> replaceTo<T>(String route) {
    return Navigator.pushReplacementNamed<T, void>(this, route);
  }

  /// Go to home and clear stack
  void goToHome() {
    Navigator.pushNamedAndRemoveUntil(
      this,
      AppRoutes.home,
      (route) => false,
    );
  }

  /// Pop current screen
  void goBack<T>([T? result]) {
    Navigator.pop(this, result);
  }

  /// Pop to first route
  void goToFirst() {
    Navigator.popUntil(this, (route) => route.isFirst);
  }

  /// Show a modal bottom sheet
  Future<T?> showSheet<T>({
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = false,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: builder,
    );
  }
}
