import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loser_night/components/edit_room.dart';
import 'package:loser_night/components/reply_content_widget.dart';
import 'package:loser_night/components/settings/avatar.dart';
import 'package:loser_night/components/swipeable.dart';
import 'package:loser_night/managers/attachment_manager.dart';
import 'package:loser_night/messages/image_message.dart';
import 'package:loser_night/messages/location_message.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class RoomPage extends StatefulWidget {
  final Room room;
  const RoomPage({super.key, required this.room});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final AutoScrollController scrollController = AutoScrollController();
  Timeline? tm;
  late final Future<Timeline> _timelineFuture = widget.room.getTimeline(
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

  Event? replyEvent;
  bool _attachmentMenu = false;
  String? _spotlight;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void getTimeline() async {
    tm = await _timelineFuture;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getTimeline();
  }

  @override
  void dispose() {
    scrollController.dispose();

    super.dispose();
  }

  void _send(String s) {
    widget.room.sendTextEvent(s.trim(), inReplyTo: replyEvent);
    setState(() => replyEvent = null);
  }

  void onTapCloseReply() {
    setState(() => replyEvent = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EditRoomWidget(room: widget.room),
              ),
            );
          },
          child: Row(
            children: [
              Avatar.fromRoom(widget.room, radius: 40),
              const SizedBox(width: 8),
              Text(
                widget.room.getLocalizedDisplayname(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      body: Builder(builder: (context) {
        if (tm == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final timeline = tm!;
        return SafeArea(
            child: Column(
          children: [
            Expanded(
              child: AnimatedList(
                controller: scrollController,
                key: _listKey,
                reverse: true,
                initialItemCount: timeline.events.length + 1,
                itemBuilder: (context, i, animation) {
                  if (i == timeline.events.length) {
                    if (timeline.canRequestHistory) {
                      WidgetsBinding.instance.scheduleTask(() async {
                        await timeline.requestHistory();
                        setState(() {});
                      }, Priority.animation);
                      return const LinearProgressIndicator();
                    }
                    return const SizedBox.shrink();
                  }
                  List<Widget> children = [];
                  final event = timeline.events[i];

                  final isMe = event.senderFromMemoryOrFallback.senderId == widget.room.client.userID;
                  final tail = i == timeline.events.length - 1 || timeline.events[i + 1].senderFromMemoryOrFallback.senderId != event.senderFromMemoryOrFallback.senderId;
                  final newDay = i == timeline.events.length - 1 || timeline.events[i + 1].originServerTs.day != event.originServerTs.day;

                  if (newDay) {
                    children.add(
                      Material(
                        color: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(event.originServerTs.get(), style: TextStyle(color: Colors.grey.shade600)),
                        ),
                      ),
                    );
                  }
                  if (tail && !isMe && newDay) {
                    children.add(Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Avatar.fromUser(event.senderFromMemoryOrFallback, radius: 36),
                          const SizedBox(width: 8),
                          Text(event.senderFromMemoryOrFallback.displayName ?? event.senderFromMemoryOrFallback.senderId),
                        ],
                      ),
                    ));
                  }
                  if (event.type != 'm.room.message') {
                    return const SizedBox.shrink();
                  } else {
                    children.add(Swipeable(
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
                                child: MessagesWidget(
                                  event: event,
                                  isMe: isMe,
                                  tail: tail,
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
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ));
                  }

                  return Column(
                    children: children,
                  );
                },
              ),
            ),
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      if (_attachmentMenu)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _attachmentMenu ? 100 : 0,
                          child: Wrap(
                            children: [
                              AtacmentItem(
                                title: 'Medya',
                                icon: Icons.image,
                                onTap: () async {
                                  try {
                                    final img = await AttachmentManager().pickMedia(context);
                                    if (img != null) {
                                      await widget.room.sendFileEvent(img);
                                      _controller.clear();
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                  }
                                },
                              ),
                              AtacmentItem(
                                title: 'Konum',
                                icon: Icons.location_on,
                                onTap: () async {
                                  try {
                                    final locations = await AttachmentManager().pickLocation(context);
                                    if (locations != null) {
                                      final l = "${locations.latitude},${locations.longitude}";
                                      await widget.room.sendLocation(_controller.text, l);
                                      _controller.clear();
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                  }
                                },
                              ),
                              AtacmentItem(
                                title: 'Dosya',
                                icon: Icons.file_copy,
                                onTap: () async {
                                  await AttachmentManager().pickFile(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: replyEvent == null ? 0 : 50,
                          child: (replyEvent != null)
                              ? Stack(
                                  children: [
                                    ReplyContent(
                                      replyEvent!,
                                      timeline: timeline,
                                      ownMessage: replyEvent!.senderFromMemoryOrFallback.senderId == widget.room.client.userID,
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: -10,
                                      child: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: onTapCloseReply,
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink()),
                      SizedBox(
                        height: 64,
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                              onPressed: () {
                                setState(() {
                                  _attachmentMenu = !_attachmentMenu;
                                  _focusNode.unfocus();
                                });
                              },
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                                  child: TextField(
                                    focusNode: _focusNode,
                                    controller: _controller,
                                    decoration: const InputDecoration(
                                      hintText: 'Bir mesaj yazın',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                              onPressed: () {
                                _send(_controller.text);
                                _controller.clear();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_attachmentMenu)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _attachmentMenu = false;
                        });
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8)
          ],
        ));
      }),
    );
  }
}

class MessagesWidget extends StatelessWidget {
  final Event event;
  final bool isMe;
  final bool tail;
  final Timeline timeline;
  final void Function(String?) scrollToEventId;

  const MessagesWidget({
    super.key,
    required this.event,
    required this.isMe,
    required this.tail,
    required this.timeline,
    required this.scrollToEventId,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 248),
            child: Material(
              color: isMe ? Colors.amber.shade100 : Colors.grey.shade200,
              elevation: 2,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMe ? 16 : 0),
                topRight: Radius.circular(isMe ? 0 : 16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (event.relationshipType == RelationshipTypes.reply)
                    ReplyContentWidget(
                      event: event,
                      timeline: timeline,
                      scrollToEventId: scrollToEventId,
                      ownMessage: isMe,
                    ),
                  Builder(builder: (context) {
                    if (MessageTypes.Text == event.messageType) {
                      final text = event.relationshipType == RelationshipTypes.reply ? event.hiddenReplyText : event.text;
                      return Padding(
                        padding: event.relationshipType != RelationshipTypes.reply ? const EdgeInsets.symmetric(horizontal: 16) : EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(text, textAlign: TextAlign.left),
                        ),
                      );
                    } else if (MessageTypes.Image == event.messageType) {
                      return ImageMessage(event: event).buildMessage(context);
                    } else if (MessageTypes.Location == event.messageType) {
                      final lat = double.tryParse(event.content['geo_uri'].toString().split(',')[0]);
                      final lon = double.tryParse(event.content['geo_uri'].toString().split(',')[1]);

                      return LocationMessage(event: event, latitude: lat, longitude: lon).buildMessage(context);
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension A on Event {
  String get hiddenReplyText => text.replaceFirst(RegExp(r'^>( \*)? <[^>]+>[^\n\r]+\r?\n(> [^\n]*\r?\n)*\r?\n'), '');
}

class AtacmentItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final void Function() onTap;
  const AtacmentItem({super.key, required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hashColor = Colors.primaries[title.hashCode % Colors.primaries.length].value;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Color(hashColor),
              radius: 24,
              child: Icon(icon, color: Colors.white),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

extension FormatDate on DateTime {
  String get() {
    DateFormat formatter = DateFormat('d MMMM y', 'tr_TR');
    return formatter.format(this);
  }
}
