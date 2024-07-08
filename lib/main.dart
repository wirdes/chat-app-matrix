import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:loser_night/managers/encrypted_message.dart';
import 'package:loser_night/screens/login.dart';
import 'package:loser_night/screens/register.dart';
import 'package:loser_night/screens/room.dart';
import 'package:loser_night/screens/room_list.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final client = await EncryptedMessage().init();
  runApp(LoserNightChatApp(client: client));
}

class LoserNightChatApp extends StatelessWidget {
  final Client client;
  const LoserNightChatApp({required this.client, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
        },
      },
    );
  }
}
