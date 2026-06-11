import 'package:flutter/material.dart';
import 'package:clarity_flutter/clarity_flutter.dart';

Widget wrapWithClarity({required Widget child}) {
  final config = ClarityConfig(
    projectId: "x5bx6pafoc",
    logLevel: LogLevel.None,
  );
  return ClarityWidget(
    app: child,
    clarityConfig: config,
  );
}
