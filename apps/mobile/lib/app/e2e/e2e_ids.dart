import 'package:flutter/widgets.dart';

class E2eId extends StatelessWidget {
  const E2eId({
    required this.id,
    required this.child,
    this.container = true,
    super.key,
  });

  final String id;
  final Widget child;
  final bool container;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey(id),
      identifier: id,
      container: container,
      child: child,
    );
  }
}
