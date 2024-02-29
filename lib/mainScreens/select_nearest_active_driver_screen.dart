import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import 'package:users_app/assistant/assistant_methods.dart';

import '../global/global.dart';

class SelectNearestActiveDriverScreen extends StatefulWidget {

  DatabaseReference? referenceRideRequest;

  SelectNearestActiveDriverScreen({this.referenceRideRequest});

  @override
  State<SelectNearestActiveDriverScreen> createState() =>
      SelectNearestActiveDriverScreenState();
}

class SelectNearestActiveDriverScreenState
    extends State<SelectNearestActiveDriverScreen> {
  String fareAmount = "";

  getFareAmountAccordingToVehicleType(int index) {
    if (tripDirectionDetailsInfo != null) {
      if (dlist[index]["carDetails"]["type"].toString() == "bike") {
        fareAmount = (AssistantMethods.calculateFareAmountOriginToDestanation(
                    tripDirectionDetailsInfo!) /
                2)
            .toString();
      }
      if (dlist[index]["carDetails"]["type"].toString() == "uber-x") {
        fareAmount = (AssistantMethods.calculateFareAmountOriginToDestanation(
                    tripDirectionDetailsInfo!) *
                2)
            .toString();
      }
      if (dlist[index]["carDetails"]["type"].toString() == "uber-go") {
        fareAmount = (AssistantMethods.calculateFareAmountOriginToDestanation(
                tripDirectionDetailsInfo!))
            .toString();
      }
    }
    return fareAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white54,
        title: Text(
          "Nearest Online Drivers",
          style: TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            //delete the ride request from database
            widget.referenceRideRequest!.remove();
            Fluttertoast.showToast(msg: "You have cancelled the ride request.");
            SystemNavigator.pop();
          },
        ),
      ),
      body: ListView.builder(
        itemCount: dlist.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: (){
              setState(() {
                chosenDriverId = dlist[index]["id"].toString();
              });
              Navigator.pop(context, "driverChoosed");
            },
            child: Card(
              color: Colors.grey,
              elevation: 3,
              shadowColor: Colors.green,
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                leading: Image.asset(
                  "images/${dlist[index]["carDetails"]["type"]}.png",
                  width: 70,
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(dlist[index]["name"],
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text(dlist[index]["carDetails"]["car_model"],
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                    SmoothStarRating(
                      rating: 3.5,
                      color: Colors.black,
                      borderColor: Colors.black,
                      allowHalfRating: true,
                      starCount: 5,
                      size: 15,
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "PHP" + getFareAmountAccordingToVehicleType(index),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white54),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      tripDirectionDetailsInfo?.duration_text?.toString() ?? "",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white54),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      tripDirectionDetailsInfo?.distance_text?.toString() ?? "",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
