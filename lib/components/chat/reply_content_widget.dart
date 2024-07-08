import 'package:flutter/material.dart';
import 'package:loser_night/config/reply_content_style.dart';
import 'package:loser_night/screens/room.dart';
import 'package:matrix/matrix.dart';

class ReplyContentWidget extends StatelessWidget {
  const ReplyContentWidget({
    super.key,
    required this.event,
    required this.timeline,
    required this.scrollToEventId,
    required this.ownMessage,
  });

  final Event event;
  final Timeline timeline;
  final void Function(String p1)? scrollToEventId;
  final bool ownMessage;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event?>(
      future: event.getReplyEvent(timeline),
      builder: (BuildContext context, snapshot) {
        final replyEvent = snapshot.data ??
            Event(
              eventId: event.relationshipEventId!,
              content: {
                'msgtype': 'm.text',
                'body': '...',
              },
              senderId: event.senderId,
              type: 'm.room.message',
              room: event.room,
              status: EventStatus.sent,
              originServerTs: DateTime.now(),
            );
        return InkWell(
          onTap: () {
            if (scrollToEventId != null) {
              scrollToEventId!(
                replyEvent.eventId,
              );
            }
          },
          child: AbsorbPointer(
            child: Container(
              margin: const EdgeInsetsDirectional.symmetric(
                vertical: 4.0,
              ),
              child: ReplyContent(
                replyEvent,
                ownMessage: ownMessage,
                timeline: timeline,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ReplyContent extends StatelessWidget {
  final Event replyEvent;
  final bool ownMessage;
  final Timeline? timeline;

  const ReplyContent(
    this.replyEvent, {
    this.ownMessage = false,
    super.key,
    this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    Widget replyBody;
    final timeline = this.timeline;
    final displayEvent = timeline != null ? replyEvent.getDisplayEvent(timeline) : replyEvent;

    final user = displayEvent.room.getParticipants().where((user) => user.id == displayEvent.senderId).isNotEmpty ? displayEvent.room.getParticipants().firstWhere((user) => user.id == displayEvent.senderId) : null;
    replyBody = Text(
      displayEvent.hiddenReplyText,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: ReplyContentStyle.replyBodyTextStyle(context),
    );
    return Container(
      padding: ReplyContentStyle.replyParentContainerPadding,
      decoration: ReplyContentStyle.replyParentContainerDecoration(context, ownMessage),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: ReplyContentStyle.prefixBarVerticalPadding,
              ),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: ReplyContentStyle.replyContentSize,
                ),
                width: ReplyContentStyle.prefixBarWidth,
                decoration: ReplyContentStyle.prefixBarDecoration(context),
              ),
            ),
            const SizedBox(width: ReplyContentStyle.contentSpacing),
            const SizedBox(
              width: ReplyContentStyle.contentSpacing,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (user != null)
                    Text(
                      user.calcDisplayname(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ReplyContentStyle.displayNameTextStyle(context),
                    ),
                  if (displayEvent.room.getParticipants().where((user) => user.id == displayEvent.senderId).isEmpty)
                    FutureBuilder<User?>(
                      future: displayEvent.fetchSenderUser(),
                      builder: (context, snapshot) {
                        return Text(
                          '${snapshot.data?.calcDisplayname() ?? displayEvent.senderFromMemoryOrFallback.calcDisplayname()}:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ReplyContentStyle.displayNameTextStyle(context),
                        );
                      },
                    ),
                  Expanded(child: replyBody),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
