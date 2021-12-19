import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() => runApp(SpeechSampleApp());

class SpeechSampleApp extends StatefulWidget {
  @override
  _SpeechSampleAppState createState() => _SpeechSampleAppState();
}

/// An example that demonstrates the basic functionality of the
/// SpeechToText plugin for using the speech recognition capability
/// of the underlying platform.
class _SpeechSampleAppState extends State<SpeechSampleApp> {
  bool _hasSpeech = false;
  bool _logEvents = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  String? meaningUrl;

  String? exampleUrl;

  String? imageUrl;

  bool isLoading =false;

  bool imageNotFound=false;

  @override
  void initState() {
    super.initState();
    _handlePermission();
    initSpeechState();
  }

  Future<void> initSpeechState() async {
    _logEvent('Initialize');
    try{
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: true,
      );
      if (hasSpeech) {

        _localeNames = await speech.locales();

        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }

      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    }catch(e){
      print("exception is $e");
    }

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('One Page Dictionary'),
        ),
        body: isLoading==false?Container(
          margin: EdgeInsets.only(bottom: 50, right:20, left: 20, top: 20 ),
          child:
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[

                  Container(
                    alignment: Alignment.center,
                    child: lastWords==''?Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Press the button to start",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black),),
                        Text("speaking",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black),),
                      ],
                    ):
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Your Word:",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black),),
                        Text("${lastWords}",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black),),
                      ],
                    ),
                  ),

                ],
              ),
            ),

                meaningUrl!=null?Container(
                  padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: Border.all(width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Meaning",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black),),
                  Text("${meaningUrl}",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black),)

                ],
              ),
            ):
            Container(),

                exampleUrl!=null?Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    border: Border.all(width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Example",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black),),
                      Text("${exampleUrl}",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black),)

                    ],
                  ),
                ):
                Container(),

                imageUrl!=null?Container(

                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    border: Border.all(width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Image",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black),),
                      Image.network(imageUrl!, width: 150, height: 300,),
                    ],
                  ),
                ):
                Container(),

                imageNotFound==false?Container():
                Container(

                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    border: Border.all(width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Image",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black),),
                      Image.asset("asset/image_not_found.png", width: 150, height: 300,),
                    ],
                  ),
                ),


                IconButton(onPressed: (){

                  Fluttertoast.showToast(msg: "Speak",fontSize: 15,
                      gravity:ToastGravity.CENTER,
                      toastLength: Toast.LENGTH_LONG,
                  backgroundColor: Colors.blue,
                  timeInSecForIosWeb: 1);

                  startListening();

                }, icon: Icon(Icons.mic, size: 55,color: Colors.blue,))

          ],
          ),
        ):Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 4,
            backgroundColor: Colors.black,
          ),
        ),
      ),
    );
  }

  void startListening() {
    _logEvent('start listening');


    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 5),
        partialResults: true,
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        listenMode: ListenMode.confirmation);
    setState(() {});
  }




  //todo lastwords important
  void resultListener(SpeechRecognitionResult result) {


    setState(() {
      lastWords = '${result.recognizedWords}';
      print("lastWords is $lastWords");
      isLoading=true;
    });
    _getresults("https://owlbot.info/api/v4/dictionary/$lastWords");

  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // _logEvent('sound level $level: $minSoundLevel - $maxSoundLevel ');
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent(
        'Received error status: $error, listening: ${speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    _logEvent(
        'Received listener status: $status, listening: ${speech.isListening}');
    setState(() {
      lastStatus = '$status';
    });
  }

  void _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    print(selectedVal);
  }

  void _logEvent(String eventDescription) {
    if (_logEvents) {
      var eventTime = DateTime.now().toIso8601String();
      print('$eventTime $eventDescription');
    }
  }

  void _switchLogging(bool? val) {
    setState(() {
      _logEvents = val ?? false;
    });
  }

  Future<void> _handlePermission() async{

    var status = await Permission.bluetooth.request();
    if (status.isDenied) {

    }

  }


  Future<dynamic> _getresults(String url) async {

    print('My Get_ _getresults url = $url');

    Map<String, String> headers = {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Token d18fd864b31e95c1ee2bd48d7badb3b8d4144492"
    };
   

    var Url = Uri.parse(url);
    var response = await http.get(Url,headers: headers);
    int statusCode=response.statusCode;
      print('My Get _getresults response statusCode =$statusCode');
      if (statusCode == 401) {
        setState(() {
          isLoading = false;
        });
      } else if (statusCode < 200 || statusCode > 400 || json == null) {
        setState(() {
          isLoading = false;
        });
        throw new Exception("Error while fetching data");


      } else if (statusCode == 200) {

        try{
          if (response.body.isNotEmpty) {
            var obj = json.decode(response.body);
            var obj2=json.decode(json.encode(obj['definitions']));
            print('obj2 is ${obj2}');

            meaningUrl=obj2[0]['definition'];
            exampleUrl=obj2[0]['example'];
            imageUrl=obj2[0]['image_url'];

            if(imageUrl==null){
              imageUrl=null;
              imageNotFound=true;
            }else{
              imageNotFound=false;
            }

            setState(() {
              isLoading = false;
            });
          }
          else {
            setState(() {
              isLoading = false;
            });


          }
        }catch(e){
          print("Exception is $e");
          setState(() {
            isLoading = false;
          });
        }

      }
      return response;
    }






  }






