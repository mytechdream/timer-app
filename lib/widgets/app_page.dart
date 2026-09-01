import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.phoneMaxWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minHeight =
                  constraints.maxHeight > 46 ? constraints.maxHeight - 46 : 0.0;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.pageHorizontalPadding,
                  46,
                  AppLayout.pageHorizontalPadding,
                  0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
