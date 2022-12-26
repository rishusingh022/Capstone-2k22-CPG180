
import 'dart:convert';
import 'package:alan_voice/alan_voice.dart';
import 'package:flutter/material.dart';


void sendData(String text) async {
  var isActive = await AlanVoice.isActive();
  if (!isActive) {
    AlanVoice.activate();
  }
  var params = jsonEncode({"data":text});
  AlanVoice.callProjectApi("script::readtext", params);
}

class NavPath extends StatefulWidget {
  const NavPath({Key? key}) : super(key: key);

  @override
  State<NavPath> createState() => _NavPathState();
}

class _NavPathState extends State<NavPath> {
  @override
  void initState(){
    super.initState();
    _initAlanButton();
  }
  Future<void> fun() async{
    AlanVoice.activate();
    AlanVoice.playText("Hello! I'm Alan. How can I help you?");
  }
  var list=['17','27','36'];
  var cnt=0;
  void _initAlanButton() {
    AlanVoice.onCommand.add((command) async {
      var commandName = command.data["command"]??" ";
     if(commandName=="distance"){
       sendData(list[cnt]);
       cnt++;
       if(cnt==3)cnt=0;
     }
    });
  }
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
