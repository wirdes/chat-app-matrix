import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:loser_night/components/circular_avatar.dart';
import 'package:loser_night/components/edit_room.dart';
import 'package:loser_night/components/input.dart';
import 'package:loser_night/components/reply_content_widget.dart';
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
  late final Future<Timeline> _timelineFuture;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final AutoScrollController scrollController = AutoScrollController();
  Event? replyEvent;
  bool _update = false;
  bool _attachmentMenu = false;
  String? _spotlight;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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
              CircularAvatarWidget.fromRoom(widget.room, radius: 20),
              const SizedBox(width: 8),
              Text(widget.room.getLocalizedDisplayname()),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder(
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
              return Column(
                children: [
                  Expanded(
                    child: AnimatedList(
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
                                          onTap: () => {
                                            print('tapped')
                                          },
                                          onLongPress: () => {},
                                          key: ValueKey(event.eventId),
                                          isSender: isMe,
                                          color: isMe ? Theme.of(context).secondaryHeaderColor : Colors.grey.shade200,
                                          image: Column(
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
                                              MessageWidget(event: event),
                                            ],
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
                    ),
                  ),
                  const Divider(height: 1),
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
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: TextField(
                                        focusNode: _focusNode,
                                        controller: _controller,
                                        decoration: const InputDecoration(
                                            hintText: 'Bir mesaj yazın',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(55)),
                                            )),
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
                  const SizedBox(
                    height: 8,
                  )
                ],
              );
            }),
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    if (MessageTypes.Text == event.messageType) {
      final text = event.relationshipType == RelationshipTypes.reply ? event.hiddenReplyText : event.getAttachmentUrl().toString();
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
