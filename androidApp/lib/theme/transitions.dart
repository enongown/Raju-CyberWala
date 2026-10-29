import 'package:flutter/material.dart';

/// Gentle fade + small upward slide used for every page transition.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeSlideTransition(animation: animation, child: child);
  }
}

class FadeSlideTransition extends StatelessWidget {
  const FadeSlideTransition({
    super.key,
    required this.animation,
    required this.child,
    this.offset = const Offset(0, 0.03),
  });

  final Animation<double> animation;
  final Widget child;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: offset,
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// A route that fades and slides in. Used for role switches and detail pages.
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeSlideTransition(animation: animation, child: child),
  );
}
