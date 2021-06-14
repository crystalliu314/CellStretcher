import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;
import java.lang.Math.*;
import java.util.*;



PFont buttonTitle_f, mmtkState_f, indicatorTitle_f, indicatorNumbers_f;

// If you want to debug the plotter without using a real serial port set this to true
//boolean mockupSerial = false;

// Serial Setup
String serialPortName;
Serial serialPort;  // Create object from Serial class

// interface stuff
ControlP5 cp5;
//ControlFrame cf;

// Settings for MMUK UI are stored in this config file
//JSONObject mmtkUIConfig;

// ************************
// ** Variables for Data **   probably wont need many of these variables
// ************************

//int XYplotCurrentSize = 0;

int patternReady = 0;
int squareWave = 0;
int sinWave = 0;
int startT = 0;
int currentT = 0;
float runT = 0;
int cycleN = 0;
double roundN = 0;

float mmtkVel = 50.0;
int bgColor = 200;
float stretchL = 10000;   //micro m?
float timeA = 5000;   //milliseconds
float timeB = 2000;
float timeC = 5000;
float timeD = 2000;
float cycleT = 0;
float currentt = 0.0;
float lastt = 0.0;
float nextPosition = 0;
float nextVel = 0;
double nextPosition1 = 0;
double nextVel1 = 0;

int newLoadcellData = 0;
int sendData = 0;
float velocity = 0.0;
float position = 0.0;
float positionCorrected = 0.0;
float loadCell = 0.0;
int feedBack = 0;
int MMTKState = 7;
int eStop = 0;
int stall = 0;
int direction = 0;
float inputVolts = 12.0;

int btBak = 0;
int btFwd = 0;
int btTare = 0;
int btStart = 0;
int btAux = 0;

float[] correctionFactors = new float[2];
float maxForce = 0;
float maxDisplacment = 0;

//steven's added variables and stuff
//Cp5 buttons, text etc.
Textfield stretchLen, TimeA, TimeB, TimeC, TimeD, Hours, Minutes, Seconds, userName;
Button sine, square, run, cancel, pause, resume, user1, user2, user3, user4, saveSettings, loadUser;
Textlabel label;

int state=0;
int start=0;
long runTime=0;  
long endTime=999999999;
long nextSec;  //used to store millis() of next second, used to adjust countdown timer every second
//int tempCounter=0;
int hours;  //stores user entered runtime values
int mins;
int secs;

long pauseStart;  //millis() of start of pause
long pauseFin;   //millis() of end of pause
long pauseShift;   //sum of all paused durations, subtract from system millis() to resume pattern where it was paused  
boolean isPaused=false;

boolean hasError=false;
LinkedList<String> errors = new LinkedList<String>(); 

JSONObject userSettings;
String topSketchPath="";
int userNumber=0;
boolean displayedUser=false;
int numberOfUsers;
int numberOfSettings;

boolean loadedUser=false;

// Pattern image
PImage wavePattern;

//used for testing

public static void sleep(int time) {
  try {
    Thread.sleep(time);
  } 
  catch (Exception e) {
  }
}

