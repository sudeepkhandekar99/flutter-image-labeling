import 'dart:typed_data';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mlkitimagelabelinglivefeed/ScannerUtils.dart';



List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyHomePage(
    title: "App",
  ));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage img;
  CameraController controller;
  bool isBusy = false;
  String result = "";
  ImageLabeler labeler;

  @override
  void initState() {
    super.initState();
    //initializeCamera();
  }
  initializeCamera () async
  {
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    labeler = FirebaseVision.instance.imageLabeler(ImageLabelerOptions(confidenceThreshold: 0.20));
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

        controller.startImageStream((image) => {
          if (!isBusy)
            {
              isBusy = true,
              img = image,
              doImageLabeling()
              // loadFilesOD4()
            }
        });

    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }



  doImageLabeling() async{

    ScannerUtils.detect(
      image: img,
      detectInImage: labeler.processImage,
      imageRotation: null,
    ).then(
          (dynamic results) {
            result = "";
            if(results is List<ImageLabel>){
              List<ImageLabel> labels = results;
              setState(() {
                for(ImageLabel label in labels){
                  result += label.text+" : "+(label.confidence as double).toStringAsFixed(2)+"\n";
                }
              });
            }

      },
    ).whenComplete(() => isBusy = false);
  }
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('images/img2.jpg'), fit: BoxFit.fill),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Center(
                      child: Container(
                          margin: EdgeInsets.only(top: 100),
                          height: 220,
                          width: 320,
                          child: Image.asset('images/lcd2.jpg')),
                    ),
                    Center(
                      child: FlatButton(
                        child: Container(
                          margin: EdgeInsets.only(top: 118),
                          height: 177,
                          width: 310,
                          child: img == null?Container(
                            width: 140,
                            height: 150,
                            child: Icon(
                              Icons.videocam,
                              color: Colors.black,
                            ),
                          ):AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: CameraPreview(controller),
                          ),
                        ),
                        onPressed: (){
                            initializeCamera();
                        },
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Container(
                    height: 245,
                    child: SingleChildScrollView(
                        child: Text(
                          '$result',
                          style: TextStyle(
                              fontSize: 25,
                              color: Colors.black,
                              fontFamily: 'finger_paint'),
                          textAlign: TextAlign.center,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
