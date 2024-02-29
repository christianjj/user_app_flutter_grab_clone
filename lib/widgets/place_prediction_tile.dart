import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:users_app/assistant/request_assistant.dart';
import 'package:users_app/global/global.dart';
import 'package:users_app/global/map_key.dart';
import 'package:users_app/models/predicted_places.dart';
import 'package:users_app/widgets/progress_dialog.dart';

import '../infoHandler/app_info.dart';
import '../models/directions.dart';


class PlacePredictionTileDesign extends StatefulWidget {


  final PredictedPlaces? predictedPlaces;


  PlacePredictionTileDesign({this.predictedPlaces});

  @override
  State<PlacePredictionTileDesign> createState() => _PlacePredictionTileDesignState();
}

class _PlacePredictionTileDesignState extends State<PlacePredictionTileDesign> {
  getPlaceDirectionDetails(String? placeId, context) async {
    showDialog(context: context,
        builder: (BuildContext context) =>
            ProgressDialog(message: "Setting up drop off, Please wait"));

    String placeDirectionDetails = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var responseApi = await RequestAssistant.receiveRequest(placeDirectionDetails);


    Navigator.pop(context);

    if(responseApi == "Error Occurred, Failed. No Response"){
      return;
    }
    else{
      if(responseApi["status"] == "OK"){
        Directions directions = Directions();
        directions.locationName = responseApi["result"]["name"];
        directions.locationLatidtude = responseApi["result"]["geometry"]["location"]["lat"];
        directions.locationLongitude = responseApi["result"]["geometry"]["location"]["lng"];
        directions.locationId = placeId;
        print("location name" + directions.locationName!);

        Provider.of<AppInfo>(context, listen: false).updateDropOfflocationAddress(directions);

        setState(() {
          userDropOffAddress = directions.locationName!;
        });

        Navigator.pop(context, "obtainedDropOff");

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: () {
      getPlaceDirectionDetails(widget.predictedPlaces?.place_id, context);
    }, style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white24, shape: RoundedRectangleBorder()),

        child: Row(children: [
          const Icon(Icons.add_location, color: Colors.grey),
          const SizedBox(width: 14.0,),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8.0,),
            Text(
                widget.predictedPlaces?.main_text ?? "no result",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.white54,
                )
            ),
            const SizedBox(height: 2.0,),

            Text(
                widget.predictedPlaces?.secondary_text ?? "",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.white54,
                )
            ),
            const SizedBox(height: 8.0)

          ],
          ))
        ],));
  }
}
