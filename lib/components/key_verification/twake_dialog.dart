import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:loser_night/components/platform_infos.dart';
import 'package:matrix/matrix.dart';

class TwakeDialog {
  static const double maxWidthLoadingDialogWeb = 448;

  static const double lottieSizeWeb = 80;

  static const double lottieSizeMobile = 48;

  static void hideLoadingDialog(BuildContext context) {
    if (PlatformInfos.isWeb) {
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
    }
  }

  static void showLoadingDialog(BuildContext context) {
    showGeneralDialog(
      barrierColor: LinagoraSysColors.material().onPrimary.withOpacity(0.75),
      useRootNavigator: PlatformInfos.isWeb,
      transitionDuration: const Duration(milliseconds: 700),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(animation),
          child: PopScope(
            canPop: false,
            child: ProgressDialog(
              lottieSize: PlatformInfos.isWeb ? lottieSizeWeb : lottieSizeMobile,
            ),
          ),
        );
      },
      context: context,
      pageBuilder: (c, a1, a2) {
        return const SizedBox();
      },
    );
  }

  static Future<LoadingDialogResult<T>> showFutureLoadingDialogFullScreen<T>({
    required Future<T> Function() future,
    required BuildContext? context,
  }) async {
    final twakeContext = context;
    if (twakeContext == null) {
      Logs().e(
        'TwakeLoadingDialog()::showFutureLoadingDialogFullScreen - Twake context is null',
      );
      return LoadingDialogResult<T>(
        error: Exception('FutureDialog canceled'),
        stackTrace: StackTrace.current,
      );
    }

    if (PlatformInfos.isWeb) {
      return _dialogFullScreenWeb(future: future, context: twakeContext);
    } else {
      return _dialogFullScreenMobile(future: future, context: twakeContext);
    }
  }

  static Future<LoadingDialogResult<T>> _dialogFullScreenWeb<T>({
    required Future<T> Function() future,
    required BuildContext context,
  }) async {
    return await showFutureLoadingDialog(
      context: context,
      future: future,
      loadingIcon: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
      ),
      barrierColor: LinagoraSysColors.material().onPrimary.withOpacity(0.75),
      loadingTitle: "loading",
      loadingTitleStyle: Theme.of(context).textTheme.titleLarge,
      maxWidth: maxWidthLoadingDialogWeb,
      errorTitle: "errorDialogTitle",
      errorTitleStyle: Theme.of(context).textTheme.titleLarge,
      errorBackLabel: "cancel",
      errorBackLabelStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
      errorNextLabel: "next",
      errorNextLabelStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
      backgroundNextLabel: Theme.of(context).colorScheme.primary,
    );
  }

  static Future<LoadingDialogResult<T>> _dialogFullScreenMobile<T>({
    required Future<T> Function() future,
    required BuildContext context,
  }) async {
    return await showFutureLoadingDialog(
      context: context,
      future: future,
      loadingIcon: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
      ),
      barrierColor: LinagoraSysColors.material().onPrimary.withOpacity(0.75),
      loadingTitle: "loading",
      loadingTitleStyle: Theme.of(context).textTheme.titleMedium,
      errorTitle: "errorDialogTitle",
      errorTitleStyle: Theme.of(context).textTheme.titleMedium,
      errorBackLabel: "cancel",
      errorBackLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
      errorNextLabel: "next",
      errorNextLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
      backgroundNextLabel: Theme.of(context).colorScheme.primary,
    );
  }

  static Future<bool?> showDialogFullScreen({
    required Widget Function() builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    required BuildContext? context,
  }) {
    final twakeContext = context;
    if (twakeContext == null) {
      Logs().e(
        'TwakeLoadingDialog()::showDialogFullScreen - Twake context is null',
      );
      return Future.value(null);
    }
    return showDialog(
      context: twakeContext,
      builder: (context) => builder(),
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      useRootNavigator: false,
    );
  }

  static Future<bool?> showCupertinoDialogFullScreen({
    required Widget Function() builder,
    required BuildContext? context,
  }) {
    final twakeContext = context;
    if (twakeContext == null) {
      Logs().e(
        'TwakeLoadingDialog()::showCupertinoDialogFullScreen - Twake context is null',
      );
      return Future.value(null);
    }
    return showCupertinoDialog(
      context: twakeContext,
      builder: (context) => builder(),
      barrierDismissible: true,
      useRootNavigator: false,
    );
  }
}

class ProgressDialog extends StatelessWidget {
  final double lottieSize;

  const ProgressDialog({
    super.key,
    required this.lottieSize,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Text(
            "loading",
            style: PlatformInfos.isWeb ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
