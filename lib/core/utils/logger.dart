import 'package:logger/logger.dart';

/// A global logger instance to use throughout your app
var logger = Logger(
  filter: null,
  output: null,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
);
