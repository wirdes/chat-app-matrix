import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map_location_picker/flutter_map_location_picker.dart';
import 'package:loser_night/components/permission_widget.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';

class AttachmentManager {
  static final AttachmentManager _instance = AttachmentManager._internal();
  AttachmentManager._internal();
  factory AttachmentManager() => _instance;
  final ImagePicker picker = ImagePicker();

  Future<MatrixFile?> pickMedia(BuildContext context) async {
    if ((await Permission.mediaLibrary.status).isDenied) {
      await permissionModal(context, [
        Permission.mediaLibrary
      ]);
    }
    if (!((await Permission.mediaLibrary.status).isGranted)) {
      return null;
    }

    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;
    final byte = await pickedFile.readAsBytes();
    final fileType = pickedFile.path.split('.').last;
    return MatrixFile(
      bytes: byte,
      name: "LoserNight${DateTime.now().microsecondsSinceEpoch}.$fileType",
    );
  }

  Future<XFile?> takePhoto() async {
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
    return pickedFile;
  }

  Future<XFile?> pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return null;
    return result.files.isNotEmpty ? result.files.first.xFile : null;
  }

  Future<void> permissionModal(BuildContext context, List<Permission> permission) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var p in permission) PermissinWidget(permission: p),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Kapat"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<LocationResult?> pickLocation(BuildContext context) async {
    if ((await Permission.location.status).isDenied) {
      await permissionModal(context, [
        Permission.location
      ]);
    }

    if (!((await Permission.location.status).isGranted)) {
      return null;
    }

    final p = await showModalBottomSheet(
        clipBehavior: Clip.hardEdge,
        showDragHandle: true,
        context: context,
        builder: (context) => MapLocationPicker(
            initialLatitude: null,
            initialLongitude: null,
            zoomButtonEnabled: false,
            searchBarEnabled: false,
            switchMapTypeEnabled: false,
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            buttonText: 'Konum Seç',
            onPicked: (result) {
              Navigator.of(context).pop(result);
            }));

    return p;
  }
}
