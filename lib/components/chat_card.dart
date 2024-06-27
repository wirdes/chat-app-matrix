import 'package:flutter/material.dart';
import 'package:loser_night/components/circular_avatar.dart';
import 'package:loser_night/screens/room.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:intl/intl.dart' as intl;
import 'package:matrix/matrix.dart' hide Visibility;

class ChatCard extends StatelessWidget {
  final Room room;
  final void Function()? onPress;
  final void Function()? onLongPress;
  const ChatCard({super.key, required this.room, this.onPress, this.onLongPress});
  static const double slidableSizeRatio = 0.23;
  static double slidableExtentRatio(int slidablesLength) {
    return slidableSizeRatio * slidablesLength;
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      groupTag: 'slidable_list',
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: ChatCard.slidableExtentRatio(2),
        children: [
          ChatCustomSlidableAction(
            icon: room.isFavourite ? const Icon(Icons.star) : const Icon(Icons.star_border),
            label: 'Favourite',
            onPressed: (context) {
              room.setFavourite(!room.isFavourite);
            },
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
          ChatCustomSlidableAction(
            icon: const Icon(Icons.delete),
            label: 'Delete',
            onPressed: (context) {
              room.leave();
            },
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
        ],
      ),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
                child: Text(
              room.getLocalizedDisplayname(),
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
            )),
            Text(
              room.lastEvent?.originServerTs.formatedLocale(context) ?? "",
              style: Theme.of(context).textTheme.bodySmall,
            )
          ],
        ),
        onTap: onPress,
        onLongPress: onLongPress,
        subtitle: Row(children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: room.lastEvent?.senderFromMemoryOrFallback.displayName ?? room.lastEvent?.senderFromMemoryOrFallback.senderId),
                          const TextSpan(text: ": "),
                          TextSpan(
                            text: room.lastEvent?.hiddenReplyText ?? "",
                            style: TextStyle(color: Theme.of(context).primaryColorDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Visibility(visible: room.membership == Membership.invite, child: const Icon(Icons.notification_important, size: 18)),
          Visibility(visible: room.isFavourite, child: const Padding(padding: EdgeInsets.only(left: 4.0), child: Icon(Icons.star, size: 18, color: Colors.amber))),
        ]),
        leading: CircularAvatarWidget.fromRoom(room),
      ),
    );
  }
}

class ChatCustomSlidableAction extends StatelessWidget {
  const ChatCustomSlidableAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Widget icon;
  final String label;
  final SlidableActionCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      autoClose: true,
      padding: const EdgeInsets.all(4.0),
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foregroundColor,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

extension FormatDateTime on DateTime {
  String formatedLocale(BuildContext context) {
    if (DateTime.now().millisecondsSinceEpoch - millisecondsSinceEpoch < Duration.millisecondsPerDay) {
      return intl.DateFormat.Hm().format(this);
    }
    return intl.DateFormat('dd/MM/yy', intl.Intl.defaultLocale).format(this);
  }
}
