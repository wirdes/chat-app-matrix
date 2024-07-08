import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/avatar/round_avatar.dart';
import 'package:matrix/matrix.dart';

class Avatar extends StatelessWidget {
  final Uri? url;
  final String? name;
  final double size;
  final void Function()? onTap;

  const Avatar({this.url, this.name, this.size = AvatarStyle.defaultSize, this.onTap, super.key});

  factory Avatar.fromData(String url, String displayName, {double radius = AvatarStyle.defaultSize}) {
    return Avatar(
      url: Uri.parse(url),
      name: displayName,
      size: radius,
    );
  }
  factory Avatar.fromUser(User user, {double radius = AvatarStyle.defaultSize}) {
    return Avatar(
      url: user.avatarUrl,
      name: user.displayName ?? user.id,
      size: radius,
    );
  }
  factory Avatar.fromRoom(Room room, {double radius = AvatarStyle.defaultSize}) {
    return Avatar(
      url: room.avatar,
      name: room.getLocalizedDisplayname(),
      size: radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = url != null ? NetworkImage('https://matrix.org/_matrix/media/r0/download/${url!.host}${url!.path}') : null;
    final fallbackLetters = name?.getShortcutNameForAvatar() ?? '@';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: RoundAvatar(
            size: size,
            text: fallbackLetters,
            imageProvider: imageProvider,
            textStyle: TextStyle(
              fontSize: size / 2,
              color: AvatarStyle.defaultTextColor(_havePicture),
              fontFamily: AvatarStyle.fontFamily,
              fontWeight: AvatarStyle.fontWeight,
            ),
          )),
    );
  }

  bool get _havePicture {
    return url == null || url.toString().isEmpty || url.toString() == 'null';
  }
}

class AvatarStyle {
  static const double defaultSize = 56.0;
  static const defaultBorderRadius = BorderRadius.all(Radius.circular(28.0));

  static Color? defaultTextColor(bool noPic) {
    return noPic ? Colors.white : null;
  }

  static const String fontFamily = 'SFProRounded';
  static const FontWeight fontWeight = FontWeight.w700;

  static BorderRadius borderRadius(double? size) {
    return BorderRadius.circular((size ?? 56) / 2);
  }

  static BoxBorder defaultBorder = Border.all(color: Colors.transparent);
}

extension StringExtension on String {
  String toCapitalized() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  String toTitleCase() {
    return split(" ").map((e) => e.toCapitalized()).join(" ");
  }

  String getShortcutNameForAvatar() {
    final words = trim().split(RegExp('\\s+'));

    if (words.isEmpty || words[0] == '') {
      return '@';
    }

    final first = words[0];
    final last = words.length > 1 ? words[1] : '';
    final codeUnits = StringBuffer();

    if (first.isNotEmpty) {
      codeUnits.writeCharCode(first.runes.first);
    }

    if (last.isNotEmpty) {
      codeUnits.writeCharCode(last.runes.first);
    }

    return codeUnits.toString().toUpperCase();
  }
}
