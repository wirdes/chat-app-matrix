import 'package:flutter/material.dart' hide Visibility;
import 'package:loser_night/components/chat/input.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';

class RoomCreateSheet extends StatefulWidget {
  const RoomCreateSheet({super.key});

  @override
  State<RoomCreateSheet> createState() => _RoomCreateSheetState();
}

class _RoomCreateSheetState extends State<RoomCreateSheet> {
  final TextEditingController _roomNameTextField = TextEditingController();
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: size.height * 0.5,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Input(controller: _roomNameTextField, label: 'Kişi Adı'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _loading = true;
                  });
                  try {
                    await client.createRoom(
                      name: _roomNameTextField.text,
                      invite: [
                        '@${_roomNameTextField.text}:matrix.org',
                      ],
                      visibility: Visibility.private,
                      isDirect: true,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                      ),
                    );
                  } finally {
                    setState(() {
                      _loading = false;
                    });
                  }
                },
                child: _loading ? const CircularProgressIndicator() : const Text('Oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
