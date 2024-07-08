import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loser_night/components/key_verification/key_verification_dialog.dart';
import 'package:loser_night/components/platform_infos.dart';
import 'package:loser_night/components/key_verification/twake_dialog.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';
import 'package:share_plus/share_plus.dart';

class BootstrapDialog extends StatefulWidget {
  final bool wipe;
  final Client client;

  const BootstrapDialog({
    super.key,
    this.wipe = false,
    required this.client,
  });

  Future<bool?> show(BuildContext context) => showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'BootstrapDialog',
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => BootstrapDialog(
          wipe: wipe,
          client: client,
        ),
      );

  @override
  BootstrapDialogState createState() => BootstrapDialogState();
}

class BootstrapDialogState extends State<BootstrapDialog> {
  final TextEditingController _recoveryKeyTextEditingController = TextEditingController();

  late Bootstrap bootstrap;

  String? _recoveryKeyInputError;

  bool _recoveryKeyInputLoading = false;

  String? titleText;

  bool _recoveryKeyStored = false;
  bool _recoveryKeyCopied = false;

  bool? _storeInSecureStorage = false;

  bool? _wipe;

  String get _secureStorageKey => 'ssss_recovery_key_${bootstrap.client.userID}';

  bool get _supportsSecureStorage => PlatformInfos.isMobile || PlatformInfos.isDesktop;

  String _getSecureStorageLocalizedName() {
    if (PlatformInfos.isMobile) {
      return "Secure storage";
    }
    if (PlatformInfos.isWindows) {
      return "Windows Credential Manager";
    } else if (PlatformInfos.isMacOS) {
      return "Keychain";
    } else if (PlatformInfos.isLinux) {
      return "Secret Service";
    } else {
      return "Secure storage";
    }
  }

  @override
  void initState() {
    _createBootstrap(widget.wipe);
    super.initState();
  }

  void _createBootstrap(bool wipe) async {
    _wipe = wipe;
    titleText = null;
    _recoveryKeyStored = false;
    bootstrap = widget.client.encryption!.bootstrap(onUpdate: (_) => setState(() {}));
    final key = await const FlutterSecureStorage().read(key: _secureStorageKey);
    if (key == null) return;
    _recoveryKeyTextEditingController.text = key;
  }

