import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:users_app/assistant/request_assistant.dart';
import 'package:users_app/global/global.dart';
import 'package:users_app/infoHandler/app_info.dart';
import 'package:users_app/models/direction_details_info.dart';
import 'package:users_app/models/users_model.dart';

import '../global/map_key.dart';
import '../models/directions.dart';

import 'package:http/http.dart' as http;

class AssistantMethods {
  static Future<String> searchAddressForGeographicCoordinates(
      Position position, context) async {
    String apiUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";
    var response = await RequestAssistant.receiveRequest(apiUrl);

    if (response != "Error Occured, Failed. No Response") {
      humanReadableAddress = response["results"][0]["formatted_address"];

      Directions userPickupAddress = Directions();
      userPickupAddress.locationLongitude = position.longitude;
      userPickupAddress.locationLatidtude = position.latitude;
      userPickupAddress.locationName = humanReadableAddress;
      Provider.of<AppInfo>(context, listen: false)
          .updatePickUplocationAddress(userPickupAddress);
    }
    return humanReadableAddress;
  }

  static void readCurrentOnlineUserInfo() async {
    currentFirebaseUser = fAuth.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(currentFirebaseUser!.uid);

    userRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
        print("name = " + userModelCurrentInfo!.name.toString());
        print("email = " + userModelCurrentInfo!.email.toString());
        print("phone = " + userModelCurrentInfo!.phone.toString());
      }
    });
  }

  static Future<DirectionDetailsInfo?>
      obtainOriginToDestinationDirectionDetails(
          LatLng originPosition, LatLng destinationPosition) async {
    String urlOriginToDestinationDirectionDetails =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";
    print(urlOriginToDestinationDirectionDetails);
    var responseDirection = await RequestAssistant.receiveRequest(
        urlOriginToDestinationDirectionDetails);

    if (responseDirection == "Error Occured, Failed. No Response") {
      return null;
    } else {
      DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();

      directionDetailsInfo.e_points =
          responseDirection["routes"][0]["overview_polyline"]["points"];
      directionDetailsInfo.distance_text =
          responseDirection["routes"][0]["legs"][0]["distance"]["text"];
      directionDetailsInfo.distance_value =
          responseDirection["routes"][0]["legs"][0]["distance"]["value"];

      directionDetailsInfo.duration_text =
          responseDirection["routes"][0]["legs"][0]["duration"]["text"];
      directionDetailsInfo.duration_value =
          responseDirection["routes"][0]["legs"][0]["duration"]["value"];

      return directionDetailsInfo;
    }
  }

  static double calculateFareAmountOriginToDestanation(
      DirectionDetailsInfo directionDetailsInfo) {
    double timeTraveledFarePerMinute =
        (directionDetailsInfo.duration_value! / 60) * 0.1;
    double distanceTraveledFarePerKilometer =
        (directionDetailsInfo.duration_value! / 1000) * 0.1;
    double totalFareAmount =
        timeTraveledFarePerMinute + distanceTraveledFarePerKilometer;
    double localCurrencyFare = totalFareAmount * 56;

    return double.parse(localCurrencyFare.toStringAsFixed(0));

    //
  }

  static sendNotificationToDriverNow(
      String deviceRegistrationToken, String userRideRequestId, context) async {
      String destinationAddress = userDropOffAddress;



    Map<String, String> headerNotification = {
      'Content-Type': 'application/json',
      'Authorization': cloudMessagingServerToken
    };

    Map bodyNotification = {
      "body": "Destination Address: \n $destinationAddress.",
      "title": "New Trip Request"
    };
    Map dataMap = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "rideRequestId": userRideRequestId,
    };

    Map officialNotificationFormat = {
      "notification": bodyNotification,
      "data": dataMap,
      "priority": "high",
      "to": deviceRegistrationToken
    };

    var responseNotification = http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: headerNotification,
        body: jsonEncode(officialNotificationFormat),
    );
  }
}
