import controlP5.*;
import processing.serial.*;

int state=0;

//creating objects
ControlP5 cp5;
Serial serialPort;

PFont buttonFont;
boolean sineIsPressed=false;
boolean triangleIsPressed=false;

String waveMode;

//for control screen
Slider amplitude;
Button sine, triangle, HU, HD, MU, MD, SU, SD, PSU, PSD, start;

//for running screen
Button resume, pause;

int hours;
int minutes;
int seconds;

int period;

int totalSeconds;

//for running screen (state 2)
int timerHour=hours;
int timerMin=minutes;
int timerSec=seconds;
long nextSec;

long pauseTime;
long resumeTime;
boolean isPaused=false;

/*
public static void sleep(int time){
 try{
 Thread.sleep(time);
 } catch (Exception e){}
 }
 
 */


void setup() {
  size (800, 480);  //window size

  serialPort = new Serial(this, "COM3", 9600);
  cp5 = new ControlP5(this);

  buttonFont = createFont("calibri bold", 30);

  sine=cp5.addButton("Sine")
    .setPosition(100, 40)
    .setSize(200, 50)
    .setFont(buttonFont)
    .setColorBackground(#E87800);

  triangle=cp5.addButton("Triangle")
    .setPosition(500, 40)
    .setSize(200, 50)
    .setFont(buttonFont)
    .setColorBackground(#E87800);

  amplitude = cp5.addSlider("amplitude")
    .setPosition(25, 150)
    .setSize(750, 60)
    .setRange(0, 20)
    .setDecimalPrecision(1)
    .setNumberOfTickMarks(200)
    .setFont(buttonFont)
    .setCaptionLabel("")
    .snapToTickMarks(true)
    .setColorBackground(#E87800);

  //runtime hours
  HU=cp5.addButton("HU")
    .setPosition(145, 295)
    .setSize(75, 30)
    .setFont(buttonFont)
    .setCaptionLabel("↑ H")
    .setColorBackground(#E87800);

  HD=cp5.addButton("HD")
    .setPosition(145, 335)
    .setSize(75, 30)
    .setFont(buttonFont)
    .setCaptionLabel("↓ H")
    .setColorBackground(#E87800);

  // runtime minutes
  MU=cp5.addButton("MU")
    .setPosition(395, 295)
    .setSize(75, 30)
    .setFont(buttonFont)
    .setCaptionLabel("↑ M")
    .setColorBackground(#E87800);

  MD=cp5.addButton("MD")
    .setPosition(395, 335)
    .setSize(75, 30)
    .setFont(buttonFont)
    .setCaptionLabel("↓ M")
    .setColorBackground(#E87800);

  // runtime seconds
  SU=cp5.addButton("SU")
    .setPosition(645, 295)
    .setSize(75, 30)
    .setFont(buttonFont)
    .setCaptionLabel("↑ S")
    .setColorBackground(#E87800);

  SD=cp5.addButton("SD")
    .setPosition(645, 335)
    .setSize(75, 30)
    .setFont(buttonFont)
    .setCaptionLabel("↓ S")
    .setColorBackground(#E87800);

  // period Seconds
  PSU=cp5.addButton("PSU")
    .setPosition(395, 390)
    .setSize(75, 30)
    .setFont(buttonFont)
    .setCaptionLabel("↑ S")
    .setColorBackground(#E87800);

  PSD=cp5.addButton("PSD")
    .setPosition(395, 430)
    .setSize(75, 30)
    .setFont(buttonFont)
    .setCaptionLabel("↓ S")
    .setColorBackground(#E87800);

  //start button
  start=cp5.addButton("start")
    .setPosition(600, 390)
    .setSize(150, 70)
    .setFont(buttonFont)
    .setColorBackground(#FA0000);


  //for running screen
  resume=cp5.addButton("Resume")
    .setPosition(100, 325)
    .setSize(200, 100)
    .setFont(buttonFont)
    .setColorBackground(#E87800);

  pause=cp5.addButton("Pause")
    .setPosition(500, 325)
    .setSize(200, 100)
    .setFont(buttonFont)
    .setColorBackground(#E87800);
}

//----------------------------------------------------------------------------------------
void draw() {   //like void loop() of arduino

  if (state==0) {
    //tare screen
    background(#FFE0BF);


    fill(0, 0, 0);
    textSize(50);
    text("Please Tare Stretcher", 155, 135);
    textSize(30);
    text("1. Jog stretcher using FORWARD\n           and BACK jog buttons", 150, 250);
    text("2. Press TARE button to continue", 160, 370);

    sine.hide();
    triangle.hide();
    amplitude.hide();
    HU.hide();
    HD.hide();
    MU.hide();
    MD.hide();
    SU.hide();
    SD.hide();
    PSU.hide();
    PSD.hide();
    start.hide();
    resume.hide();
    pause.hide();

    if (serialPort.available()>0) {
      //String incomingVal=serialPort.readStringUntil('\n');
      char incomingVal=serialPort.readChar();
      println();
      print(incomingVal);
      println("Tare");
      //println(incomingVal.equals("Tare"));
      if (incomingVal=='T') {
        println(state); 
        state=1; 
        println(state);
      }
    }
  } else if (state==1) {
    //control parameters screen 
    background(#FFE0BF);

    sine.show();
    triangle.show();
    amplitude.show();
    HU.show();
    HD.show();
    MU.show();
    MD.show();
    SU.show();
    SD.show();
    PSU.show();
    PSD.show();
    start.show();

    //wave select text
    fill(0, 0, 0);
    textSize(30);
    text("Wave Pattern", 300, 30);

    //amplitude slider text
    fill(0, 0, 0);
    textSize(30);
    text("Stretch Amplitude (mm)", 230, 135);

    //runtime text
    fill(0, 0, 0);
    textSize(30);
    text("Runtime", 300, 275);

    //amplitude text
    fill(0, 0, 0);
    textSize(30);
    text("Period (s): ", 100, 430);

    //hours text box
    fill(#DEDEDE);
    rect(23, 295, 100, 60, 4);

    fill(0, 0, 0);
    textSize(25);
    text(str(hours), 30, 335);


    //minutes text box
    fill(#DEDEDE);
    rect(275, 295, 100, 60, 4);

    fill(0, 0, 0);
    textSize(25);
    text(str(minutes), 282, 335);

    //seconds text box
    fill(#DEDEDE);
    rect(525, 295, 100, 60, 4);

    fill(0, 0, 0);
    textSize(25);
    text(str(seconds), 534, 335);

    //amplitude seconds text box
    fill(#DEDEDE);
    rect(275, 390, 100, 60, 4);

    fill(0, 0, 0);
    textSize(25);
    text(str(period), 282, 430);
    print("a"+Math.floor(amplitude.getValue()*10.0)/10.0+"\n");
  } else if (state==2) {     //running state
    //long endTimer=millis()+(totalSeconds*1000); //+1000 to compensate for time delay of arduino to start driving motor
    //int secCounter=(totalSeconds*1000)-1000;  //will count to 10 and reset (every second) CAN TRY CENTISECONDS
    fill(0, 0, 0);
    textSize(30);
    text("Wave Mode:             "+waveMode, 50, 30);

    fill(0, 0, 0);
    textSize(30);
    text("Stretch Amplitude:  "+Math.floor(amplitude.getValue()*10.0)/10.0+" mm", 50, 70);

    fill(0, 0, 0);
    textSize(30);
    text("Wave Period:           "+period+" seconds", 50, 110);

    fill(0, 0, 0);
    textSize(30);
    text("Runtime:                 "+hours+" H "+minutes+" M "+seconds+" S ", 50, 150);
    if (millis()>=nextSec && isPaused==false) {
      timerSec--;

      if (timerSec<0) {
        timerMin--;
        timerSec=59;
      }

      if (timerMin<0) {
        timerHour--;
        timerMin=59;
      }


      background(#FFE0BF);

      //displaying timer 
      fill(0, 0, 0);
      textSize(55);
      text(timerHour+":", 275, 250);

      fill(0, 0, 0);
      textSize(55);
      text(timerMin+":", 375, 250);

      fill(0, 0, 0);
      textSize(55);
      text(timerSec, 475, 250);
      nextSec=nextSec+1000;
    }
    /*
    //long decisecBeginning=millis();
     fill(0, 0, 0);
     textSize(50);
     text(timerHour, 100, 135);
     
     fill(0, 0, 0);
     textSize(50);
     text(timerMin, 200, 135);
     
     fill(0, 0, 0);
     textSize(50);
     text(timerSec, 300, 135);
     
     
     //millis()!=endTimer
     if (millis()>=endTimer-secCounter){   ///marks every second
     timerSec--;
     
     if(timerSec<0){
     timerMin--;
     timerSec=59;
     }
     
     if(timerMin<0){
     timerHour--;
     timerMin=59;
     }
     secCounter=secCounter-1000;
     }
     */


    if (serialPort.available()>0) {
      //String incomingVal=serialPort.readStringUntil('\n');
      char incomingVal=serialPort.readChar();
      print(incomingVal);
      //println(incomingVal.equals("Tare"));
      if (incomingVal=='D') {
        state=0;
      }
    }
  }
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController()) {
    print(theEvent);

    if (theEvent.getController().getName()=="Sine") {
      waveMode="sine";
      sine.setColorBackground(#4B70FF); 
      triangle.setColorBackground(#E87800);
    }

    if (theEvent.getController().getName()=="Triangle") {
      waveMode="triangle";
      triangle.setColorBackground(#4B70FF); 
      sine.setColorBackground(#E87800);
    }

    if (theEvent.getController().getName()=="HU") {
      hours++;
    }

    if (theEvent.getController().getName()=="HD") {
      if (hours>0) {
        hours--;
      }
    }

    //minutes
    if (theEvent.getController().getName()=="MU") {
      minutes++;
      if (minutes>59) {
        //hours++;
        minutes=0;
      }
    }

    if (theEvent.getController().getName()=="MD") {
      minutes--;
      if (minutes<0) {
        //hours--;
        //if (hours<0){
        //hours=0; 
        minutes=59;
      }
      //minutes=0;
    }

    //seconds
    if (theEvent.getController().getName()=="SU") {
      seconds++;
      if (seconds>59) {
        seconds=0;
      }
    }

    if (theEvent.getController().getName()=="SD") {
      seconds--;
      if (seconds<0) {
        seconds=59;
      }
    }

    //Period seconds
    if (theEvent.getController().getName()=="PSU") {
      period++;
    }

    if (theEvent.getController().getName()=="PSD") {
      period--;
      if (period<0) {
        period=0;
      }
    }

    if (theEvent.getController().getName()=="start") {
      //setting up a few things for running screen (state 2)
      //show timer
      timerHour=hours;
      timerMin=minutes;
      timerSec=seconds;
      nextSec=millis()+1000;
      background(#FFE0BF);
      sine.hide();
      triangle.hide();
      amplitude.hide();
      HU.hide();
      HD.hide();
      MU.hide();
      MD.hide();
      SU.hide();
      SD.hide();
      PSU.hide();
      PSD.hide();
      start.hide();
      resume.show();
      pause.show();



      totalSeconds=(hours*3600)+(minutes*60)+seconds;

      //send info
      serialPort.write("w"+waveMode+"\n");
      println("wave: "+ waveMode);
      serialPort.write("a"+Math.floor(amplitude.getValue()*10.0)/10.0);
      println("amplitude: "+ Math.floor(amplitude.getValue()*10.0)/10.0);
      serialPort.write("t"+totalSeconds);
      println("runtime: "+ totalSeconds);
      serialPort.write("p"+period);
      println("Period: "+ period);

      state=2;
    }

    if (theEvent.getController().getName()=="Pause") {
      serialPort.write("pause"+"\n");
      pauseTime=millis();
      isPaused=true;
      println("pause");
      pause.setColorBackground(#4B70FF); 
      resume.setColorBackground(#E87800);
    }

    if (theEvent.getController().getName()=="Resume") {
      serialPort.write("resume"+"\n");
      resumeTime=millis();
      isPaused=false;
      nextSec=nextSec+(resumeTime-pauseTime);
      println("resume");
      resume.setColorBackground(#4B70FF); 
      pause.setColorBackground(#E87800);
    }
  }
}

/*
public class runFrame extends PApplet {
 public void setup(){
 size (800, 480);
 }
 
 public void draw(){
 background(0,0,0);
 }
 }
 */
/*

 public void HU() {
 print(str(hours));
 hours++;
 //add some upper limit
 }
 
 public void HD() {
 print(str(hours));
 if(hours>0){
 hours--;
 }
 }
 */
