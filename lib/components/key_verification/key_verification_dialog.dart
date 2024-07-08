import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:loser_night/components/platform_infos.dart';
import 'package:loser_night/components/settings/avatar.dart';
import 'package:loser_night/components/key_verification/twake_dialog.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';

class KeyVerificationDialog extends StatefulWidget {
  Future<void> show(BuildContext context) => showAdaptiveBottomSheet(
        context: context,
        builder: (context) => this,
        isDismissible: false,
      );

  final KeyVerification request;

  const KeyVerificationDialog({
    super.key,
    required this.request,
  });

  @override
  KeyVerificationPageState createState() => KeyVerificationPageState();
}

class KeyVerificationPageState extends State<KeyVerificationDialog> {
  void Function()? originalOnUpdate;
  late final List<dynamic> sasEmoji;

  @override
  void initState() {
    originalOnUpdate = widget.request.onUpdate;
    widget.request.onUpdate = () {
      originalOnUpdate?.call();
      setState(() {});
    };
    widget.request.client.getProfileFromUserId(widget.request.userId).then((p) {
      profile = p;
      setState(() {});
    });
    rootBundle.loadString('assets/sas-emoji.json').then((e) {
      sasEmoji = json.decode(e);
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.request.onUpdate = originalOnUpdate; // don't want to get updates anymore
    if (![
      KeyVerificationState.error,
      KeyVerificationState.done
    ].contains(widget.request.state)) {
      widget.request.cancel('m.user');
    }
    super.dispose();
  }

  Profile? profile;

  Future<void> checkInput(String input) async {
    if (input.isEmpty) return;

    final valid = await TwakeDialog.showFutureLoadingDialogFullScreen(
      context: context,
      future: () async {
        // make sure the loading spinner shows before we test the keys
        await Future.delayed(const Duration(milliseconds: 100));
        var valid = false;
        try {
          await widget.request.openSSSS(keyOrPassphrase: input);
          valid = true;
        } catch (_) {
          valid = false;
        }
        return valid;
      },
    );
    if (valid.error != null) {
      await showOkAlertDialog(
        useRootNavigator: false,
        context: context,
        message: "incorrectPassphraseOrKey",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user;
    final directChatId = widget.request.client.getDirectChatFromUserId(widget.request.userId);
    if (directChatId != null) {
      user = widget.request.client.getRoomById(directChatId)!.unsafeGetUserFromMemoryOrFallback(widget.request.userId);
    }
    final displayName = user?.calcDisplayname() ?? widget.request.userId.localpart!;
    var title = const Text("verifyTitle");
    Widget body;
    final buttons = <Widget>[];
    switch (widget.request.state) {
      case KeyVerificationState.showQRSuccess:
      case KeyVerificationState.confirmQRScan:
      case KeyVerificationState.askChoice:
        throw 'Not implemented';
      case KeyVerificationState.askSSSS:
        // prompt the user for their ssss passphrase / key
        final textEditingController = TextEditingController();
        String input;
        body = Container(
          margin: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                "askSSSSSign",
                style: TextStyle(fontSize: 20),
              ),
              Container(height: 10),
              TextField(
                controller: textEditingController,
                autofocus: false,
                autocorrect: false,
                onSubmitted: (s) {
                  input = s;
                  checkInput(input);
                },
                minLines: 1,
                maxLines: 1,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "passphraseOrKey",
                  prefixStyle: TextStyle(color: Theme.of(context).primaryColor),
                  suffixStyle: TextStyle(color: Theme.of(context).primaryColor),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
        buttons.add(
          TextButton(
            child: const Text(
              "submit",
            ),
            onPressed: () => checkInput(textEditingController.text),
          ),
        );
        buttons.add(
          TextButton(
            child: const Text(
              "skip",
            ),
            onPressed: () => widget.request.openSSSS(skip: true),
          ),
        );
        break;
      case KeyVerificationState.askAccept:
        title = const Text("newVerificationRequest");
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Avatar(
              url: user?.avatarUrl,
              name: displayName,
              size: AvatarStyle.defaultSize * 2,
            ),
            const SizedBox(height: 16),
            const Text(
              " askVerificationRequest(displayName)",
            ),
          ],
        );
        buttons.add(
          TextButton.icon(
            icon: const Icon(Icons.close),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            label: const Text("reject"),
            onPressed: () => widget.request.rejectVerification().then((_) => Navigator.of(context, rootNavigator: false).pop()),
          ),
        );
        buttons.add(
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: const Text("accept"),
            onPressed: () => widget.request.acceptVerification(),
          ),
        );
        break;
      case KeyVerificationState.waitingAccept:
        body = Center(
          child: Column(
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: [
                  Avatar(
                    url: user?.avatarUrl,
                    name: displayName,
                  ),
                  const SizedBox(
                    width: AvatarStyle.defaultSize + 2,
                    height: AvatarStyle.defaultSize + 2,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "waitingPartnerAcceptRequest",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

        break;
      case KeyVerificationState.askSas:
        TextSpan compareWidget;
        // maybe add a button to switch between the two and only determine default
        // view for if "emoji" is a present sasType or not?

        if (widget.request.sasTypes.contains('emoji')) {
          title = const Text(
            "compareEmojiMatch",
            maxLines: 1,
            style: TextStyle(fontSize: 16),
          );
          compareWidget = TextSpan(
            children: widget.request.sasEmojis.map((e) => WidgetSpan(child: _Emoji(e, sasEmoji))).toList(),
          );
        } else {
          title = const Text("compareNumbersMatch");
          final numbers = widget.request.sasNumbers;
          final numbstr = '${numbers[0]}-${numbers[1]}-${numbers[2]}';
          compareWidget = TextSpan(text: numbstr, style: const TextStyle(fontSize: 40));
        }
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text.rich(
              compareWidget,
              textAlign: TextAlign.center,
            ),
          ],
        );
        buttons.add(
          TextButton.icon(
            icon: const Icon(Icons.close),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            label: const Text("theyDontMatch"),
            onPressed: () => widget.request.rejectSas(),
          ),
        );
        buttons.add(
          TextButton.icon(
            icon: const Icon(Icons.check_outlined),
            label: const Text("theyMatch"),
            onPressed: () => widget.request.acceptSas(),
          ),
        );
        break;
      case KeyVerificationState.waitingSas:
        final acceptText = widget.request.sasTypes.contains('emoji') ? "waitingPartnerEmoji" : "waitingPartnerNumbers";
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator.adaptive(strokeWidth: 2),
            const SizedBox(height: 10),
            Text(
              acceptText,
              textAlign: TextAlign.center,
            ),
          ],
        );
        break;
      case KeyVerificationState.done:
        body = const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.check_circle_outlined,
              color: Colors.green,
              size: 128.0,
            ),
            SizedBox(height: 10),
            Text(
              "verifySuccess",
              textAlign: TextAlign.center,
            ),
          ],
        );
        buttons.add(
          TextButton(
            child: const Text(
              "close",
            ),
            onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
          ),
        );
        break;
      case KeyVerificationState.error:
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cancel, color: Colors.red, size: 128.0),
            const SizedBox(height: 10),
            Text(
              'Error ${widget.request.canceledCode}: ${widget.request.canceledReason}',
              textAlign: TextAlign.center,
            ),
          ],
        );
        buttons.add(
          TextButton(
            child: const Text(
              "close",
            ),
            onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
          ),
        );
        break;
    }
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: title,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          body
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: buttons,
          ),
        ),
      ),
    );
  }
}

