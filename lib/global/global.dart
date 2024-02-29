import 'package:firebase_auth/firebase_auth.dart';
import 'package:users_app/models/users_model.dart';

import '../models/direction_details_info.dart';

final FirebaseAuth fAuth = FirebaseAuth.instance;

User? currentFirebaseUser;

UserModel? userModelCurrentInfo;

List dlist = []; //online driversKey info List

DirectionDetailsInfo? tripDirectionDetailsInfo;

String? chosenDriverId = "";

String cloudMessagingServerToken = "key=AAAAvRYrfMc:APA91bFJZ8RBIUPkVzVBeQ5RTs0dOb60dEh4rGwYbAGIBpX5iM5IVL2aP3oIyR5sm9tjPUwRIEPR3J3bhdVORLP7jj74VleHh7sEJVDHOmk9FPAd_H5sGTobY5Imqce06rWUAsD-7yLd";

String userDropOffAddress = "";