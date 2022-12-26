import 'dart:convert';
import 'dart:io';
import 'package:alan_voice/alan_voice.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';


class ScanText extends StatefulWidget {
  const ScanText({Key? key}) : super(key: key);

  @override
  State<ScanText> createState() => _ScanTextState();
}

class _ScanTextState extends State<ScanText> {
  File? imageFile;

  @override
  void initState(){
    super.initState();
    _initAlanButton();
  }
  Future<void> fun() async{
    AlanVoice.activate();
    AlanVoice.playText("Hello! I'm Alan. How can I help you?");
  }
  void _initAlanButton() {
    AlanVoice.onCommand.add((command) async {
      var commandName = command.data["command"]??" ";
      if(commandName=="opencamera"){
        AlanVoice.activate();
        AlanVoice.playText('opening camera');
       // _getFromGallery() async{
      //     XFile? pickedFile = await ImagePicker().pickImage(
      //       source: ImageSource.camera,
      //       maxHeight: MediaQuery.of(context).size.height-80,
      //       maxWidth: MediaQuery.of(context).size.width-20,
      //     );
      //     if (pickedFile != null) {
      //       setState(() => {
      //         //imageCache.clear(), imageCache.clearLiveImages(),
      //        imageFile = File(pickedFile.path),
      //       });
      //
      // //    }
        getImage(source: ImageSource.camera);

        //  final textdetector= GoogleMlKit.vision.textDetector();
        //  RecognisedText recognisedText=await textdetector.processImage(inputimage);
        //  await textdetector.close();
        //  for (TextBlock block in recognisedText.blocks) {
        //   for (TextLine line in block.lines) {
        //     _text = _text + line.text + "\n";
        //   }
        // }
        // debugPrint(_text);
        // AlanVoice.activate();
        // AlanVoice.playText(_text);

      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Padding(

      padding: const EdgeInsets.fromLTRB(20.0,40.0,20,40.0),
      child: Column(

        children: [
          if(imageFile!=null)
        new Center(
                    child: imageFile == null
                       ? Expanded(
                         child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          border: Border.all(width: 8, color:Colors.black12),
                          borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                       )
                         : new Image.file(imageFile!
                        ,height: MediaQuery.of(context).size.height-80,
                      scale: 0.1,

                    ),
                   ),
        ],
      ),
    );
  }

  Future getImage({required ImageSource source}) async{
    var file=await ImagePicker().pickImage(
        source: source,
        // maxHeight: 200,
        // maxWidth: 100,
        imageQuality: 100,
    ); //created object of picked image
    debugPrint(file?.path);
    debugPrint('new file path is');
    debugPrint(file?.path);
    if(file?.path!=null){
      debugPrint('file path is not null');
      if(true){
        imageFile=(File(file!.path));
        setState(() async {
        debugPrint('elts set the state');

        debugPrint('ok the fiannal file path is');
        debugPrint(file.path);//obtaining path of picked image
        debugPrint('START INITIALIZING image');
        String _text=" ";
        final inputImage=InputImage.fromFilePath(imageFile!.path);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        debugPrint('image initialized');
        String text = recognizedText.text;
        for (TextBlock block in recognizedText.blocks) {
          debugPrint('new block');
          //final Rect rect = block.rect;
          //final List<Offset> cornerPoints = block.cornerPoints;
          //final String text = block.text;
          //final List<String> languages = block.recognizedLanguages;
          for (TextLine line in block.lines) {
            _text=_text+line.text+'\n';
            debugPrint(_text);
          }
        }
        textRecognizer.close();
        debugPrint(_text);
        debugPrint('donee');
        sendData(_text);
        // AlanVoice.activate();
        // AlanVoice.playText(_text);
     });}
    }else debugPrint('file path is null');
    return file;
  }
  void sendData(String text) async {
    var isActive = await AlanVoice.isActive();
    if (!isActive) {
      AlanVoice.activate();
    }
    var params = jsonEncode({"data":text});
    AlanVoice.callProjectApi("script::readtext", params);
  }
}
