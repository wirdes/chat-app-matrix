import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissinWidget extends StatefulWidget {
  final Permission permission;
  const PermissinWidget({super.key, required this.permission});

  @override
  State<PermissinWidget> createState() => _PermissinWidgetState();
}

class _PermissinWidgetState extends State<PermissinWidget> {
  PermissionStatus? check;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    widget.permission.status.then((value) {
      if (value.isGranted) {
        setState(() {
          check = PermissionStatus.granted;
        });
      } else {
        setState(() {
          check = PermissionStatus.denied;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.permission.toString().split(".").last.toCapitalized()),
        const Spacer(),
        SizedBox(
          height: 50,
          child: loading
              ? const Center(child: SizedBox(height: 5, child: LinearProgressIndicator()))
              : check == PermissionStatus.denied || check == null
                  ? TextButton(
                      onPressed: () async {
                        setState(() => loading = true);
                        final req = await widget.permission.request();
                        setState(() {
                          loading = false;
                          check = req.isGranted
                              ? PermissionStatus.granted
                              : req.isPermanentlyDenied
                                  ? PermissionStatus.permanentlyDenied
                                  : PermissionStatus.denied;
                        });
                      },
                      child: const Text("İzin İste"),
                    )
                  : check == PermissionStatus.granted
                      ? const Icon(Icons.check, color: Colors.green)
                      : check == PermissionStatus.permanentlyDenied
                          ? TextButton(
                              onPressed: () async => openAppSettings(),
                              child: const Text("Ayarlar'a git"),
                            )
                          : const Icon(Icons.close, color: Colors.red),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String toCapitalized() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  String toTitleCase() {
    return split(" ").map((e) => e.toCapitalized()).join(" ");
  }
}
