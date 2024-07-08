import 'package:flutter/material.dart';
import 'package:loser_night/components/chat/input.dart';
import 'package:loser_night/screens/room_list.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameTextField = TextEditingController();
  final TextEditingController _passwordTextField = TextEditingController();

  bool _loading = false;

  void _register() async {
    setState(() {
      _loading = true;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);
      await client.checkHomeserver(Uri.https('matrix.org', ''));
      await client.register(
        username: _usernameTextField.text,
        password: _passwordTextField.text,
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoomListPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Column(
        children: [
          Input(controller: _usernameTextField, label: 'Kullanıcı Adı', disabled: _loading),
          const SizedBox(height: 16),
          Input(controller: _passwordTextField, label: 'Şifre', disabled: _loading, obscureText: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: const Text('Kayıt Ol'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
