import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../global/map_key.dart';

class RequestAssistant{


  static Future<dynamic> receiveRequest(String url) async{
    http.Response httpResponse = await http.get(Uri.parse(url));
    try {
      if (httpResponse.statusCode == 200) {
        String resData = httpResponse.body;

        var decodeResponseData = jsonDecode(resData);

        return decodeResponseData;
      }

      else {
        return "Error Occured, Failed. No Response";
      }
    }catch(exp){
      return "Error Occured, Failed. No Response";
    }
  }
}