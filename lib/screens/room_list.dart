import 'package:flutter/material.dart';
import 'package:loser_night/components/chat_card.dart';
import 'package:loser_night/components/room_create_sheet.dart';
import 'package:loser_night/screens/login.dart';
import 'package:loser_night/screens/room.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  void _logout() async {
    final client = Provider.of<Client>(context, listen: false);
    await client.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _join(Room room) async {
    if (room.membership != Membership.join) {
      await room.join();
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomPage(room: room),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          scaffoldKey.currentState!.showBottomSheet(
            (context) => const RoomCreateSheet(),
            showDragHandle: true,
          );
        },
        child: const Icon(Icons.person_add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
        },
        child: StreamBuilder(
          stream: client.onSync.stream,
          builder: (context, _) => ListView.builder(
            itemCount: client.rooms.length,
            itemBuilder: (context, i) => ChatCard(
              room: client.rooms[i],
              onPress: () => _join(client.rooms[i]),
            ),
          ),
        ),
      ),
    );
  }
}
