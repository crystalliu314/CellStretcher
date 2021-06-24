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
enum State {
  tare, userProfile, getInput, running, returnInitPos
};  //UI states
State currentState=State.tare;

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
int isTared=0;
int isTaredTemp=0;
int isAuxTemp=0;
int isAux=0;

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
Button sine, square, run, cancel, pause, resume, user1, user2, user3, user4, saveSettings, loadUser, jogBak, jogFwd, tareButton, startButton, aux, userBack;
Textlabel controlPanelLabel, hourLabel, minLabel, secLabel;

//int state=0;
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

long returnInitPosTime;
int StateTransitionPause;

boolean loadedUser=false;

boolean jogButtonPressed=false;

int displayAuxError=0;
int displayTareError=0;

int clearedRunningBackground=0;

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

//---------------------------------------------------------------------------------------------------------------
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

  controlPanelLabel=cp5.addTextlabel("label")
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
    .setPosition(675, 500)
    .setSize(200, 75)
    .setColorBackground(#FA0000)
    .setColorForeground(#FF7C80);

  pause=cp5.addButton("pause")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(125, 500)
    .setSize(200, 75);

  resume=cp5.addButton("resume")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(400, 500)
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


  aux=cp5.addButton("Aux")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    // .setPosition(x+680, y)
    .setPosition(x=37, y=500)
    .setSize(150, 75);

  jogBak=cp5.addButton("Jog Back")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    //.setPosition(x=70, y=500)
    .setPosition(x+200, y)
    .setSize(150, 75);

  jogFwd=cp5.addButton("Jog Fwd")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    //.setPosition(x+230, y)
    .setPosition(x+400, y)
    .setSize(150, 75);

  tareButton=cp5.addButton("Tare")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(x+600, y)
    .setSize(150, 75);

  startButton=cp5.addButton("Ready")
    //.setValue(1)
    .setFont(createFont("Arial Black", 20))
    .setPosition(x+800, y)
    .setSize(150, 75);

  userBack=cp5.addButton("Back")
    .setFont(createFont("Arial Black", 20))
    .setPosition(20, 20)
    .setSize(125, 50);

  hourLabel=cp5.addTextlabel("Hour Label")
    //.setText("Cell Stretcher Control Panel")
    .setPosition(275, 400)
    .setColorValue(color(0, 0, 0))
    .setFont(createFont("Arial Bold", 35));

  minLabel=cp5.addTextlabel("Minutes Label")
    //.setText("Cell Stretcher Control Panel")
    .setPosition(375, 400)
    .setColorValue(color(0, 0, 0))
    .setFont(createFont("Arial Bold", 35));

  secLabel=cp5.addTextlabel("Seconds Label")
    //.setText("Cell Stretcher Control Panel")
    .setPosition(475, 400)
    .setColorValue(color(0, 0, 0))
    .setFont(createFont("Arial Bold", 35));
  /*
       fill(0, 0, 0);
   textSize(55);
   text(hours+":", 275, 250);
   
   fill(0, 0, 0);
   textSize(55);
   text(mins+":", 375, 250);
   
   fill(0, 0, 0);
   textSize(55);
   text(secs, 475, 250);
   */

  textFont(createFont("Arial", 16, true));


  //holding jog buttons

  jogBak.addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {

      switch(theEvent.getAction()) {
        case(ControlP5.ACTION_PRESSED): 

        if (isAux==1&&isTared==0) {
          println("JogBack"); 
          serialPort.write("L");
          jogButtonPressed=true;
        } else if (isAux==0) {
          displayAuxError=1;
        }
        break;

        case(ControlP5.ACTION_RELEASED): 
        if (isAux==1&&isTared==0) {
          println("stop"); 
          serialPort.write("l");
          jogButtonPressed=false;
        } 
        break;
      }
    }
  }

  );

  jogFwd.addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {

      switch(theEvent.getAction()) {
        case(ControlP5.ACTION_PRESSED): 
        if (isAux==1&&isTared==0) {
          println("jogFwd");
          serialPort.write("F");
          jogButtonPressed=true;
        } else if (isAux==0) {
          displayAuxError=1;
        }
        break;

        case(ControlP5.ACTION_RELEASED): 
        if (isAux==1&&isTared==0) {
          println("stop"); 
          serialPort.write("f");
          jogButtonPressed=false;
        }
        break;
      }
    }
  }

  );
}

