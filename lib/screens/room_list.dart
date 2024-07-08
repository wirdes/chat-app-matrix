import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:loser_night/components/bootstrap/bootstrap_dialog.dart';
import 'package:loser_night/components/chat_card.dart';
import 'package:loser_night/components/room_create_sheet.dart';
import 'package:loser_night/components/settings/avatar.dart';
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
  void checkBootstrap(Client client) async {
    if (!client.encryptionEnabled) return;
    await client.accountDataLoading;
    await client.userDeviceKeysLoading;
    if (client.prevBatch == null) {
      await client.onSync.stream.first;
    }
    final crossSigning = await client.encryption?.crossSigning.isCached() ?? false;
    final needsBootstrap = await client.encryption?.keyManager.isCached() == false || client.encryption?.crossSigning.enabled == false || crossSigning == false;
    if (needsBootstrap == true) {
      await BootstrapDialog(
        client: client,
      ).show(context);

      return;
    }
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
  void initState() {
    super.initState();
    final client = Provider.of<Client>(context, listen: false);
    checkBootstrap(client);
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('Chats', style: Theme.of(context).textTheme.headlineLarge),
        ),
        actions: [
          FutureBuilder(
              future: client.getUserProfile(client.userID!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final user = snapshot.data;
                  return Avatar(
                    url: user?.avatarUrl,
                    name: user?.displayname ?? client.userID,
                    size: 40,
                  );
                }
                return const CircularProgressIndicator();
              }),
          const SizedBox(width: 24),
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
