import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class CircularAvatarWidget extends StatelessWidget {
  final Uri? url;
  final String displayName;
  final double radius;
  const CircularAvatarWidget({
    super.key,
    this.url,
    this.radius = 24,
    required this.displayName,
  });

  factory CircularAvatarWidget.fromUser(
    User user, {
    double radius = 24,
  }) =>
      CircularAvatarWidget(
        url: user.avatarUrl,
        displayName: user.displayName ?? user.id,
        radius: radius,
      );
  factory CircularAvatarWidget.fromRoom(
    Room room, {
    double radius = 24,
  }) =>
      CircularAvatarWidget(
        url: room.avatar,
        displayName: room.getLocalizedDisplayname(),
        radius: radius,
      );

  @override
  Widget build(BuildContext context) {
    final color = Colors.primaries[displayName.hashCode % Colors.primaries.length];
    return CircleAvatar(
      backgroundColor: color,
      radius: radius,
      foregroundImage: url == null ? null : Image.network('https://matrix.org/_matrix/media/r0/download/${url!.host}${url!.path}').image,
      child: Text(url != null ? "" : displayName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius / 1.5,
          )),
    );
  }
}
