import 'dart:convert';

import 'package:alan_voice/alan_voice.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
  late List<CameraDescription> _cameras;
 // class ObjDet extends StatefulWidget {
 //   const ObjDet({Key? key}) : super(key: key);
 //
 //   @override
 //   State<ObjDet> createState() => _ObjDetState();
 // }
 //
 // class _ObjDetState extends State<ObjDet> {
 //   @override
 //   Widget build(BuildContext context) {
 //     return const Placeholder();
 //   }
 // }

void sendData(String text) async {
  var isActive = await AlanVoice.isActive();
  if (!isActive) {
    AlanVoice.activate();
  }
  var params = jsonEncode({"data":text});
  AlanVoice.callProjectApi("script::readtext", params);
}

class ObjDet extends StatefulWidget {
  const ObjDet({Key? key}) : super(key: key);

  @override
  State<ObjDet> createState() => _ObjDetState();
}

class _ObjDetState extends State<ObjDet> {
  @override
  void initState(){
    super.initState();
    _initAlanButton();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      WidgetsFlutterBinding.ensureInitialized();
      try{
        _cameras=await availableCameras();
        print('camera found');
      }on CameraException catch(e){
        print('Error:  $e.code\nError Message:$e.messages');
      }
      setState(() { });

    });
  }
  Future<void> fun() async{
    AlanVoice.activate();
    AlanVoice.playText("Hello! I'm Alan. How can I help you?");
  }
  void _initAlanButton() {
    AlanVoice.onCommand.add((command) async {
      var commandName = command.data["command"]??" ";
      // if(commandName=="wholedoc"){
      //   print('Name:${file!.name}');
      //   print('Bytes:${file!.path}');
      //   PDFDoc doc = await PDFDoc.fromPath(file!.path!);
      //   String docText = await doc.text;
      //   print(docText);
      //   AlanVoice.activate();
      //   debugPrint('donee');
      //   sendData(docText);
      //   //operation
      // }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
          child: Column(
            children: <Widget> [
              ElevatedButton(
                child: Text('Real Time Detection'),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RealTimeDetectionScreen())
                  );
                },
              )
            ],
          )
      ),
    );
  }
}

class RealTimeDetectionScreen extends StatefulWidget {
  const RealTimeDetectionScreen({Key? key}) : super(key: key);

  @override
  _RealTimeDetectionScreenState createState() => _RealTimeDetectionScreenState();
}

class _RealTimeDetectionScreenState extends State<RealTimeDetectionScreen> {
  late CameraController _controller;
  late CameraImage _image;
  bool isDetecting = true;
  List<dynamic>? _recognitions = [];

  @override void initState() {
    super.initState();
    _controller = CameraController(
      _cameras[0],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.yuv420, // ONLY WORKS ON ANDROID
    );
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      loadModel();
      _controller.startImageStream((image) {
        if (!isDetecting) {
          _image = image;
          isDetecting = true;
          runModel();
        }
      });
    }).catchError((Object error) {
      if (error is CameraException) {
        switch (error.code) {
          case 'CameraAccessDenied':
            print('User denied camera access');
            break;
          default:
            print('Exception occured');
            break;
        }
      }
    });
  }

  @override void dispose() {
    Tflite?.close();
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> loadModel() async {
    print('before  loadModel');
    Tflite?.close();
    await Tflite.loadModel(
        model: 'assets/ssd_mobilenet.tflite',
        labels: 'assets/labels.txt',
        numThreads: 1, // defaults to 1
        isAsset: true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate: false // defaults to false, set to true to use GPU delegate
    ).then((result) {
      print('after loadModel');
      print(result);
      isDetecting = false;
    });
  }

  Future<void> runModel() async {
    await Tflite.detectObjectOnFrame(
        bytesList: _image.planes.map((plane) {return plane.bytes;}).toList(),// required
        model: "SSDMobileNet",
        imageHeight: _image.height,
        imageWidth: _image.width,
        imageMean: 127.5,   // defaults to 127.5
        imageStd: 127.5,    // defaults to 127.5
        rotation: 90,       // defaults to 90, Android only
        numResultsPerClass: 2,      // defaults to 5
        threshold: 0.5,     // defaults to 0.1
        asynch: true        // defaults to true
    ).then((recognitions) {
      // setState(() {});
      print(recognitions);
      isDetecting = false;
      // print(recognitions.runtimeType);   // List<Object?>
      setState(() {
        _recognitions = recognitions;
      });
      // setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isInitialized) {
      return Stack(
        children: <Widget>[
          CameraPreview(_controller),
          BoundingBoxes(
            recognitions: _recognitions,
            imageHeight: _image.height,
            imageWidth: _image.width,
            screenHeight: MediaQuery.of(context).size.height,
            screenWidth: MediaQuery.of(context).size.width,
          ),
        ],
      );
    }
    return Container(
      child: Text('Camera Denied'),
    );
  }
}

class BoundingBoxes extends StatefulWidget {
  const BoundingBoxes({
    Key? key,
    required this.recognitions,
    required this.imageHeight,
    required this.imageWidth,
    required this.screenHeight,
    required this.screenWidth,
  }) : super(key: key);

  final List<dynamic>? recognitions;
  final int imageHeight;
  final int imageWidth;
  final double screenHeight;
  final double screenWidth;

  @override
  _BoundingBoxesState createState() => _BoundingBoxesState();
}

class _BoundingBoxesState extends State<BoundingBoxes> {
  Widget renderBoxes() {
    if (widget.recognitions!.isNotEmpty) {
      double width = widget.recognitions![0]['rect']['w'] * widget.screenWidth;
      double height = widget.recognitions![0]['rect']['h'] * widget.screenHeight;
      double startXPosition = widget.recognitions![0]['rect']['x'] * widget.screenWidth;
      double startYPosition = widget.recognitions![0]['rect']['y'] * widget.screenHeight;
      sendData(widget.recognitions![0]['detectedClass']);
      return Positioned(
          left: startXPosition,
          top: startYPosition,
          width: width,
          height: height,
          child: Container(
            child: Text("${widget.recognitions![0]['detectedClass']}",
              style: TextStyle(
                color: Colors.green,
                fontSize: 32,
                backgroundColor: Colors.red,
                decoration: TextDecoration.none,
              ),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 3.0,
              ),
            ),
          )
      );
    }

    return Text('No objects detected');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget> [
        renderBoxes(),
      ],
    );
  }
}



