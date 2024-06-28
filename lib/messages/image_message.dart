import 'package:flutter/material.dart';
import 'package:loser_night/messages/message.dart';

class ImageMessage extends Message {
  final ImageProvider? imageProvider;

  ImageMessage({this.imageProvider, super.event});

  ImageProvider image({bool thumb = false}) => imageProvider ?? NetworkImage(event!.getAttachmentUrl(getThumbnail: thumb).toString());

  @override
  Widget buildMessage(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(event!.content['body'].toString()),
              backgroundColor: Colors.transparent,
            ),
            body: SizedBox(
              width: size.width,
              child: InteractiveViewer(
                child: Image(image: image()),
              ),
            ),
          ),
        ));
      },
      child: SizedBox(
        width: 120,
        height: 120,
        child: Image(image: image(thumb: true), fit: BoxFit.cover),
      ),
    );
  }
}
