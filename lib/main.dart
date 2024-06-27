import 'package:flutter/material.dart';
import 'package:loser_night/screens/login.dart';
import 'package:loser_night/screens/register.dart';
import 'package:loser_night/screens/room.dart';
import 'package:loser_night/screens/room_list.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cName = 'Losers Night${DateTime.now().millisecondsSinceEpoch}';
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
  runApp(LoserNightChatApp(client: client));
}

class LoserNightChatApp extends StatelessWidget {
  final Client client;
  const LoserNightChatApp({required this.client, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        builder: (context, child) => Provider<Client>(
              create: (context) => client,
              child: child,
            ),
        home: client.isLogged() ? const RoomListPage() : const LoginPage(),
        routes: {
          '/login': (_) => const LoginPage(),
          '/room_list': (_) => const RoomListPage(),
          '/register': (_) => const RegisterPage(),
          '/room': (_) {
            final room = ModalRoute.of(context)!.settings.arguments as Room;
            return RoomPage(room: room);
          }
        });
  }
}
