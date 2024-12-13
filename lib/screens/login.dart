import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:loser_night/components/sso_button.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

enum SsoLoginState {
  success,
  error,
  tokenEmpty,
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List<IdentityProvider> identityProviders = [];
  bool loading = false;

  void getSSO() async {
    Map<String, dynamic>? jsonResp = <String, dynamic>{};
    http.Client httpClient = http.Client();
    final headers = <String, String>{};
    final homeserver = Uri.https('matrix.org', '');

    var resp = await httpClient.get(homeserver.resolve('_matrix/client/r0/login'), headers: headers);
    var respBody = resp.body;
    try {
      respBody = utf8.decode(resp.bodyBytes);
    } catch (_) {}
    if (resp.statusCode >= 500 && resp.statusCode < 600) {
      throw Exception(respBody);
    }
    var jsonString = String.fromCharCodes(respBody.runes);
    if (jsonString.startsWith('[') && jsonString.endsWith(']')) {
      jsonString = '{"chunk":$jsonString}';
    }
    jsonResp = jsonDecode(jsonString) as Map<String, dynamic>?;

    if (resp.statusCode >= 400 && resp.statusCode < 500) {
      throw MatrixException(resp);
    }

    var login = jsonResp!.tryGetList('flows')!.singleWhere((flow) => flow['type'] == AuthenticationTypes.sso)['identity_providers'] as List;
    var identityProviders = login.map((e) => IdentityProvider.fromJson(e)).toList();
    setState(() {
      this.identityProviders = identityProviders;
    });
  }

  @override
  void initState() {
    super.initState();
    getSSO();
  }

  Future<SsoLoginState> ssoLoginActionMobile({
    required BuildContext context,
    required String id,
  }) async {
    try {
      final result = await authenticateWithWebAuth(context: context, id: id);
      final token = Uri.parse(result).queryParameters['loginToken'];
      if (token?.isEmpty ?? false) return SsoLoginState.tokenEmpty;
      final client = Provider.of<Client>(context, listen: false);
      await client.checkHomeserver(Uri.https('matrix.org', ''));
      await client.login(
        LoginType.mLoginToken,
        token: token!,
        initialDeviceDisplayName: 'Loser Night Chat',
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/room_list', (route) => false);

      return SsoLoginState.success;
    } catch (e) {
      Logs().e('ConnectPageMixin:: ssoLoginActionMobil(): error: $e');
      return SsoLoginState.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            children: [
              for (var identityProvider in identityProviders)
                SsoButton(
                  identityProvider: identityProvider,
                  onPressed: () async {
                    final state = await ssoLoginActionMobile(context: context, id: identityProvider.id!);
                    if (state == SsoLoginState.tokenEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Token is empty'),
                        ),
                      );
                    } else if (state == SsoLoginState.error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error'),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _getAuthenticateUrl({
  required BuildContext context,
  required String id,
  required String redirectUrl,
}) {
  final ssoRedirectUri = 'https://matrix.org/_matrix/client/r0/login/sso/redirect/${Uri.encodeComponent(id)}';
  final redirectUrlEncode = Uri.encodeQueryComponent(redirectUrl);
  return '$ssoRedirectUri?redirectUrl=$redirectUrlEncode';
}

Future<String> authenticateWithWebAuth({
  required BuildContext context,
  required String id,
}) async {
  const redirectUrl = 'loser.night://login';
  final url = _getAuthenticateUrl(
    context: context,
    id: id,
    redirectUrl: redirectUrl,
  );
  final urlScheme = _getRedirectUrlScheme(redirectUrl);
  return await FlutterWebAuth2.authenticate(
    url: url,
    callbackUrlScheme: urlScheme,
  );
}

String _getRedirectUrlScheme(String redirectUrl) {
  return Uri.parse(redirectUrl).scheme;
}