class _Emoji extends StatelessWidget {
  final KeyVerificationEmoji emoji;
  final List<dynamic>? sasEmoji;

  const _Emoji(this.emoji, this.sasEmoji);

  String getLocalizedName() {
    final sasEmoji = this.sasEmoji;
    if (sasEmoji == null) {
      // asset is still being loaded
      return emoji.name;
    }
    final translations = Map<String, String?>.from(
      sasEmoji[emoji.number]['translated_descriptions'],
    );
    translations['en'] = emoji.name;
    // ignore: deprecated_member_use
    for (final locale in window.locales) {
      final wantLocaleParts = locale.toString().split('_');
      final wantLanguage = wantLocaleParts.removeAt(0);
      for (final haveLocale in translations.keys) {
        final haveLocaleParts = haveLocale.split('_');
        final haveLanguage = haveLocaleParts.removeAt(0);
        if (haveLanguage == wantLanguage && (Set.from(haveLocaleParts)..removeAll(wantLocaleParts)).isEmpty && (translations[haveLocale]?.isNotEmpty ?? false)) {
          return translations[haveLocale]!;
        }
      }
    }
    return emoji.name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(emoji.emoji, style: const TextStyle(fontSize: 50)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(getLocalizedName()),
        ),
        const SizedBox(height: 10, width: 5),
      ],
    );
  }
}

Future<T?> showAdaptiveBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool isScrollControlled = false,
  bool showDragHandle = false,
}) =>
    showModalBottomSheet(
      context: context,
      builder: builder,
      showDragHandle: showDragHandle,
      useRootNavigator: !PlatformInfos.isMobile,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height - 128,
        maxWidth: 360 * 1.5,
      ),
      clipBehavior: Clip.hardEdge,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
    );

Future<LoadingDialogResult<T>> showFutureLoadingDialogFullScreen<T>({
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
  return showFutureLoadingDialog(
    context: twakeContext,
    future: future,
    barrierDismissible: false,
    loadingIcon: const CircularProgressIndicator(),
    loadingTitle: "loading",
    errorTitle: "errorDialogTitle",
  );
}
