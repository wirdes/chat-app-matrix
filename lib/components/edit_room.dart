import 'package:flutter/material.dart';
import 'package:loser_night/components/chat/input.dart';
import 'package:loser_night/components/settings/avatar.dart';
import 'package:loser_night/managers/attachment.dart';
import 'package:matrix/matrix.dart';

class EditRoomWidget extends StatefulWidget {
  final Room room;
  const EditRoomWidget({super.key, required this.room});

  @override
  State<EditRoomWidget> createState() => _EditRoomWidgetState();
}

class _EditRoomWidgetState extends State<EditRoomWidget> {
  final controller = TextEditingController();
  bool editRoomName = false;

  @override
  void initState() {
    super.initState();
    controller.text = widget.room.getLocalizedDisplayname();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
            stream: widget.room.client.onSync.stream,
            builder: (context, snapshot) {
              return Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      InkWell(
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (context) {
                              final img = widget.room.avatar;

                              return Stack(
                                children: [
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                                      child: InteractiveViewer(
                                          child: Image.network(
                                        'https://matrix.org/_matrix/media/r0/download/${img!.host}${img.path}',
                                      )),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 4,
                                    child: Row(
                                      children: [
                                        IconButton(
                                            onPressed: () async {
                                              widget.room.setAvatar(null);

                                              Navigator.of(context).pop();
                                            },
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 24)),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                          },
                                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Avatar.fromRoom(widget.room, radius: 250),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Material(
                          color: Colors.white,
                          elevation: 3,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () async {
                              final img = await AttachmentManager().pickMedia(context);
                              if (img == null) return;
                              final byte = img.bytes;
                              final file = MatrixFile(
                                bytes: byte,
                                name: "LoserNight${DateTime.now().microsecondsSinceEpoch}.${img.name.split('.').last}",
                              );

                              await widget.room.setAvatar(file);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.camera_alt),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Input(
                    controller: controller,
                    label: "Oda Adı",
                    hintText: "Oda Adı",
                    disabled: !editRoomName,
                    onTapIcon: () async {
                      setState(() {
                        editRoomName = !editRoomName;
                      });
                      if (editRoomName) {
                        try {
                          await widget.room.setName(controller.text);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    suffixIcon: editRoomName ? Icons.check : Icons.edit,
                  ),
                  const SizedBox(height: 16),
                  const Text("Oda Üyeleri"),
                  FutureBuilder(
                      future: widget.room.loadHeroUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final users = snapshot.data as List<User>;
                        return SizedBox(
                          height: 100,
                          width: double.infinity,
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final member = users[index];
                              return ListTile(
                                title: Text(member.displayName ?? member.id),
                                leading: Avatar.fromUser(member),
                                trailing: widget.room.canKick
                                    ? IconButton(
                                        onPressed: () async {
                                          await widget.room.client.kick(widget.room.id, member.id);
                                        },
                                        icon: const Icon(Icons.delete),
                                      )
                                    : null,
                              );
                            },
                          ),
                        );
                      }),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        await widget.room.client.leaveRoom(widget.room.id);
                        Navigator.of(context).pop();
                      },
                      child: const Text("Odayı Sil"),
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }
}
