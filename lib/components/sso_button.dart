import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loser_night/utils/custom_http_client.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

class SsoButton extends StatelessWidget {
  final IdentityProvider identityProvider;
  final void Function()? onPressed;
  const SsoButton({
    super.key,
    required this.identityProvider,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: identityProvider.icon == null
                    ? const Icon(Icons.web_outlined)
                    : Image.network(
                        identityProvider.getIcon().toString(),
                        width: 48,
                        height: 48,
                        errorBuilder: (_, __, ___) => const Icon(Icons.web_outlined),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              identityProvider.name ?? identityProvider.brand ?? 'Unknown',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IdentityProvider {
  final String? id;
  final String? name;
  final String? icon;
  final String? brand;

  IdentityProvider({this.id, this.name, this.icon, this.brand});

  factory IdentityProvider.fromJson(Map<String, dynamic> json) => IdentityProvider(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        brand: json['brand'],
      );

  Uri getIcon() {
    Uri uri = Uri.parse(icon ?? '');
    if (uri.isScheme('mxc')) {
      uri = Uri(scheme: 'https', host: 'matrix.org', path: '/_matrix/media/r0/download/${uri.host}${uri.path}');
    }
    return uri;
  }

  Client client(String name) {
    return Client(
      name,
      httpClient: !kIsWeb && Platform.isAndroid ? CustomHttpClient.createHTTPClient() : null,
      verificationMethods: {
        KeyVerificationMethod.numbers,
        KeyVerificationMethod.emoji,
      },
      importantStateEvents: <String>{
        'im.ponies.room_emotes',
        EventTypes.RoomPowerLevels,
      },
      logLevel: kReleaseMode ? Level.warning : Level.verbose,
      databaseBuilder: (_) async {
        final dir = await getApplicationSupportDirectory();
        final db = MatrixSdkDatabase(
          "$name${DateTime.now().millisecondsSinceEpoch}",
          database: await sqlite.openDatabase('$dir/database.sqlite'),
        );
        await db.open();
        return db;
      },
    );
  }
}
