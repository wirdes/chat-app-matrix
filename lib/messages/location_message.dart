import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:loser_night/messages/message.dart';

class LocationMessage extends Message {
  final double? latitude;
  final double? longitude;

  LocationMessage({this.latitude, this.longitude, super.event});

  @override
  Widget buildMessage(BuildContext context) {
    List<Widget> children = [
      TileLayer(
        urlTemplate: 'https://www.google.com/maps/vt/pb=!1m4!1m3!1i{z}!2i{x}!3i{y}!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425',
        userAgentPackageName: 'pinsar.com.tr',
      ),
      if (latitude != null && longitude != null)
        MarkerLayer(
          markers: [
            Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(latitude!, longitude!),
              child: const Icon(Icons.location_on, size: 36.0, color: Colors.red),
            ),
          ],
        ),
    ];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude!, longitude!),
                  initialZoom: 13.0,
                ),
                children: children,
              ),
            ),
          ),
        ));
      },
      child: SizedBox(
        width: 120,
        height: 80,
        child: AbsorbPointer(
          absorbing: true,
          child: FlutterMap(
            options: MapOptions(initialCenter: LatLng(latitude!, longitude!), initialZoom: 13.0),
            children: children,
          ),
        ),
      ),
    );
    // return InkWell(
    //     onTap: () {
    //       Navigator.of(context).push(MaterialPageRoute(
    //         builder: (context) => Scaffold(
    //           appBar: AppBar(),
    //           body: Center(
    //             child: FlutterMap(
    //               options: MapOptions(
    //                 initialCenter: LatLng(latitude!, longitude!),
    //                 initialZoom: 13.0,
    //               ),
    //               children: children,
    //             ),
    //           ),
    //         ),
    //       ));
    //     },
    //     child: SizedBox(
    //       width: 120,
    //       height: 80,
    //       child: FlutterMap(
    //         options: MapOptions(initialCenter: LatLng(latitude!, longitude!), initialZoom: 13.0, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
    //         children: children,
    //       ),
    //     ));
  }
}
