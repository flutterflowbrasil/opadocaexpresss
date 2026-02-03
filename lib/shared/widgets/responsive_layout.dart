import 'package:flutter/material.dart';
import 'package:padoca_express/core/constants/breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext) mobile;
  final Widget Function(BuildContext)? tablet;
  final Widget Function(BuildContext)? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.tablet) {
          return desktop?.call(context) ??
              tablet?.call(context) ??
              mobile(context);
        } else if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet?.call(context) ?? mobile(context);
        } else {
          return mobile(context);
        }
      },
    );
  }
}