void setup() {
  size (1024, 600);  //window size
  serialPort = new Serial(this, "COM4", 115200);

  topSketchPath=sketchPath();
  userSettings=loadJSONObject(topSketchPath+"\\users.json");

  cycleT = (timeA + timeB + timeC + timeD);

  surface.setLocation(100, 100);
  //surface.setResizable(true);
  surface.setVisible(true);
  frameRate(25);
  cp5 = new ControlP5(this);

  int x = 0;
  int y = 0;

  fill(0, 0, 0);

  label=cp5.addTextlabel("label")
    .setText("Cell Stretcher Control Panel")
    .setPosition(x=15, y=7)
    .setColorValue(color(0, 0, 0))
    .setFont(createFont("Arial Bold", 35));

  square=cp5.addButton("Square")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(x, y=75)
    .setSize(200, 75);

  sine=cp5.addButton("Sinusoid")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(x+275, y=75)
    .setSize(200, 75);

  //println(sinWave);
  //println(squareWave);
  //sleep(2000);


  stretchLen=cp5.addTextfield("stretch length (mm)")
    .setPosition(x=15, y+100)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setFont(createFont("Arial", 20))
    .setText("20")
    .setSize(100, 50)
    .setAutoClear(false);


  TimeA=cp5.addTextfield("time A")
    .setPosition(x, y = 285)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(68, 114, 196))
    .setColorBackground(color(68, 114, 196))
    .setFont(createFont("Arial", 20))
    .setText("5")
    .setSize(100, 50)
    .setAutoClear(false);

  TimeB=cp5.addTextfield("time B")
    .setPosition(x+125, y)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(237, 125, 49))
    .setColorBackground(color(237, 125, 49))
    .setFont(createFont("Arial", 20))
    .setText("2")
    .setSize(100, 50)
    .setAutoClear(false);

  TimeC=cp5.addTextfield("time C")
    .setPosition(x+250, y)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(255, 192, 0))
    .setColorBackground(color(255, 192, 0))
    .setFont(createFont("Arial", 20))
    .setText("5")
    .setSize(100, 50)
    .setAutoClear(false);

  TimeD=cp5.addTextfield("time D")
    .setPosition(x+375, y)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(112, 173, 71))
    .setColorBackground(color(112, 173, 71))
    .setFont(createFont("Arial", 20))
    .setText("2")
    .setSize(100, 50)
    .setAutoClear(false);

  Hours=cp5.addTextfield("Hour")
    .setPosition(x=15, y=430)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setFont(createFont("Arial", 20))
    .setText("0")
    .setSize(100, 50)
    .setAutoClear(false);

  Minutes=cp5.addTextfield("Min")
    .setPosition(x+125, y)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setFont(createFont("Arial", 20))
    .setText("0")
    .setSize(100, 50)
    .setAutoClear(false);

  Seconds=cp5.addTextfield("Sec")
    .setPosition(x+250, y)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setFont(createFont("Arial", 20))
    .setText("25")
    .setSize(100, 50)
    .setAutoClear(false);

  loadUser=cp5.addButton("Load User")
    .setPosition(x, y+90)
    .setFont(createFont("Arial Black", 16))
    // .setText("25")
    .setSize(150, 60);

  run=cp5.addButton("Run")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(750, y=500)
    .setSize(200, 75)
    .setColorBackground(#FA0000)
    .setColorForeground(#FF7C80);

  cancel=cp5.addButton("Cancel")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(675, 450)
    .setSize(200, 75)
    .setColorBackground(#FA0000)
    .setColorForeground(#FF7C80);

  pause=cp5.addButton("pause")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(125, 450)
    .setSize(200, 75);

  resume=cp5.addButton("resume")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(400, 450)
    .setSize(200, 75);

  user1=cp5.addButton("user1")
    //.setValue(1)
    .setFont(createFont("Arial Black", 17))
    .setPosition(x=120, y=100)
    .setSize(200, 75);

  user2=cp5.addButton("user2")
    //.setValue(1)
    .setFont(createFont("Arial Black", 17))
    .setPosition(x+230, y)
    .setSize(200, 75);

  user3=cp5.addButton("user3")
    //.setValue(1)
    .setFont(createFont("Arial Black", 17))
    .setPosition(x+460, y)
    .setSize(200, 75);

  user4=cp5.addButton("user4")
    //.setValue(1)
    .setFont(createFont("Arial Black", 17))
    .setPosition(x+690, y)
    .setSize(200, 75);

  userName=cp5.addTextfield("User Name")
    .setPosition(505, 10)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setFont(createFont("Arial", 20))
    .setSize(500, 40)
    .setAutoClear(false);

  saveSettings=cp5.addButton("Save Settings")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(500, y=500)
    .setSize(200, 75)
    //.setColorBackground(#FA0000)
    //.setColorForeground(#FF7C80)
    ;

  textFont(createFont("Arial", 16, true));
}

void draw() { //----------------------------------------------------------------------------------------------------------------------------------------------- 
  if (serialPort.available()>0) {
    char incomingVal=serialPort.readChar();
    println();
    print(incomingVal);

    if (incomingVal=='S') {  //S for start, from arduino
      state=1;
    }
  }

  if (state==0) {      //jog, tare, start state
    background(bgColor);
    stretchLen.hide();
    TimeA.hide();
    TimeB.hide(); 
    TimeC.hide(); 
    TimeD.hide(); 
    Hours.hide(); 
    Minutes.hide(); 
    Seconds.hide();
    sine.hide(); 
    square.hide(); 
    run.hide();
    cancel.hide();
    pause.hide();
    resume.hide();
    label.hide();
    user1.hide();
    user2.hide();
    user3.hide();
    user4.hide();
    userName.hide();
    saveSettings.hide();
    loadUser.hide();

    resume.setColorBackground(#002b5c); 
    pause.setColorBackground(#002b5c);
    //sine.setColorBackground(#002b5c); 
    //square.setColorBackground(#002b5c);

    int nextP =0;   //moving back to initial position so sample can be removed
    float nextV = 200;
    String printthis = "p" + nextP + "\nv" + nextV + "\n";
    serialPort.write(printthis);
    System.out.println(printthis);

    fill(0, 0, 0);
    textSize(50);
    text("Please Set Initial Position", 155, 135);
    textSize(30);
    text("1. Press AUX button until red LED disappears", 100, 250);
    text("2. Jog stretcher using FORWARD and BACK jog buttons", 100, 300);
    text("3. Press TARE button to set initial position", 100, 350);
    text("4. Press START button to ready stretcher for pattern input", 100, 400);
  } else if (state==1) {     //get user parameters state, transistion to running state via run button
    background(bgColor);
    textSize(16);

    user1.hide();
    user2.hide();
    user3.hide();
    user4.hide();
    stretchLen.show();
    TimeA.show();
    TimeB.show(); 
    TimeC.show(); 
    TimeD.show(); 
    Hours.show(); 
    Minutes.show(); 
    Seconds.show();
    sine.show(); 
    square.show(); 
    run.show();
    label.show();
    loadUser.show();

if (loadedUser==true){
  saveSettings.show();
      userName.show();
    if (displayedUser==false) {
      userName.setText(userSettings.getString("name"+userNumber));
      displayedUser=true;
    }
}
    //text("Current Speed: " + String.format("%.02f", mmtkVel) + " mm/min", 125, 70);
    /*
    if (squareWave==1) {
     square.setColorBackground(#4B70FF); 
     sine.setColorBackground(#002b5c);
     } else if (sinWave==1) {
     sine.setColorBackground(#4B70FF); 
     square.setColorBackground(#002b5c);
     }
     */
    // text("Wave Form: ", 600, 400);

    if (sinWave == 1) {
      // text("Sinusoid", 675, 400);
      sine.setColorBackground(#4B70FF); 
      square.setColorBackground(#002b5c);
      wavePattern = loadImage(//topSketchPath+
        "/images/SinPattern.jpg");

      image(wavePattern, 505, 90, 500, 309);
    }

    if (squareWave == 1) {
      //text("Square", 675, 400);
      square.setColorBackground(#4B70FF); 
      sine.setColorBackground(#002b5c);
      wavePattern = loadImage(//topSketchPath+
        "/images/SquarePattern.jpg");

      image(wavePattern, 505, 90, 500, 309);
    }
    textSize(30);
    fill(0, 0, 0); 
    text("Machine run time: ", 15, 410);

    stretchL = float(stretchLen.getText())*1000;
    timeA = float(TimeA.getText())*1000;
    timeB = float(TimeB.getText())*1000;
    timeC = float(TimeC.getText())*1000;
    timeD = float(TimeD.getText())*1000;
    cycleT = (timeA + timeB + timeC + timeD);

    checkErrors();
    if (hasError==true) {
      fill(#FF3B3B); //red
      textSize(15);
      for (int i=0; i<errors.size(); i++) {
        text(errors.get(i), 500, 425+(25*i));
      }
      //transition back to user user parameter state
    }
    //println(start);
    //sleep(2000);
  } else if (state==2) {    //running - displaying timer state
    //sleep(100);   
    displayedUser=false;

    background(bgColor);
    stretchLen.hide();
    TimeA.hide();
    TimeB.hide(); 
    TimeC.hide(); 
    TimeD.hide(); 
    Hours.hide(); 
    Minutes.hide(); 
    Seconds.hide();
    sine.hide(); 
    square.hide(); 
    run.hide();
    label.hide();
    cancel.show();
    pause.show();
    resume.show();
    userName.hide();
    saveSettings.hide();
    loadUser.hide();

    //keep track of seconds to adjust timer
    if (start==1 && millis()<endTime) {
      if (millis()>=nextSec&&isPaused==false) {
        nextSec=millis()+1000;

        secs--;
        if (secs<0) {
          mins--;
          secs=59;
        }

        if (mins<0) {
          hours--;
          mins=59;
        }  
        //text(tempCounter, 100,100);
        //tempCounter++;
      }

      //displaying timer 
      fill(0, 0, 0);
      textSize(55);
      text(hours+":", 275, 250);

      fill(0, 0, 0);
      textSize(55);
      text(mins+":", 375, 250);

      fill(0, 0, 0);
      textSize(55);
      text(secs, 475, 250);
      //nextSec=nextSec+1000;

      lastt = currentt;
      currentT = millis()-(int)pauseShift;
      runT = (currentT - startT);   //time now to start
      roundN = Math.floor(runT/cycleT);   //which "round" of wave length are we on?
      cycleN = (int) roundN;
      currentt = (float) (runT - cycleN*cycleT);   //converts running time to limited domain loop (0 and runT)

      if (squareWave == 1&&isPaused==false) {
        if (currentt <= timeA) {

          //EXAMPLE------------------------------------
          nextPosition = currentt/timeA * stretchL;  //nextPosition = x, x is a function of t(currentT)
          nextVel = stretchL/timeA*60;  //v(t)=x'(t), in this case V is independent of t(current T)
          //_________________________________________
        } else if (currentt > timeA && currentt < (timeA + timeB)) {
          nextPosition = stretchL;
        } else if (currentt >= (timeA+timeB) && currentt <= (timeA+timeB+timeC)) {
          nextPosition = stretchL - (currentt - timeA - timeB)/timeC * stretchL;
          nextVel = stretchL/timeC*60;
        } else if (currentt > (timeA+timeB+timeC) && currentt < (timeA+timeB+timeC+timeD)) {
          nextPosition = 0;
        }
        int nextP = (int) nextPosition;   //passing through serial port
        float nextV = (float) nextVel;
        String printthis = "p" + nextP + "\nv" + nextV + "\n";
        serialPort.write(printthis);
        System.out.println(printthis);
      }

      if (sinWave == 1&&isPaused==false) {
        if (currentt <= timeA/2) {
          float nextt = currentt + currentt - lastt;
          nextPosition1 = (Math.sin(currentt/timeA * Math.PI-Math.PI*0.5)+1)*0.5*stretchL;
          nextVel1 = Math.max(60*Math.cos(nextt/timeA * Math.PI - Math.PI/2)*Math.PI*stretchL/(2*timeA), 10);
        }
        if (currentt > timeA/2 && currentt <= timeA) {
          nextPosition1 = (Math.sin(currentt/timeA * Math.PI-Math.PI*0.5)+1)*0.5*stretchL;
          nextVel1 = Math.max(60*Math.cos(lastt/timeA * Math.PI - Math.PI/2)*Math.PI*stretchL/(2*timeA), 10);
        } else if (currentt > timeA && currentt < (timeA + timeB)) {
          nextPosition1 = stretchL;
          nextVel1 = stretchL/timeA*60;
        } else if (currentt >= (timeA+timeB) && currentt <= (timeA+timeB+timeC/2)) {
          currentt = currentt - timeA - timeB;
          float nextt = currentt + currentt - lastt;
          nextPosition1 = (Math.sin(currentt/timeC * Math.PI+Math.PI*0.5)+1)*0.5*stretchL;
          nextVel1 = Math.max (Math.abs(60*Math.cos(nextt/timeC * Math.PI + Math.PI*0.5)*Math.PI*stretchL/(2*timeC)), 10);
        } else if (currentt >= (timeA+timeB+timeC/2) && currentt <= (timeA+timeB+timeC)) {
          currentt = currentt - timeA - timeB;
          nextPosition1 = (Math.sin(currentt/timeC * Math.PI+Math.PI*0.5)+1)*0.5*stretchL;
          nextVel1 = Math.max (Math.abs(60*Math.cos(lastt/timeC * Math.PI + Math.PI*0.5)*Math.PI*stretchL/(2*timeC)), 10);
        } else if (currentt > (timeA+timeB+timeC) && currentt < (timeA+timeB+timeC+timeD)) {
          nextPosition1 = 0;
          nextVel1 = stretchL/timeC*60;
        }


        int nextP = (int) nextPosition1;
        float nextV = (float) nextVel1;
        String printthis = "p" + nextP + "\nv" + nextV + "\n";
        serialPort.write(printthis);
        System.out.println(printthis);
      }

      //System.out.println(currentT);

      sendData = 0;
      //System.out.println(currentT);

      //sendData = 0;
    }

    if (millis()>endTime) {   //reseting some stuff when timer runs out
      //gotEndTime=0;
      state=0;
      endTime=999999999;
      start=0;
      isPaused=false;
    }
  }

  if (state==4) {     //user select state
    background(bgColor);
    stretchLen.hide();
    TimeA.hide();
    TimeB.hide(); 
    TimeC.hide(); 
    TimeD.hide(); 
    Hours.hide(); 
    Minutes.hide(); 
    Seconds.hide();
    sine.hide(); 
    square.hide(); 
    run.hide();
    cancel.hide();
    pause.hide();
    resume.hide();
    label.hide();
    loadUser.hide();
    userName.hide();
    saveSettings.hide();

    user1.setCaptionLabel(userSettings.getString("name0"));
    user2.setCaptionLabel(userSettings.getString("name1"));
    user3.setCaptionLabel(userSettings.getString("name2"));
    user4.setCaptionLabel(userSettings.getString("name3"));

    user1.show();
    user2.show();
    user3.show();
    user4.show();

    //fill(0, 0, 0);
    textSize(40);
    text("Select User", 400, 60);

    int y;
    textSize(25);
    text("Wave: ", 12, y=215);
    text("Length: ", 12, y=y+45);
    text("Time A: ", 12, y=y+45);
    text("Time B: ", 12, y=y+45);
    text("Time C: ", 12, y=y+45);
    text("Time D: ", 12, y=y+45);
    text("Run Hrs: ", 12, y=y+45);
    text("Run Mins: ", 12, y=y+45);
    text("Run Secs: ", 12, y=y+45);

    String[] settings= {"wavePattern", "stretchLength", "timeA", "timeB", "timeC", "timeD", "hours", "mins", "secs"};
    int[] xPositions={200, 430, 660, 890};

    //print(userSettings.getString(settings[2]+str(0)));

    for (int i=0; i<4; i++) {   //cycles through user
      y=170;
      for (int j=0; j<9; j++) {   //cycles through all settings of one user
        //user1 info
        text(userSettings.getString(settings[j]+str(i)), xPositions[i], y=y+45);
        //text(userSettings.getString(settings[2]+str(0)), 15,15);
      }
    }
  }
}

boolean onlyDigits(String str, int n)
{
  boolean onlyDigits=true;

  if (n==0) {
    return true;
  } else {
    for (int i=0; i<n; i++) {
      // Check if character is
      // digit from 0-9
      // then return true
      // else false
      if (!(str.charAt(i) >= '0'
        && str.charAt(i) <= '9')) {
        onlyDigits=false;
        //} else {
        //onlyDigits= false;
        //}
      }
    }
    return onlyDigits;
  }
}


void checkErrors() {
  hasError=false;
  errors.clear();
  if (sinWave==0 && squareWave==0) {
    hasError=true; 
    errors.add("ERROR: Missing waveform");
  }
  if (stretchLen.getText().isEmpty()==true || 
    TimeA.getText().isEmpty()==true||
    TimeB.getText().isEmpty()==true||
    TimeC.getText().isEmpty()==true|| 
    TimeD.getText().isEmpty()==true||
    Hours.getText().isEmpty()==true||
    Minutes.getText().isEmpty()==true||
    Seconds.getText().isEmpty()==true) {
    hasError=true; 
    errors.add("ERROR: Empty text field(s)");
  } 
  if (onlyDigits(stretchLen.getText(), stretchLen.getText().length())==false||
    onlyDigits(TimeA.getText(), TimeA.getText().length())==false||
    onlyDigits(TimeB.getText(), TimeB.getText().length())==false||
    onlyDigits(TimeC.getText(), TimeC.getText().length())==false||
    onlyDigits(TimeD.getText(), TimeD.getText().length())==false||
    onlyDigits(Hours.getText(), Hours.getText().length())==false||
    onlyDigits(Minutes.getText(), Minutes.getText().length())==false||
    onlyDigits(Seconds.getText(), Seconds.getText().length())==false) {
    hasError=true; 
    errors.add("ERROR: Input(s) contain characters");
  }

  //if (stretchLen.matches("//d+")){

  //}
}

void getUserSettings(int userNumber) {

  Hours.setText(str(userSettings.getInt("hours"+userNumber)));
  Minutes.setText(str(userSettings.getInt("mins"+userNumber)));
  Seconds.setText(str(userSettings.getInt("secs"+userNumber)));
  stretchLen.setText(str(userSettings.getInt("stretchLength"+userNumber)));
  TimeA.setText(str(userSettings.getInt("timeA"+userNumber)));
  TimeB.setText(str(userSettings.getInt("timeB"+userNumber)));
  TimeC.setText(str(userSettings.getInt("timeC"+userNumber)));
  TimeD.setText(str(userSettings.getInt("timeD"+userNumber)));

  println(Minutes.getValue());
  if (userSettings.getString("wavePattern"+userNumber).equals("sine")) {
    sinWave=1; 
    squareWave=0;
  } else if (userSettings.getString("wavePattern"+userNumber).equals("square")) {
    squareWave=1; 
    sinWave=0;
  }
}
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController()) {
    String parameter=theEvent.getController().getName();
    print(theEvent);

    //if (theEvent.isAssignableFrom(Textfield.class) || theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
    //String parameter = theEvent.getName();
    String value = "";

    //if (theEvent.isAssignableFrom(Textfield.class))
    //value = theEvent.getStringValue();

    //else 
    // if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class))
    value = theEvent.getValue()+"";

    // print("set "+parameter+" "+value+";\n");

    if (parameter == "input speed") {
      mmtkVel = float(value);
      serialPort.write("V" + mmtkVel + "\n");
    }

    if (parameter == "Run") {
      //patternReady = 1;
      println("run pressed");


      //checkErrors();
      if (hasError==false) {
        start=1;
        state=2;
        loadedUser=false;
        startT=millis();
        // startT = millis();
        //if (gotEndTime==0) {
        hours=int(Hours.getText());
        mins=int(Minutes.getText());
        secs=int(Seconds.getText());
        stretchL=float(stretchLen.getText())*1000;

        runTime=hours*1200 +mins*60 +secs;  //in seconds
        //println(runTime);
        endTime=millis()+runTime*1000;
        //println(endTime);
        nextSec=millis()+1000;
        // gotEndTime=1;
        //start=1;
      }
    }

    if (parameter == "Square") {
      squareWave = 1;
      sinWave = 0;
      square.setColorBackground(#4B70FF); 
      sine.setColorBackground(#002b5c);
    }

    if (parameter == "Sinusoid") {
      sinWave = 1;
      squareWave = 0;
      sine.setColorBackground(#4B70FF);
      square.setColorBackground(#002b5c);
    }

    if (parameter == "Cancel") {
      state=0;
      endTime=999999999;
      start=0;
    }

    if (parameter == "pause") {
      isPaused=true;
      pauseStart=millis();
      pause.setColorBackground(#4B70FF); 
      resume.setColorBackground(#002b5c);
    }

    if (parameter == "resume") {
      isPaused=false;
      pauseFin=millis();
      endTime=endTime+(pauseFin-pauseStart);   //readjust endTime
      pauseShift+=(pauseFin-pauseStart);
      nextSec+=pauseFin-pauseStart;

      resume.setColorBackground(#4B70FF); 
      pause.setColorBackground(#002b5c);
    }

    if (parameter=="user1") {
      userNumber=0;
      getUserSettings(userNumber);
      state=1;
    }
    if (parameter=="user2") {
      userNumber=1;
      getUserSettings(userNumber);
      state=1;
    }
    if (parameter=="user3") {
      userNumber=2;
      getUserSettings(userNumber);
      state=1;
    }
    if (parameter=="user4") {
      userNumber=3;
      getUserSettings(userNumber);
      state=1;
    }

    if (parameter=="Save Settings") {
      userSettings.setString("name"+userNumber, userName.getText());
      userSettings.setString("stretchLength"+userNumber, stretchLen.getText());
      userSettings.setString("timeA"+userNumber, TimeA.getText());
      userSettings.setString("timeB"+userNumber, TimeB.getText());
      userSettings.setString("timeC"+userNumber, TimeC.getText());
      userSettings.setString("timeD"+userNumber, TimeD.getText());
      userSettings.setString("hours"+userNumber, Hours.getText());
      userSettings.setString("mins"+userNumber, Minutes.getText());
      userSettings.setString("secs"+userNumber, Seconds.getText());
      if (sinWave==1) {
        userSettings.setString("wavePattern"+userNumber, "sine");
      } else if (squareWave==1) {
        userSettings.setString("wavePattern"+userNumber, "square");
      }
      // stretchLen, TimeA, TimeB, TimeC, TimeD, Hours, Minutes, Seconds, userName;
      saveJSONObject(userSettings, topSketchPath+"\\users.json");
    }

    if (parameter=="Load User") {
      loadedUser=true;
      displayedUser=false;
      state=4;
    }

    /*
    // Send Serial Commands to MMTK
     if (!mockupSerial) {
     if (parameter == "Start") {
     serialPort.write("Begin\n");
     } else if (parameter == "Tare") {
     serialPort.write("Tare\n");
     } else if (parameter == "Stop") {
     serialPort.write("Stop\n");
     } else if (parameter == "5kg calibration") {
     serialPort.write("Calibration\n");
     }
     }
     */
  }
}



/* for seth - creating a new wave: procedure
 1. find function of desired pattern: x(t)=.... assign x=nextPosition, t=currentT
 2. find velocity (nextVel) function of pattern: v(t)= x'(t) <-take derivative of x(t), you can use symbolab.com calculator if you haven't learned calculus yet
 see EXAMPLE below for steps 1 and 2
 
 3. pass nextPosition and nextVel to arduino via serial port:
 serialPort.write("p"+nextPosition+"\nv"+nextVel+"\n");
 */