void draw() { //----------------------------------------------------------------------------------------------------------------------------------------------- 
  if (serialPort.available()>0) {
    String myString = "";

    try {
      myString = serialPort.readStringUntil('\n');
    }
    catch (Exception e) {
    }
    if (myString == null) {
      return;
    }

    if (myString.contains("TARE")) {
      // This is a tare frame, empty the array and ignore it
      // Also ignore the next line with indices
      System.out.println("TARE");
    } else {
      // split the string at delimiter (space)
      String[] tempData = split(myString, '\t');   

      // build the arrays for bar charts and line graphs
      if (tempData.length ==10) {
        // This is a normal data frame
        // SPEED POSITION LOADCELL FEEDBACK_COUNT STATE ESTOP STALL DIRECTION INPUT_VOLTAGE BT_FWD BT_BAK BT_TARE BT_START BT_AUX and a space

        try {
          velocity = Float.parseFloat(trim(tempData[0]));
          position = Float.parseFloat(trim(tempData[1]));
          MMTKState = Integer.parseInt(trim(tempData[2]));
          eStop = Integer.parseInt(trim(tempData[3]));
          stall = Integer.parseInt(trim(tempData[4]));
          direction = Integer.parseInt(trim(tempData[5]));
          inputVolts = Float.parseFloat(trim(tempData[6]));
          isTaredTemp = Integer.parseInt(trim(tempData[7]));
          isAuxTemp = Integer.parseInt(trim(tempData[8]));


          //positionCorrected = position - (loadCell * correctionFactor[0] - loadCell * loadCell * correctionFactor[1]);
        }
        catch (NumberFormatException e) {
          System.out.println(e);
        }
      }

      if (isTaredTemp==1) {
        isTared=1;
        tareButton.setColorBackground(#0ACB15);
        displayTareError=0;
      }
      if (isAuxTemp==1) {
        isAux=1;
        aux.setColorBackground(#0ACB15);
        displayAuxError=0;
      }

      //println(isTaredTemp+"  ---  "+isAuxTemp);
      // println(MMTKState + "   "+isTared+"   "+isAux);


      if (currentState == State.tare) {
        if (MMTKState == 0) {     //if mmtk is sending running state, transition to state 1
          currentState = State.getInput ;
        }
      }

      //if (MMTKState == 0) {    
      // sleep(1000);
      // }
    }
  }

  //states: tare, userProfile, getInput, running
  switch (currentState) {
  case tare:
    {
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
      controlPanelLabel.hide();
      user1.hide();
      user2.hide();
      user3.hide();
      user4.hide();
      userName.hide();
      saveSettings.hide();
      loadUser.hide();
      userBack.hide();
      aux.show();
      jogFwd.show();
      jogBak.show();
      tareButton.show();
      startButton.show();

      resume.setColorBackground(#002b5c);    //resetting colours of running screen buttons
      pause.setColorBackground(#002b5c);
      //sine.setColorBackground(#002b5c); 
      //square.setColorBackground(#002b5c);
      /*
      if (isAux==1) {
       aux.setColorBackground(#0ACB15);
       }
       if (isTared==1) {
       tareButton.setColorBackground(#0ACB15);
       }
       */
      /*
      if (jogButtonPressed==true) {
       // serialPort.write("B");
       println("B");
       }
       */

      fill(0, 0, 0);
      textSize(50);
      text("Please Set Initial Position", 155, 100);
      textSize(30);
      text("1. Press AUX button until red LED disappears", 100, 200);
      text("2. Jog stretcher using FORWARD and BACK jog buttons", 100, 250);
      text("3. Press TARE button to set initial position", 100, 300);
      text("4. Press START button to ready stretcher for pattern input", 100, 350);

      if (displayAuxError==1) {
        fill(#FF3B3B); //red
        textSize(15);
        text("ERROR: Please AUX before JOGGING", 100, 400);
      }

      if (displayTareError==1) {
        fill(#FF3B3B); //red
        textSize(15);
        text("ERROR: Please TARE before READY", 100, 425);
      }
      break;
    }
  case userProfile:
    {
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
      controlPanelLabel.hide();
      loadUser.hide();
      userName.hide();
      saveSettings.hide();     

      userBack.show();

      user1.setCaptionLabel(userSettings.getString("name0"));
      user2.setCaptionLabel(userSettings.getString("name1"));
      user3.setCaptionLabel(userSettings.getString("name2"));
      user4.setCaptionLabel(userSettings.getString("name3"));

      user1.show();
      user2.show();
      user3.show();
      user4.show();

      //fill(0, 0, 0);
      fill(0, 0, 0);
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
      break;
    }
  case getInput:
    {
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
      controlPanelLabel.show();
      loadUser.show();
      aux.hide();
      jogFwd.hide();
      jogBak.hide();
      tareButton.hide();
      startButton.hide();
      userBack.hide();

      if (loadedUser==true) {
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
      break;
    }
  case running:
    {

      //sleep(100);   
      displayedUser=false;
      /*
      if (clearedRunningBackground==0) {
       background(bgColor);
       clearedRunningBackground=1;
       }
       */
      background(bgColor);
      //wipe last displayed timer off canvas
      hourLabel.hide();
      minLabel.hide();
      secLabel.hide();
      //sleep(1000);
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
      controlPanelLabel.hide();
      cancel.show();
      pause.show();
      resume.show();
      hourLabel.show();
      minLabel.show();
      secLabel.show();
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
        /*
        hourLabel.setText(str(hours)+":");
         minLabel.setText(str(mins)+":");
         secLabel.setText(str(secs));
         */

        fill(0, 0, 0);
        textSize(55);
        text(hours+":", 275, 450);

        fill(0, 0, 0);
        textSize(55);
        text(mins+":", 375, 450);

        fill(0, 0, 0);
        textSize(55);
        text(secs, 475, 450);



        //sending waveforms
        lastt = currentt;
        currentT = millis()-(int)pauseShift;
        runT = (currentT - startT);   //time now to start
        roundN = Math.floor(runT/cycleT);   //which "round" of wave length are we on?
        cycleN = (int) roundN;
        currentt = (float) (runT - cycleN*cycleT);   //converts running time to limited domain loop (0 and runT)

        if (squareWave == 1&&isPaused==false) {
          if (currentt <= timeA) {

            //EXAMPLE------------------------------------
            nextPosition1 = currentt/timeA * stretchL;  //nextPosition = x, x is a function of t(currentT)
            nextVel1 = stretchL/timeA*60;  //v(t)=x'(t), in this case V is independent of t(current T)
            //_________________________________________
          } else if (currentt > timeA && currentt < (timeA + timeB)) {
            nextPosition1 = stretchL;
          } else if (currentt >= (timeA+timeB) && currentt <= (timeA+timeB+timeC)) {
            nextPosition1 = stretchL - (currentt - timeA - timeB)/timeC * stretchL;
            nextVel1 = stretchL/timeC*60;
          } else if (currentt > (timeA+timeB+timeC) && currentt < (timeA+timeB+timeC+timeD)) {
            nextPosition1 = 0;
          }
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
        }
      }

      if (millis()<endTime) {
        int nextP = -(int) nextPosition1;    //negative to flip direction
        float nextV = (float) nextVel1;
        String printthis = "p" + nextP + "\nv" + nextV + "\n";
        serialPort.write(printthis);
        System.out.println(printthis);
      } else {   //reseting some stuff when timer runs out
        //gotEndTime=0;
        currentState=State.returnInitPos;
        //serialPort.write("S");  //telling arduino to return to stop state
        endTime=999999999;
        start=0;
        isPaused=false;
        //serialPort.write("S");  //telling arduino to return to stop state
        //returnInitPosTime=millis()+4000;
        returnInitPosTime=(int)Math.ceil(millis()+(Math.abs(nextPosition1))/5);
        //println("nextPos: "+nextPosition1);
        //println("stop time millis "+Math.ceil(millis()+(Math.abs(nextPosition1))/5));
        //println("pause time "+(Math.abs(nextPosition1))/5);
      }

      plot();

      break;
    }
  case returnInitPos:
    {
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
      //controlPanelLabel.hide();
      user1.hide();
      user2.hide();
      user3.hide();
      user4.hide();
      userName.hide();
      saveSettings.hide();

      //XYplotOrigin[0] = 0;
      //XYplotOrigin[1] = 0;
      //resetting stuff on 'Tare' screen
      isTared=0;
      isAux=0;
      tareButton.setColorBackground(#002b5c);
      aux.setColorBackground(#002b5c);

      clearedRunningBackground=0;
      plotSetup=0;

      textAlign(LEFT);
      fill(0, 0, 0);
      textSize(55);
      text("Please Wait", 275, 250);

      nextPosition1=0;  //making sure last run's 'nextPosition1' value gets reset
      if (millis()<returnInitPosTime) {
        int nextP =0;   //moving back to initial position so sample can be removed
        float nextV = 500;
        String printthis = "p" + nextP + "\nv" + nextV + "\n";
        serialPort.write(printthis);
        System.out.println(printthis);
        StateTransitionPause=millis()+200;
      } else {
        //print(pauseTime);
        //sleep(4000);
        serialPort.write("S");
        if (millis()>StateTransitionPause) {   //making sure arduino has time to change state before processing
          currentState=State.tare;
        }
      }
      break;
    }
  }
}
import java.util.Arrays;

//=======PLOTTING!!!===================================================================
/*
int xInitPos=27;
 int yInitPos=50;
 int xPos = xInitPos;  
 //Variables to draw a continuous line.
 float lastxPos=xInitPos;
 float lastheight=350;
 int plotHeight=350;
 int plotWidth=970;
 int madePlane=0;
 */


// Generate the plot
int[] XYplotFloatDataDims = {5, 10000};
int[] XYplotIntDataDims = {5, 10000};

// XY Plot
int[] XYplotOrigin = {133, 80};
int[] XYplotSize = {800, 250};
int XYplotColor = color(20, 20, 200);

Graph XYplot = new Graph(XYplotOrigin[0], XYplotOrigin[1], XYplotSize[0], XYplotSize[1], XYplotColor); //(X,Y,W,H,C)

float[][] XYplotFloatData = new float[XYplotFloatDataDims[0]][XYplotFloatDataDims[1]];  //creating plot array [5 possible vars] [10000 spots per var]
int[][] XYplotIntData = new int[XYplotIntDataDims[0]][XYplotIntDataDims[1]];
// This value grows and is used for slicing
int XYplotCurrentSize = 0;

int plotSetup=0;
int periodsDisplayed=3;
int clearPlotCounter=1;

void plot() {

  if (plotSetup==0) {
    XYplot.xLabel="Run Time (sec)";
    XYplot.yLabel="Stretch Length (mm)";
    XYplot.Title="Stretch Length vs Run Time";  
    XYplot.xDiv=2;  
    XYplot.xMax=(timeA+timeB+timeC+timeD)/1000*periodsDisplayed; 
    XYplot.xMin=0;  
    XYplot.yMax=stretchL/1000*1.1;  //1.1 just so plot doesnt reach all the way to yMax 
    XYplot.yMin=0;

    plotSetup=1;
  }
  
  // If the current data is longer than our buffer
  // Have to expand the buffer and continue
  /*
        if (XYplotCurrentSize >= XYplotIntData[0].length) {
   System.out.println("=========== expand buffer ==============");
   int newLength = XYplotIntDataDims[1] + XYplotIntData[0].length;
   int[][] tempIntData = new int[XYplotIntDataDims[0]][newLength];
   float[][] tempFloatData = new float[XYplotFloatDataDims[0]][newLength];
   
   // Copy data to this bigger array
   for (int i=0; i<tempIntData.length; i++) {
   System.arraycopy(XYplotIntData[i], 0, tempIntData[i], 0, XYplotIntData[i].length);
   }
   for (int i=0; i<XYplotFloatData.length; i++) {
   System.arraycopy(XYplotFloatData[i], 0, tempFloatData[i], 0, XYplotFloatData[i].length);
   }
   XYplotIntData = tempIntData;
   XYplotFloatData = tempFloatData;
   }
   */
   

  // update the data buffer
  XYplotFloatData[0][XYplotCurrentSize] = velocity;
  XYplotFloatData[1][XYplotCurrentSize] = -position;
  float nextP = (float) nextPosition1/1000;
  //XYplotFloatData[1][XYplotCurrentSize] = (float) (Math.sin(currentt/timeA * Math.PI*0.5-Math.PI*0.25)+1.0);
  XYplotFloatData[2][XYplotCurrentSize] = loadCell;
  //XYplotFloatData[3][XYplotCurrentSize] = inputVolts;
  XYplotFloatData[3][XYplotCurrentSize] = (runT+pauseShift)/1000;
  XYplotFloatData[4][XYplotCurrentSize] = nextP;

  XYplotIntData[0][XYplotCurrentSize] = feedBack;
  XYplotIntData[1][XYplotCurrentSize] = MMTKState;
  XYplotIntData[2][XYplotCurrentSize] = eStop;
  XYplotIntData[3][XYplotCurrentSize] = stall;
  XYplotIntData[4][XYplotCurrentSize] = direction;
  

  /*
        if (loadCell > maxForce) {
   maxForce = loadCell;
   }
   
   if (position > maxDisplacment) {
   maxDisplacment = position;
   }
   */
   
  
  XYplotCurrentSize ++;


  // Copy data to plot into new array for plotting
  float[] plotTime = Arrays.copyOfRange(XYplotFloatData[3], 0, XYplotCurrentSize);
  float[] plotDisplacement = Arrays.copyOfRange(XYplotFloatData[1], 0, XYplotCurrentSize);
  float[] plotNewDisplacement = Arrays.copyOfRange(XYplotFloatData[4], 0, XYplotCurrentSize);

  // check if graph need to expand
  //if ( maxDisplacment > XYplot.xMax || maxForce > XYplot.xMin ) {
  if (plotTime[plotTime.length-1] > XYplot.xMax ) {
    //XYplot.xMax = max(maxDisplacment, mmtkUIConfig.getInt("mainPlotXMax"));
    // XYplot.yMax = max(maxForce, mmtkUIConfig.getInt("mainPlotYMax"));

   // XYplotOrigin[0] = XYplotCurrentSize;
    Arrays.fill(XYplotFloatData[0], 0);
    Arrays.fill(XYplotFloatData[1], 0);
    Arrays.fill(XYplotFloatData[2], 0);
    Arrays.fill(XYplotFloatData[3], 0);
    Arrays.fill(XYplotFloatData[4], 0);
    XYplotCurrentSize=0;

    XYplot.xMin=XYplot.xMax;  
    XYplot.xMax=(timeA+timeB+timeC+timeD)/1000*periodsDisplayed*clearPlotCounter; 
    clearPlotCounter++;

    //println(plotTime[plotTime.length-1]);
    //println(XYplot.xMax);
    //println("expand plot");
  }



  // draw the line graphs
  XYplot.DrawAxis();
  XYplot.GraphColor = XYplotColor;
  XYplot.DotXY(plotTime, plotDisplacement);
  XYplot.GraphColor = color(200, 20, 20);
  
  /*
  
  if (madePlane==0) {
   fill(255, 255, 255);
   //stroke(0,0,0);     //stroke color
   //strokeWeight(1); 
   rect(xInitPos, yInitPos, plotWidth, plotHeight);
   madePlane=1;
   }
   position=map(position, 0, stretchL, 0, plotHeight-75);
   
   stroke(127, 34, 255);     //stroke color
   strokeWeight(4); 
   println("position "+ position);//stroke wider
   //line(27, 350, 500, 375+position*1000); 
   line(lastxPos, lastheight, xPos, 375+position*1000); 
   lastxPos= xPos;
   xPos++;
   lastheight= 375+position*1000;
   
   if (xPos>=plotWidth+xInitPos) {
   xPos=xInitPos;
   lastxPos=xInitPos;
   madePlane=0;

   }
      */
}
//=========================================================================================
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
      if (!(str.charAt(i) >= '0' && str.charAt(i) <= '9' || str.charAt(i)=='.')) {   //if character is not between 0 and 9 or not equal to .
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

      if (hasError==false) {
        start=1;
        currentState=State.running;
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
      //serialPort.write("S");  //telling arduino to return to stop state
      currentState=State.returnInitPos;
      endTime=999999999;
      start=0;
      returnInitPosTime=(int)Math.ceil(millis()+(Math.abs(nextPosition1))/5);
      //sleep(1000);
      // println("stop");
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
      currentState=State.getInput;
    }
    if (parameter=="user2") {
      userNumber=1;
      getUserSettings(userNumber);
      currentState=State.getInput;
    }
    if (parameter=="user3") {
      userNumber=2;
      getUserSettings(userNumber);
      currentState=State.getInput;
    }
    if (parameter=="user4") {
      userNumber=3;
      getUserSettings(userNumber);
      currentState=State.getInput;
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
      currentState=State.userProfile;
    }

    if (parameter=="Back") {
      loadedUser=false;
      currentState=State.getInput;
    }

    if (parameter=="Aux") {
      serialPort.write("A");
    }
    /*
    if (parameter=="Jog Back") {
     serialPort.write("B");
     }
     if (parameter=="Jog Fwd") {
     serialPort.write("F");
     }
     */
    if (parameter=="Tare") {
      serialPort.write("T");
    }

    if (parameter=="Ready") {
      if (isTared==1) {
        serialPort.write("R");
      } else {
        displayTareError=1;
      }
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
