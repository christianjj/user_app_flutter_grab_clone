import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:users_app/assistant/assistant_methods.dart';
import 'package:users_app/assistant/geofire_assistant.dart';
import 'package:users_app/global/global.dart';
import 'package:users_app/main.dart';
import 'package:users_app/mainScreens/search_places_screen.dart';
import 'package:users_app/mainScreens/select_nearest_active_driver_screen.dart';
import 'package:users_app/models/active_nearby_driver.dart';
import 'package:users_app/models/direction_details_info.dart';
import 'package:users_app/widgets/my_drawer.dart';
import 'package:users_app/widgets/progress_dialog.dart';
import '../infoHandler/app_info.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Completer<GoogleMapController> _controllers =
      Completer<GoogleMapController>();

  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();

  double searchLocationContainerHeight = 220;

  Position? userCurrentPosition;
  var geoLocator = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingofMap = 0;

  List<LatLng> pLineCoordinatesList = [];
  Set<Polyline> polyLineSet = {};
  Set<Marker> markersSet = {};
  Set<Circle> circleSet = {};

  bool openNavigationDrawer = true;
  bool activeNearbyDriversKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;

  List<ActiveNearbyDrivers> onlineNearbyAvailableDriversList = [];

  DatabaseReference? referenceRideRequest;

  blackGoogleMapTheme() {
    newGoogleMapController!.setMapStyle('''
                    [
                      {
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "featureType": "administrative.locality",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#263c3f"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#6b9a76"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#38414e"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#212a37"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#9ca5b3"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#1f2835"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#f3d19c"
                          }
                        ]
                      },
                      {
                        "featureType": "transit",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#2f3948"
                          }
                        ]
                      },
                      {
                        "featureType": "transit.station",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#515c6d"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      }
                    ]
                ''');
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  locateUserPosition() async {
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = currentPosition;
    LatLng latLngPosition =
        LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);

    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    String humanReadableAddress =
        await AssistantMethods.searchAddressForGeographicCoordinates(
            userCurrentPosition!, context);
    print("this is your address = $humanReadableAddress");

    initializeGeofireListener();
  }

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  saveRideRequestInformation() {
    //save the ride request information

    referenceRideRequest =
        FirebaseDatabase.instance.ref().child("All Ride Request").push();

    var originLocation =
        Provider.of<AppInfo>(context, listen: false).userPickupLocation;
    var dropOffLocation =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map originLocationMap = {
      //"key": value
      "latitude": originLocation!.locationLatidtude.toString(),
      "longtitude": originLocation!.locationLongitude.toString(),
    };

    Map destinationLocationMap = {
      //"key": value
      "latitude": dropOffLocation!.locationLatidtude.toString(),
      "longtitude": dropOffLocation!.locationLongitude.toString(),
    };

    Map userInformationMap = {
      //"key": value
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time": DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name,
      "userPhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locationName,
      "destinationAddress": dropOffLocation.locationName,
      "driverId": "waiting",
    };

    referenceRideRequest!.set(userInformationMap);

    onlineNearbyAvailableDriversList = GeoFireAssistant.activeNearbyDriversList;

    searchNearestOnlineDrivers();
  }

  searchNearestOnlineDrivers() async {
    if (onlineNearbyAvailableDriversList.isEmpty) {
      //cancel/delete the RideRequest Information

      referenceRideRequest!.remove();
      setState(() {
        polyLineSet.clear();
        markersSet.clear();
        circleSet.clear();
        pLineCoordinatesList.clear();
      });
      Fluttertoast.showToast(msg: "No Online Nearest Driver Available");
      Fluttertoast.showToast(msg: "Restart the app ");
      Future.delayed(Duration(milliseconds: 4000), () {
        SystemNavigator.pop();
      });

      return;
    }

    await retrieveOnlineDriverInformation(onlineNearbyAvailableDriversList);
    var response = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => SelectNearestActiveDriverScreen(
                referenceRideRequest: referenceRideRequest)));

    if (response == "driverChoosed") {
      FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(chosenDriverId!)
          .once()
          .then((snapshot) {
        if (snapshot.snapshot.value != null) {
          sendNotificationToDriverNow(chosenDriverId!);
        } else {
          Fluttertoast.showToast(msg: "This Driver do not Exist, try again");
        }
      });
    }
  }

  sendNotificationToDriverNow(String chosenDriver) {
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(chosenDriver)
        .child("newRideStatus")
        .set(referenceRideRequest!.key);

    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(chosenDriver)
        .child("token")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        String deviceRegistrationToken = snap.snapshot.value.toString();
        AssistantMethods.sendNotificationToDriverNow(deviceRegistrationToken,
            referenceRideRequest!.key.toString(), context);

        Fluttertoast.showToast(msg: "Notification send Successfully.");
      } else {
        Fluttertoast.showToast(msg: "Please choose another driver");
        return;
      }
    });
  }

  retrieveOnlineDriverInformation(
      List<ActiveNearbyDrivers> onlineNearbyAvailableDriversList) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");
    for (int i = 0; i < onlineNearbyAvailableDriversList.length; i++) {
      await ref
          .child(onlineNearbyAvailableDriversList[i].driverId.toString())
          .once()
          .then((dataSnapshot) {
        var driverInfoKey = dataSnapshot.snapshot.value;
        dlist.add(driverInfoKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    createActiveNearByDriverIconMarker();

    return SafeArea(
      child: Scaffold(
        key: sKey,
        drawer: MyDrawer(
            name: userModelCurrentInfo?.name ?? "",
            email: userModelCurrentInfo?.email ?? ""),
        body: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: bottomPaddingofMap),
              initialCameraPosition: _kGooglePlex,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              myLocationEnabled: true,
              markers: markersSet,
              circles: circleSet,
              polylines: polyLineSet,
              onMapCreated: (GoogleMapController controller) {
                _controllers.complete(controller);
                newGoogleMapController = controller;
                blackGoogleMapTheme();
                setState(() {
                  bottomPaddingofMap = 265;
                });
                locateUserPosition();
              },
            ),
            Positioned(
              top: 20,
              left: 22,
              child: GestureDetector(
                onTap: () {
                  if (openNavigationDrawer) {
                    sKey.currentState?.openDrawer();
                  } else {
                    //restart- refresh - minimize programmatically
                    //SystemNavigator.pop();
                    setState(() {
                      polyLineSet.clear();
                      markersSet.clear();
                      circleSet.clear();
                      pLineCoordinatesList.clear();
                      locateUserPosition();
                    });
                  }
                },
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(openNavigationDrawer ? Icons.menu : Icons.close,
                      color: Colors.black54),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSize(
                curve: Curves.easeIn,
                duration: Duration(milliseconds: 120),
                child: Container(
                    height: searchLocationContainerHeight,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        topLeft: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.add_location_alt_outlined,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("From",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                  Text(
                                      Provider.of<AppInfo>(context)
                                                  .userPickupLocation !=
                                              null
                                          ? "${(Provider.of<AppInfo>(context).userPickupLocation!.locationName!).substring(0, 29)}..."
                                          : "not getting address",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14)),
                                ],
                              )
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            height: 16,
                          ),
                          GestureDetector(
                            onTap: () async {
                              var responseFromSearchScreen =
                                  await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (c) =>
                                              SearchPlacesScreen()));

                              if (responseFromSearchScreen ==
                                  "obtainedDropOff") {
                                //draw polyline
                                setState(() {
                                  openNavigationDrawer = false;
                                });
                                await drawPolyLineFromSourceToDestination();
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_location_alt_outlined,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("To",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                    Text(
                                        Provider.of<AppInfo>(context)
                                                    .userDropOffLocation !=
                                                null
                                            ? Provider.of<AppInfo>(context)
                                                .userDropOffLocation!
                                                .locationName!
                                            : "Where to go ",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14)),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (Provider.of<AppInfo>(context, listen: false)
                                      .userDropOffLocation !=
                                  null) {
                                saveRideRequestInformation();
                              } else {
                                Fluttertoast.showToast(
                                    msg: "Please select destination location");
                              }
                            },
                            child: Text("Request a ride",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                          )
                        ],
                      ),
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> drawPolyLineFromSourceToDestination() async {
    var sourcePosition =
        Provider.of<AppInfo>(context, listen: false).userPickupLocation;
    var destinationPosition =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatlng = LatLng(
        sourcePosition!.locationLatidtude!, sourcePosition.locationLongitude!);
    var destinationLatlng = LatLng(destinationPosition!.locationLatidtude!,
        destinationPosition.locationLongitude!);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: "Please wait...",
            ));
    var directionDetailsInfo =
        await AssistantMethods.obtainOriginToDestinationDirectionDetails(
            originLatlng, destinationLatlng);

    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
    });

    Navigator.pop(context);

    print("points = ");

    print(directionDetailsInfo?.e_points);

    pLineCoordinatesList.clear();

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPPointsResultList =
        polylinePoints.decodePolyline(directionDetailsInfo!.e_points!);

    if (decodedPPointsResultList.isNotEmpty) {
      decodedPPointsResultList.forEach((PointLatLng pointLatLng) {
        pLineCoordinatesList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });

      polyLineSet.clear();

      setState(() {
        Polyline polyline = Polyline(
          color: Colors.blue,
          polylineId: PolylineId("PolylineID"),
          jointType: JointType.round,
          points: pLineCoordinatesList,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        );
        polyLineSet.add(polyline);
      });

      LatLngBounds boundsLatLng;
      if (originLatlng.latitude > destinationLatlng.latitude &&
          originLatlng.longitude > destinationLatlng.longitude) {
        boundsLatLng =
            LatLngBounds(southwest: destinationLatlng, northeast: originLatlng);
      } else if (originLatlng.longitude > destinationLatlng.longitude) {
        boundsLatLng = LatLngBounds(
            southwest:
                LatLng(originLatlng.latitude, destinationLatlng.longitude),
            northeast:
                LatLng(destinationLatlng.latitude, originLatlng.longitude));
      } else if (originLatlng.latitude > destinationLatlng.latitude) {
        boundsLatLng = LatLngBounds(
            southwest:
                LatLng(destinationLatlng.latitude, originLatlng.longitude),
            northeast:
                LatLng(originLatlng.latitude, destinationLatlng.longitude));
      } else {
        boundsLatLng =
            LatLngBounds(southwest: originLatlng, northeast: destinationLatlng);
      }
      newGoogleMapController!
          .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));
      Marker originMarker = Marker(
        markerId: MarkerId("originID"),
        infoWindow: InfoWindow(
            title: destinationPosition.locationName, snippet: "Origin"),
        position: originLatlng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      );

      Marker destinationMarker = Marker(
        markerId: MarkerId("destinationID"),
        infoWindow: InfoWindow(
            title: destinationPosition.locationName, snippet: "Destination"),
        position: destinationLatlng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );

      setState(() {
        markersSet.add(originMarker);
        markersSet.add(destinationMarker);
      });

      Circle originCircle = Circle(
        circleId: CircleId("originID"),
        fillColor: Colors.green,
        radius: 12,
        strokeColor: Colors.white,
        strokeWidth: 3,
        center: originLatlng,
      );

      Circle destinationCircle = Circle(
        circleId: CircleId("destinationID"),
        fillColor: Colors.red,
        radius: 12,
        strokeColor: Colors.white,
        strokeWidth: 3,
        center: destinationLatlng,
      );

      setState(() {
        circleSet.add(originCircle);
        circleSet.add(destinationCircle);
      });
    }
  }

  initializeGeofireListener() {
    try {
      Geofire.initialize("activeDrivers");
      Geofire.queryAtLocation(
              userCurrentPosition!.latitude, userCurrentPosition!.longitude, 5)!
          .listen((map) {
        print(map);
        if (map != null) {
          var callBack = map['callBack'];

          //latitude will be retrieved from map['latitude']
          //longitude will be retrieved from map['longitude']

          switch (callBack) {
            case Geofire.onKeyEntered: //whenever any driver become active
              ActiveNearbyDrivers activeNearbyDriver = ActiveNearbyDrivers();
              activeNearbyDriver.locationLatitude = map['latitude'];
              activeNearbyDriver.locationLongitude = map['longitude'];
              activeNearbyDriver.driverId = map['key'];
              GeoFireAssistant.activeNearbyDriversList.add(activeNearbyDriver);
              if (activeNearbyDriversKeysLoaded == true) {
                displayActiveDriversOnUsersMap();
              }
              break;

            case Geofire.onKeyExited: //whenever any driver become offline
              GeoFireAssistant.deleteofflineDriverFromList(map['key']);
              displayActiveDriversOnUsersMap();
              break;

            //driver move
            case Geofire.onKeyMoved:
              // Update your key's location

              ActiveNearbyDrivers activeNearbyDriver = ActiveNearbyDrivers();
              activeNearbyDriver.locationLatitude = map['latitude'];
              activeNearbyDriver.locationLongitude = map['longitude'];
              activeNearbyDriver.driverId = map['key'];
              GeoFireAssistant.updateActiveNearbyDriverLocation(
                  activeNearbyDriver);
              displayActiveDriversOnUsersMap();

              break;
            //display online drivers
            case Geofire.onGeoQueryReady:
              // All Intial Data is loaded
              activeNearbyDriversKeysLoaded = true;
              displayActiveDriversOnUsersMap();
              break;
          }
        }

        setState(() {});
      });
    } catch (exeption) {
      print(exeption);
    }
  }

  displayActiveDriversOnUsersMap() {
    setState(() {
      markersSet.clear();
      circleSet.clear();
      Set<Marker> driversMarkerSet = Set<Marker>();
      for (ActiveNearbyDrivers eachDriver
          in GeoFireAssistant.activeNearbyDriversList) {
        LatLng eachDriverActivePosition =
            LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);
        Marker marker = Marker(
          markerId: MarkerId("driver" + eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );

        driversMarkerSet.add(marker);
      }
      setState(() {
        markersSet = driversMarkerSet;
      });
    });
  }

  createActiveNearByDriverIconMarker() {
    if (activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png")
          .then((value) {
        activeNearbyIcon = value;
      });
    }
  }
}