  @override
  Widget build(BuildContext context) {
    _wipe ??= widget.wipe;
    final buttons = <AdaptiveFlatButton>[];
    Widget body = const CircularProgressIndicator.adaptive();
    titleText = "loadingPleaseWait";

    if (bootstrap.newSsssKey?.recoveryKey != null && _recoveryKeyStored == false) {
      final key = bootstrap.newSsssKey!.recoveryKey;
      titleText = "recoveryKey";
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          title: Text("recoveryKey"),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360 * 1.5),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  trailing: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.info_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  subtitle: Text("chatBackupDescription"),
                ),
                const Divider(
                  height: 32,
                  thickness: 1,
                ),
                TextField(
                  minLines: 2,
                  maxLines: 4,
                  readOnly: true,
                  controller: TextEditingController(text: key),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(16),
                    suffixIcon: Icon(Icons.key_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                if (_supportsSecureStorage)
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    value: _storeInSecureStorage,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (b) {
                      setState(() {
                        _storeInSecureStorage = b;
                      });
                    },
                    title: Text(_getSecureStorageLocalizedName()),
                    subtitle: Text("storeInSecureStorageDescription"),
                  ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  value: _recoveryKeyCopied,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (b) {
                    final box = context.findRenderObject() as RenderBox;
                    Share.share(
                      key!,
                      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
                    );
                    setState(() => _recoveryKeyCopied = true);
                  },
                  title: Text("copyToClipboard"),
                  subtitle: Text("saveKeyManuallyDescription"),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_outlined),
                  label: Text("next"),
                  onPressed: (_recoveryKeyCopied || _storeInSecureStorage == true)
                      ? () {
                          if (_storeInSecureStorage == true) {
                            const FlutterSecureStorage().write(
                              key: _secureStorageKey,
                              value: key,
                            );
                          }
                          setState(() => _recoveryKeyStored = true);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      switch (bootstrap.state) {
        case BootstrapState.loading:
          break;
        case BootstrapState.askWipeSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap.wipeSsss(_wipe!),
          );
          break;
        case BootstrapState.askBadSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap.ignoreBadSecrets(true),
          );
          break;
        case BootstrapState.askUseExistingSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap.useExistingSsss(!_wipe!),
          );
          break;
        case BootstrapState.askUnlockSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap.unlockedSsss(),
          );
          break;
        case BootstrapState.askNewSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap.newSsss(),
          );
          break;
        case BootstrapState.openExistingSsss:
          _recoveryKeyStored = true;
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              title: Text("chatBackup"),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 360 * 1.5,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                      trailing: Icon(
                        Icons.info_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      subtitle: Text(
                        "pleaseEnterRecoveryKeyDescription",
                      ),
                    ),
                    const Divider(height: 32),
                    TextField(
                      minLines: 1,
                      maxLines: 2,
                      autocorrect: false,
                      readOnly: _recoveryKeyInputLoading,
                      autofillHints: _recoveryKeyInputLoading
                          ? null
                          : [
                              AutofillHints.password
                            ],
                      controller: _recoveryKeyTextEditingController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(16),
                        hintStyle: TextStyle(
                          fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                        ),
                        hintText: "recoveryKey",
                        errorText: _recoveryKeyInputError,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      icon: _recoveryKeyInputLoading ? const CircularProgressIndicator.adaptive() : const Icon(Icons.lock_open_outlined),
                      label: Text("unlockOldMessages"),
                      onPressed: _recoveryKeyInputLoading
                          ? null
                          : () async {
                              setState(() {
                                _recoveryKeyInputError = null;
                                _recoveryKeyInputLoading = true;
                              });
                              try {
                                final key = _recoveryKeyTextEditingController.text;
                                await bootstrap.newSsssKey!.unlock(
                                  keyOrPassphrase: key,
                                );
                                Logs().d('SSSS unlocked');
                                await bootstrap.client.encryption!.crossSigning.selfSign(
                                  keyOrPassphrase: key,
                                );
                                Logs().d('Successful elfsigned');
                                await bootstrap.openExistingSsss();
                              } catch (e, s) {
                                Logs().w('Unable to unlock SSSS', e, s);
                                setState(
                                  () => _recoveryKeyInputError = "oopsSomethingWentWrong",
                                );
                              } finally {
                                setState(
                                  () => _recoveryKeyInputLoading = false,
                                );
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text("or"),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cast_connected_outlined),
                      label: Text("transferFromAnotherDevice"),
                      onPressed: _recoveryKeyInputLoading
                          ? null
                          : () async {
                              final req = await TwakeDialog.showFutureLoadingDialogFullScreen(
                                future: () => widget.client.userDeviceKeys[widget.client.userID!]!.startVerification(),
                                context: context,
                              );
                              if (req.error != null) return;
                              await KeyVerificationDialog(request: req.result!).show(context);
                              Navigator.of(context, rootNavigator: false).pop();
                            },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      icon: const Icon(Icons.delete_outlined),
                      label: Text("recoveryKeyLost"),
                      onPressed: _recoveryKeyInputLoading
                          ? null
                          : () async {
                              if (OkCancelResult.ok ==
                                  await showOkCancelAlertDialog(
                                    useRootNavigator: false,
                                    context: context,
                                    title: "recoveryKeyLost",
                                    message: "wipeChatBackup",
                                    okLabel: "ok",
                                    cancelLabel: "cancel",
                                    isDestructiveAction: true,
                                  )) {
                                // if (Matrix.of(context).twakeSupported) {
                                //   await TomBootstrapDialog(
                                //     client: widget.client,
                                //     wipe: true,
                                //     wipeRecovery: true,
                                //   ).show().then(
                                //         (value) => Navigator.of(
                                //           context,
                                //           rootNavigator: false,
                                //         ).pop<bool>(false),
                                //       );
                                // }
                                // else {
                                //   _createBootstrap(true);
                                // }
                                _createBootstrap(true);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          );
        case BootstrapState.askWipeCrossSigning:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap.wipeCrossSigning(_wipe!),
          );
          break;
        case BootstrapState.askSetupCrossSigning:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap.askSetupCrossSigning(
              setupMasterKey: true,
              setupSelfSigningKey: true,
              setupUserSigningKey: true,
            ),
          );
          break;
        case BootstrapState.askWipeOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap.wipeOnlineKeyBackup(_wipe!),
          );

          break;
        case BootstrapState.askSetupOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap.askSetupOnlineKeyBackup(true),
          );
          break;
        case BootstrapState.error:
          titleText = "oopsSomethingWentWrong";
          body = const Icon(Icons.error_outline, color: Colors.red, size: 40);
          buttons.add(
            AdaptiveFlatButton(
              label: "close",
              onPressed: () => Navigator.of(context, rootNavigator: false).pop<bool>(false),
            ),
          );
          break;
        case BootstrapState.done:
          titleText = null;
          body = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/backup.png', fit: BoxFit.contain),
              Flexible(
                child: Text(
                  "yourChatBackupHasBeenSetUp",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
          buttons.add(
            AdaptiveFlatButton(
              label: "close",
              onPressed: () => Navigator.of(context, rootNavigator: false).pop<bool>(false),
            ),
          );
          break;
      }
    }

    return AlertDialog(
      content: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: body,
            ),
          ),
          if (titleText != null)
            Expanded(
              child: Text(
                titleText!,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      actions: buttons.isNotEmpty ? buttons : null,
    );
  }
}

class AdaptiveFlatButton extends StatelessWidget {
  final String label;
  final Color? textColor;
  final void Function()? onPressed;

  const AdaptiveFlatButton({
    super.key,
    required this.label,
    this.textColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
