import '../models/active_nearby_driver.dart';

class GeoFireAssistant{
  static List<ActiveNearbyDrivers> activeNearbyDriversList = [];
  static deleteofflineDriverFromList(String driverId){
    int indexNumber = activeNearbyDriversList.indexWhere((element) => element.driverId == driverId);

    activeNearbyDriversList.removeAt(indexNumber);

  }

  static void updateActiveNearbyDriverLocation(ActiveNearbyDrivers driverWhoMove){
    int indexNumber = activeNearbyDriversList.indexWhere((element) => element.driverId == driverWhoMove.driverId);
    activeNearbyDriversList[indexNumber].locationLongitude = driverWhoMove.locationLongitude;
    activeNearbyDriversList[indexNumber].locationLatitude = driverWhoMove.locationLatitude;
  }
}