import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class Message {
  Event? event;

  Message({this.event});

  Widget buildMessage(BuildContext context) {
    return Text(event?.content['body'].toString() ?? "No Event Found");
  }
}
