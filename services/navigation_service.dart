import 'package:flutter/material.dart';

/// Service for handling navigation between screens
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() => _instance;

  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to a new route without replacing current route
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushNamed(routeName, arguments: arguments);
  }

  /// Replace current route with new route
  Future<dynamic> replaceTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Custom page transition
  PageRouteBuilder customPageTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeInOutQuart,
    Offset? beginOffset,
  }) {
    beginOffset ??= const Offset(1.0, 0.0);

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var end = Offset.zero;
        var tween =
            Tween(begin: beginOffset, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Pop the current route
  void goBack() {
    navigatorKey.currentState!.pop();
  }

  /// Pop until a specific route
  void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }
}