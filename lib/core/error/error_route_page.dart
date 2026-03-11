import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/router/router.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:kakikaki/app/widget/widget.dart';

class ErrorRoutePage extends StatelessWidget {
  const ErrorRoutePage(this.state, {super.key});

  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.error_page_not_found)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: Lottie.asset(
                  LottiePath.error404,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                state.error?.message ?? state.uri.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              CommonTextButton(
                isExpandedWidth: false,
                onPressed: () => navigate(
                  context,
                  path: InitialRoute().location,
                  method: NavigationMethod.go,
                ),
                text: l10n.action_go_back_to_first_page,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
