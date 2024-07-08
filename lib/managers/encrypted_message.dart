import 'package:loser_night/components/platform_infos.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sqflite/sqflite.dart' as sqlite;

class EncryptedMessage {
  static final EncryptedMessage _instance = EncryptedMessage._internal();
  EncryptedMessage._internal();
  factory EncryptedMessage() => _instance;

  Future<Client> init() async {
    final cName = '${PlatformInfos.clientName}-${DateTime.now().millisecondsSinceEpoch}';
    final client = Client(
      cName,
      databaseBuilder: (_) async {
        final dir = await getApplicationSupportDirectory();
        final db = MatrixSdkDatabase(
          cName,
          database: await sqlite.openDatabase('$dir/database.sqlite'),
        );
        await db.open();
        return db;
      },
    );
    await client.init();
    return client;
  }
}
