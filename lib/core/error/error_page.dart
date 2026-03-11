import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/error/error_reporter.dart';

/// This [AppErrorPage] displays when App Navigator or Router fails
///
/// Often this will be an [AssertionError], maybe specifically a [FlutterError]
class AppErrorPage extends StatelessWidget {
  const AppErrorPage(this.errorDetails, {super.key});

  final FlutterErrorDetails errorDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  LottiePath.error404,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _stringify(errorDetails.exception),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Exception to message
  static String _stringify(Object? exception) {
    try {
      return exception.toString();
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'AppErrorPage.stringify',
      );
    }
    return 'Error';
  }
}

/// This [AppErrorWidget] displays when App build component fails
///
/// Often this will be an [AssertionError], maybe specifically a [FlutterError]
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget(this.errorDetails, {super.key, this.widget});

  final FlutterErrorDetails errorDetails;
  final Widget? widget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Lottie.asset(
        LottiePath.error404,
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}
