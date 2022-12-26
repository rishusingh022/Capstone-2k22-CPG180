
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:alan_voice/alan_voice.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf_text/pdf_text.dart';

class ScanDoc extends StatefulWidget {
  const ScanDoc({Key? key}) : super(key: key);

  @override
  State<ScanDoc> createState() => _ScanDocState();
}

class _ScanDocState extends State<ScanDoc> {
  PlatformFile? file;
  @override
  void initState(){
    super.initState();
    _initAlanButton();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result=await FilePicker.platform.pickFiles();
      setState(() { });
      if(result!=null){
        file = result.files.first;
        openFile(file!);
      }
    });
  }
  Future<void> fun() async{
    AlanVoice.activate();
    AlanVoice.playText("Hello! I'm Alan. How can I help you?");
  }
  void _initAlanButton() {
    AlanVoice.onCommand.add((command) async {
      var commandName = command.data["command"]??" ";
      if(commandName=="wholedoc"){
        print('Name:${file!.name}');
        print('Bytes:${file!.path}');
        PDFDoc doc = await PDFDoc.fromPath(file!.path!);
        String docText = await doc.text;
        print(docText);
        AlanVoice.activate();
        debugPrint('donee');
        sendData(docText);
        //operation
      }else{
        var pageno=int.parse(commandName);
        PDFDoc doc = await PDFDoc.fromPath(file!.path!);
        PDFPage page = doc.pageAt(pageno);
        String pageText = await page.text;
        print(pageText);
        AlanVoice.activate();
        debugPrint('donee');
        sendData(pageText);
      }
    });
  }
  void openFile(PlatformFile file) async{
    OpenFile.open(file.path);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

    );
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

