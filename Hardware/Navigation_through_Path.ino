#include <ESP8266WiFi.h>
#include <FirebaseArduino.h>
#define trigPin 3
#define echoPin 1
long duration;
int distance;
String fireStatus = "";        
#define FIREBASE_HOST "capsiii-ad5f3-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "HZfbfE7tY9zVcqGwtcnawQ5l0qNiHTy2O0tGOUfc"     
#define WIFI_SSID "EACCESS"   
#define WIFI_PASSWORD  "hostelnet"  

void setup() {

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    // Serial.print(".");
    delay(500);
  }
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.setString("DISTANCE", "0");
  pinMode(trigPin, OUTPUT);
pinMode(echoPin, INPUT);
}

void loop() {

// Serial.println("Sending_Data");
digitalWrite(trigPin, LOW);
delayMicroseconds(2);

digitalWrite(trigPin, HIGH);
delayMicroseconds(10);
digitalWrite(trigPin, LOW);
duration = pulseIn(echoPin, HIGH);
distance= duration*0.034/2;
  Firebase.setFloat ("DISTANCE",distance);
  delay(10000);

 if(Firebase.failed())
{
  return;
}
}