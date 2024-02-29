import 'package:flutter/material.dart';

import '../models/directions.dart';

class AppInfo extends ChangeNotifier{
    Directions? userPickupLocation, userDropOffLocation;


    void updatePickUplocationAddress(Directions userPickupAddress){
      userPickupLocation = userPickupAddress;
      notifyListeners();

    }


    void updateDropOfflocationAddress(Directions dropOffAddress){
      userDropOffLocation = dropOffAddress;
      notifyListeners();

    }

}