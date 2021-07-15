import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'main.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

late String Grpid;
late double _userlat;
late double _userlong;

class GroupMap extends StatelessWidget {
  late String _title;

  GroupMap(
      {required String grpid,
      required String Title,
      required double userlat,
      required double userlong}) {
    Grpid = grpid;
    _title = Title;
    _userlat = userlat;
    _userlong = userlong;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        body: FireMap(),
      ),
    );
  }
}

class FireMap extends StatefulWidget {
  const FireMap({Key? key}) : super(key: key);

  @override
  _FireMapState createState() => _FireMapState();
}

class _FireMapState extends State<FireMap> {
  Set<Marker> markers = new Set<Marker>();

  // variables for slider widget
  double _value = 1.0;
  String _label = 'Adjust Radius';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _uid = _auth.currentUser!.uid.toString();
  // for retrieving location data
  CollectionReference collectionReference =
      FirebaseFirestore.instance.collection('groups');
  BehaviorSubject<double> radius = BehaviorSubject();
  late Stream<List<DocumentSnapshot>> stream;

  // will store logged in user's current location
  Location location = new Location();
  late String _GrpId;
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    _GrpId = Grpid;

    GeoFirePoint center =
        Geoflutterfire().point(latitude: _userlat, longitude: _userlong);
    stream = radius.switchMap((rad) {
      return Geoflutterfire()
          .collection(
              collectionRef:
                  collectionReference.doc(Grpid).collection('locations'))
          .within(
              center: center, radius: rad, field: 'position', strictMode: true);
    });

    //_initializemarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        GoogleMap(
          markers: markers,
          compassEnabled: true,
          initialCameraPosition:
              CameraPosition(target: LatLng(24.150, -110.32), zoom: 10),
          onMapCreated: _onMapCreated,
          myLocationEnabled:
              true, // Add little blue dot for device location, requires permission from user
        ),
        Container(
          height: 130.0,
          width: 160.0,
          child: Slider(
            min: 1,
            max: 1000,
            divisions: 200,
            activeColor: Colors.deepPurpleAccent,
            inactiveColor: Colors.deepPurple.withOpacity(0.5),
            value: _value,
            label: _label,
            onChanged: (double value) => changed(value),
          ),
        ),
      ],
    );
  }

  changed(value) {
    setState(() {
      _value = value;
      _label = '${_value.toInt().toString()} kms';
      markers.clear();
      radius.add(value);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    print('onMapCreated called');
    // listen to the change in location of current user
    location.onLocationChanged.listen((event) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(event.latitude!, event.longitude!),
            zoom: 16.0,
          ),
        ),
      );
      GeoFirePoint myLocation = Geoflutterfire()
          .point(latitude: event.latitude!, longitude: event.longitude!);
      updateDB(myLocation);
    });
    setState(() {
      mapController = controller;
    });
    stream.listen((List<DocumentSnapshot> documentList) {
      markers.clear();
      _updateMarkers(documentList);
    });
  }

  _updateMarkers(List<DocumentSnapshot> documentList) {
    print('updating markers');
    documentList.forEach((DocumentSnapshot document) {
      final GeoPoint point = document['position']['geopoint'];
      _addMarker(point.latitude, point.longitude, document['name']);
    });
  }

  _addMarker(double lat, double long, String name) {
    print('adding marker $name');
    markers.add(Marker(
        markerId: MarkerId(name),
        position: LatLng(lat, long),
        infoWindow: InfoWindow(
          title: name,
          snippet: 'Latitude: $lat , longitude: $long',
        )));
  }

  updateDB(GeoFirePoint myLocation) {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(_GrpId)
        .collection('Location')
        .doc(_uid)
        .set({
      'name': _auth.currentUser!.displayName.toString(),
      'position': myLocation.data,
    });
  }
}
