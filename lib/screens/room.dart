import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loser_night/components/reply_content_widget.dart';
import 'package:loser_night/components/swipeable.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class RoomPage extends StatefulWidget {
  final Room room;
  const RoomPage({super.key, required this.room});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  late final Future<Timeline> _timelineFuture;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final AutoScrollController scrollController = AutoScrollController();
  Event? replyEvent;
  bool _update = false;
  String? _spotlight;
  late final Timeline timeline;

  @override
  void initState() {
    super.initState();
    _timelineFuture = widget.room.getTimeline(
        onChange: (i) {
          _listKey.currentState?.setState(() {});
        },
        onInsert: (i) {
          _listKey.currentState?.insertItem(i);
        },
        onRemove: (i) {
          _listKey.currentState?.removeItem(i, (_, __) => const ListTile());
        },
        onUpdate: () {});
    scrollController.addListener(() {
      if (scrollController.offset == scrollController.position.maxScrollExtent) {
        setState(() {
          _update = true;
        });
      } else {
        setState(() {
          _update = false;
        });
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _send(String s) {
    widget.room.sendTextEvent(s.trim(), inReplyTo: replyEvent);
    setState(() {
      replyEvent = null;
    });
  }

  void onTapCloseReply() {
    setState(() {
      replyEvent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.getLocalizedDisplayname()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<Timeline>(
                future: _timelineFuture,
                builder: (context, snapshot) {
                  final timeline = snapshot.data;
                  if (timeline == null) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  widget.room.setReadMarker(timeline.events.last.eventId);
                  if (_update) {
                    timeline.requestHistory();
                  }
                  return AnimatedList(
                    controller: scrollController,
                    key: _listKey,
                    reverse: true,
                    initialItemCount: timeline.events.length,
                    itemBuilder: (context, i, animation) {
                      final event = timeline.events[i];

                      final isMe = event.senderFromMemoryOrFallback.senderId == widget.room.client.userID;
                      final tail = i == timeline.events.length - 1 || timeline.events[i + 1].senderFromMemoryOrFallback.senderId != event.senderFromMemoryOrFallback.senderId;
                      final newDay = i == timeline.events.length - 1 || timeline.events[i + 1].originServerTs.day != event.originServerTs.day;
                      if (newDay) {
                        return DateChip(date: event.originServerTs);
                      } else {
                        if (event.type != 'm.room.message') {
                          return const SizedBox.shrink();
                        } else {
                          final text = event.relationshipType == RelationshipTypes.reply ? event.hiddenReplyText : event.text;
                          return Swipeable(
                            key: ValueKey(event.eventId),
                            onSwipe: (w) {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                replyEvent = event;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                              child: Material(
                                color: _spotlight == event.eventId ? Colors.yellow.shade200 : Colors.transparent,
                                child: AutoScrollTag(
                                  key: ValueKey(event.eventId),
                                  controller: scrollController,
                                  index: i,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: Opacity(
                                      opacity: timeline.events[i].status.isSent ? 1 : 0.5,
                                      child: BubbleNormalImage(
                                        onTap: () => {},
                                        onLongPress: () => {},
                                        key: ValueKey(event.eventId),
                                        isSender: isMe,
                                        color: isMe ? Theme.of(context).secondaryHeaderColor : Colors.grey.shade200,
                                        image: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (event.relationshipType == RelationshipTypes.reply)
                                                ReplyContentWidget(
                                                  event: event,
                                                  timeline: timeline,
                                                  scrollToEventId: (id) async {
                                                    final index = timeline.events.indexWhere((element) => element.eventId == id);
                                                    if (index != -1) {
                                                      await scrollController.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
                                                      setState(() {
                                                        _spotlight = id;
                                                      });
                                                      Future.delayed(const Duration(seconds: 2), () {
                                                        setState(() {
                                                          _spotlight = null;
                                                        });
                                                      });
                                                    }
                                                  },
                                                  ownMessage: event.senderFromMemoryOrFallback.senderId == widget.room.client.userID,
                                                ),
                                              Padding(
                                                padding: event.relationshipType != RelationshipTypes.reply ? const EdgeInsets.symmetric(horizontal: 16) : EdgeInsets.zero,
                                                child: Text(text, textAlign: TextAlign.left),
                                              ),
                                            ],
                                          ),
                                        ),
                                        tail: tail,
                                        sent: true,
                                        delivered: true,
                                        id: event.eventId,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            MessageBar(
              messageBarHintText: 'Bir mesaj yazın',
              sendButtonColor: Theme.of(context).colorScheme.primary,
              messageBarColor: Theme.of(context).colorScheme.surface,
              onSend: _send,
              replying: replyEvent != null,
              onTapCloseReply: onTapCloseReply,
              replyIconColor: Theme.of(context).colorScheme.primary,
              replyCloseColor: Theme.of(context).colorScheme.primary,
              replyingTo: replyEvent?.relationshipType == RelationshipTypes.reply ? replyEvent!.hiddenReplyText : (replyEvent?.text ?? ''),
              actions: [
                InkWell(
                  child: const Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 24,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension A on Event {
  String get hiddenReplyText => text.replaceFirst(RegExp(r'^>( \*)? <[^>]+>[^\n\r]+\r?\n(> [^\n]*\r?\n)*\r?\n'), '');
}
