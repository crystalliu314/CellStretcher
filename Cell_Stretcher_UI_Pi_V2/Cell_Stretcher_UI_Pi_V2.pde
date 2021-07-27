import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;
import java.lang.Math.*;
import java.util.*;
import javax.swing.JOptionPane;

PFont buttonTitle_f, mmtkState_f, indicatorTitle_f, indicatorNumbers_f;

//Cell Stretcher States
enum State {
  tare, userProfile, getInput, running, returnInitPos, stopped
};  //UI states
State currentState=State.tare;

// Serial Setup
String serialPortName;
Serial serialPort;  // Create object from Serial class

// interface stuff
ControlP5 cp5;

// Saved User Settings are stored in this config file. Other vars for saving and retrieving settings
JSONObject userSettings;
String topSketchPath="";
int userNumber=0;
boolean displayedUser=false;
int numberOfUsers;
int numberOfSettings;

// ************************
// ** Variables for Data **   
// ************************

//int XYplotCurrentSize = 0;

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
//float nextPosition = 0;
//float nextVel = 0;
double nextPosition1 = 0;
double nextVel1 = 0;

int newLoadcellData = 0;
int sendData = 0;
float velocity = 0.0;
float position = 0.0;
float positionCorrected = 0.0;
float loadCell = 0.0;
int feedBack = 0;
int MMTKState = 1;
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
Button sine, square, run, cancel, pause, resume, user1, user2, user3, user4, saveSettings, loadUser, jogBak, jogFwd, tareButton, startButton, aux, userBack, eStopAux, eStopResume;
Textlabel controlPanelLabel;

//vars for runtime timer
int start=0;
long runTime=0;  
long endTime=999999999;
long nextSec;  //used to store millis() of next second, used to adjust countdown timer every second
int hours;  
int mins;
int secs;

//vars for pause/resume 
long pauseStart;  //millis() of start of pause
long pauseFin;   //millis() of end of pause
long pauseShift;   //sum of all paused durations, subtract from system millis() to resume pattern where it was paused  
boolean isPaused=false;

//keeping track of errors on user input screen
boolean hasError=false;
LinkedList<String> errors = new LinkedList<String>(); 

//vars for returning stretcher to initial position at end of stretch
long returnInitPosTime;  //millis() of when stretch has ended
int StateTransitionPause;  //how long to pause for to allow stretcher to return to init position

boolean loadedUser=false;

//vars for setup screen
boolean jogButtonPressed=false;
int displayAuxError=0;
int displayTareError=0;

//int clearedRunningBackground=0;

// Pattern image
PImage wavePattern;

//pause function used for testing
public static void sleep(int time) {
  try {
    Thread.sleep(time);
  } 
  catch (Exception e) {
  }
}

boolean windowPosFlag;
//---------------------------------------------------------------------------------------------------------------
void setup() {
  windowPosFlag=false;
  size (1024, 570);  //window size
  surface.setTitle("CaT Stretcher");



  String[] serialPortList = Serial.list();
  String[] serialPortChoices = new String[serialPortList.length];
  for (int i = 0; i < Serial.list().length; i++) {
    serialPortChoices[i] = serialPortList[i];
  }


  serialPortName = (String) JOptionPane.showInputDialog(null, "Please Select The Serial Port for Cell Stretcher", "Serial Port", JOptionPane.QUESTION_MESSAGE, null, serialPortChoices, serialPortChoices[0]);

  System.out.println(serialPortName);
  serialPort = new Serial(this, serialPortName, 57600);


  // serialPort = new Serial(this, "/dev/ttyUSB0", 57600);   //fake uno
  //serialPort = new Serial(this, "/dev/ttyACM0", 57600);  //eligoo uno

  topSketchPath=sketchPath();
  userSettings=loadJSONObject(topSketchPath+"/users.json");

  cycleT = (timeA + timeB + timeC + timeD);

  surface.setLocation(100, 100);
  surface.setVisible(true);
  frameRate(25);
  cp5 = new ControlP5(this);

  int x = 0;
  int y = 0;

  fill(0, 0, 0);

  //cp5 objects (buttons, textfields, etc.)
  //setup screen
  aux=cp5.addButton("Aux")
    .setFont(createFont("Arial Black", 20))
    .setPosition(x=37, y=470)
    .setSize(150, 75);

  jogBak=cp5.addButton("Jog Back")
    .setFont(createFont("Arial Black", 20))
    .setPosition(x+200, y)
    .setSize(150, 75);

  jogFwd=cp5.addButton("Jog Fwd")
    .setFont(createFont("Arial Black", 20))
    .setPosition(x+400, y)
    .setSize(150, 75);

  //holding jog buttons

  jogBak.addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {

      switch(theEvent.getAction()) {
        case(ControlP5.ACTION_PRESSED): 

        if (isAux==1) {
          println("JogBack"); 
          serialPort.write("L");
          jogButtonPressed=true;
          tareButton.setColorBackground(#002b5c);
          tareButton.setColorForeground(#4B70FF);

          isTared=0;
        } else if (isAux==0) {
          displayAuxError=1;
        }
        break;

        case(ControlP5.ACTION_RELEASED): 
        if (isAux==1) {
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
        if (isAux==1) {
          println("jogFwd");
          serialPort.write("F");
          jogButtonPressed=true;
          tareButton.setColorBackground(#002b5c);
          tareButton.setColorForeground(#4B70FF);

          isTared=0;
        } else if (isAux==0) {
          displayAuxError=1;
        }
        break;

        case(ControlP5.ACTION_RELEASED): 
        if (isAux==1) {
          println("stop"); 
          serialPort.write("f");
          jogButtonPressed=false;
        }
        break;
      }
    }
  }

  );
  tareButton=cp5.addButton("Tare")
    .setFont(createFont("Arial Black", 20))
    .setPosition(x+600, y)
    .setSize(150, 75);

  startButton=cp5.addButton("Ready")
    .setFont(createFont("Arial Black", 20))
    .setPosition(x+800, y)
    .setSize(150, 75);


  //control panel/user inputs screen
  controlPanelLabel=cp5.addTextlabel("label")
    .setText("Cell Stretcher Control Panel")
    .setPosition(x=15, y=7)
    .setColorValue(color(0, 0, 0))
    .setFont(createFont("Arial Bold", 35));

  square=cp5.addButton("Square")
    .setFont(createFont("Arial Black", 20))
    .setPosition(x, y=65)
    .setSize(200, 75);

  sine=cp5.addButton("Sinusoid")
    .setFont(createFont("Arial Black", 20))
    .setPosition(x+275, y=65)
    .setSize(200, 75);


  stretchLen=cp5.addTextfield("stretch length (mm)")
    .setPosition(x=15, y+95)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setFont(createFont("Arial", 20))
    .setText("20")
    .setSize(100, 50)
    .setAutoClear(false);


  TimeA=cp5.addTextfield("time A")
    .setPosition(x, y = 270)
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
    .setPosition(x=15, y=410)
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
    .setSize(150, 60);

  run=cp5.addButton("Run")
    .setFont(createFont("Arial Black", 20))
    .setPosition(750, y=485)
    .setSize(200, 75)
    .setColorBackground(#FA0000)
    .setColorForeground(#FF7C80);

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
    .setFont(createFont("Arial Black", 20))
    .setPosition(500, y=485)
    .setSize(200, 75);


  //select user screen
  user1=cp5.addButton("user1")
    .setFont(createFont("Arial Black", 17))
    .setPosition(x=120, y=90)
    .setSize(200, 65);

  user2=cp5.addButton("user2")
    .setFont(createFont("Arial Black", 17))
    .setPosition(x+230, y)
    .setSize(200, 65);

  user3=cp5.addButton("user3")
    .setFont(createFont("Arial Black", 17))
    .setPosition(x+460, y)
    .setSize(200, 65);

  user4=cp5.addButton("user4")
    .setFont(createFont("Arial Black", 17))
    .setPosition(x+690, y)
    .setSize(200, 65);

  userBack=cp5.addButton("Back")
    .setFont(createFont("Arial Black", 20))
    .setPosition(20, 20)
    .setSize(125, 50);

  //run screen 
  x=485;
  pause=cp5.addButton("pause")
    .setFont(createFont("Arial Black", 20))
    .setPosition(x, 480)
    .setSize(150, 75);

  resume=cp5.addButton("resume")
    .setFont(createFont("Arial Black", 20))
    .setPosition(x+=175, 480)
    .setSize(150, 75);

  cancel=cp5.addButton("Cancel")
    .setFont(createFont("Arial Black", 20))
    .setPosition(x+=175, 480)
    .setSize(150, 75)
    .setColorBackground(#FA0000)
    .setColorForeground(#FF7C80);

  eStopAux=cp5.addButton("eStopAux")
    .setFont(createFont("Arial Black", 20))
    .setPosition(210, 460)
    .setSize(200, 75)
    .setLabel("Aux");

  eStopResume=cp5.addButton("eStopResume")
    .setFont(createFont("Arial Black", 20))
    .setPosition(600, 460)
    .setSize(200, 75)
    .setLabel("Resume");
  ;

  textFont(createFont("Arial", 16, true));

  //hide all CP5 elements buttons upon startup
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
  aux.hide();
  jogBak.hide();
  jogFwd.hide();
  tareButton.hide();
  startButton.hide();
}

int timerAdjust;
State lastCurrentState;
int lastIsAux;
int isAuxCounter;
boolean savedLastState=false;

boolean firstAux=false;
int displayEstopError=0;

boolean firstEstopAux=false;
void draw() { //----------------------------------------------------------------------------------------------------------------------------------------------- 
  if (!windowPosFlag) {
    surface.setLocation(0, -1);
    windowPosFlag=true;
  }

  //serial parsing
  while (serialPort.available()>0) {
    String myString = "";

    try {
      myString = serialPort.readStringUntil('\n');
    }
    catch (Exception e) {
    }

    if (myString == null) {
      return;
    }
    /*
    if (myString.contains("TARE")) {
     // This is a tare frame, empty the array and ignore it
     // Also ignore the next line with indices
     System.out.println("TARE");
     
     */
    // } else {


    // split the string at delimiter (space)
    String[] tempData = split(myString, '\t');   

    lastIsAux=isAuxTemp;
    // build the arrays for bar charts and line graphs
    if (tempData.length ==  10) {
      // This is a normal data frame
      // SPEED POSITION LOADCELL FEEDBACK_COUNT STATE ESTOP STALL DIRECTION INPUT_VOLTAGE BT_FWD BT_BAK BT_TARE BT_START BT_AUX and a space
      //lastIsAux=isAuxTemp;
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

    println(MMTKState+"     "+eStop+"     "+isAuxTemp+"     "+isAux);
    //checking if tare or aux has been pressed
    if (isTaredTemp==1) {
      isTared=1;
      tareButton.setColorBackground(#0ACB15);
      tareButton.setColorForeground(#5DFF5E);
      displayTareError=0;
    }
    if (isAuxTemp==1) {
      isAux=1;
      aux.setColorBackground(#0ACB15);
      aux.setColorForeground(#5DFF5E);
      displayAuxError=0;
      displayEstopError=0;
    } else if (isAuxTemp==0) {
      isAux=0;
    }


    //if mmtk sends that is is tared, transition to next state
    if (currentState == State.tare) {
      if (MMTKState == 0) {     //if mmtk is sending running state, transition to state 1
        currentState = State.getInput ;
      }
    }
    //}
  }

  //states: tare, userProfile, getInput, running, stopped
  //mmtk states: running, stopped, hold, jogFwd, jogBak, fastFwd, fastBak, noChange
  if (currentState!=State.tare&& eStop==1) {
    if (savedLastState==false) {
      lastCurrentState=currentState;  //save state before eStop
      savedLastState=true;
    }

    if (currentState==State.running||currentState==State.returnInitPos) {
      isPaused=true;
      pauseStart=millis();
    }
    currentState=State.stopped;
  }
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
      eStopAux.hide();
      eStopResume.hide();
      aux.show();
      jogFwd.show();
      jogBak.show();
      tareButton.show();
      startButton.show();

      resume.setColorBackground(#002b5c);    //resetting colours of running screen buttons
      pause.setColorBackground(#002b5c);


      fill(255, 255, 255);
      rect(25, 25, 970, 425);
      fill(0, 0, 0);
      textFont(createFont("Arial Bold", 50, true));
      textAlign(CENTER);
      text("Please Set Initial Position", 500, 90);
      textAlign(LEFT);
      textFont(createFont("Arial", 30, true));
      fill(#FF3B3B); //red
      text("1. Make sure EMERGENCY STOP button is released", 100, 170);
      fill(0, 0, 0);
      text("2. Press the AUX button ", 100, 220);
      text("3. Jog stretcher using the FORWARD and BACK jog buttons", 100, 270);
      text("4. Press the TARE button to set initial position", 100, 320);
      text("5. Press the READY button to ready stretcher for pattern input", 100, 370);

      if (MMTKState==1) {
        aux.setColorBackground(#002b5c);
        aux.setColorForeground(#4B70FF);
      }
      if (displayAuxError==1) {
        fill(#FF3B3B); //red
        textSize(15);
        text("ERROR: Please AUX button before JOGGING, TARE, or READY", 50, 410);
      }

      if (displayTareError==1) {
        fill(#FF3B3B); //red
        textSize(15);
        text("ERROR: Please AUX and TARE before READY", 50, 435);
      }

      if (displayEstopError==1) {
        fill(#FF3B3B); //red
        textSize(15);
        text("ERROR: Please release ESTOP before AUX", 600, 410);
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
      eStopAux.hide();
      eStopResume.hide();

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
      textFont(createFont("Arial Bold", 40, true));
      text("Select User", 400, 60);

      int y;
      textFont(createFont("Arial", 25, true));
      text("Wave: ", 12, y=195);
      text("Length: ", 12, y=y+45);
      text("Time A: ", 12, y=y+45);
      text("Time B: ", 12, y=y+45);
      text("Time C: ", 12, y=y+45);
      text("Time D: ", 12, y=y+45);
      text("Run Hrs: ", 12, y=y+45);
      text("Run Mins: ", 12, y=y+45);
      text("Run Secs: ", 12, y=y+45);

      String[] settings= {"wavePattern", "stretchLength", "timeA", "timeB", "timeC", "timeD", "hours", "mins", "secs"};
      String[] units={"", " mm", " s", " s", " s", " s", " hrs", " mins", " s"};    
      int[] xPositions={200, 430, 660, 890};

      //print(userSettings.getString(settings[2]+str(0)));

      for (int i=0; i<4; i++) {   //cycles through user
        y=145;
        for (int j=0; j<9; j++) {   //cycles through all settings of one user
          //user1 info
          if (j==0) {
            text(userSettings.getString(settings[j]+str(i))+units[j], xPositions[i], y=y+45);
          } else {
            text(float(userSettings.getString(settings[j]+str(i)))+units[j], xPositions[i], y=y+45);
          }
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
      eStopAux.hide();
      eStopResume.hide();

      if (loadedUser==true) {
        saveSettings.show();
        userName.show();
        if (displayedUser==false) {
          userName.setText(userSettings.getString("name"+userNumber));
          displayedUser=true;
        }
      }

      if (sinWave == 1) {
        // text("Sinusoid", 675, 400);
        sine.setColorBackground(#4B70FF); 
        square.setColorBackground(#002b5c);
        wavePattern = loadImage(topSketchPath+
          "/images/SinPattern.jpg");

        image(wavePattern, 505, 90, 500, 309);
      }

      if (squareWave == 1) {
        //text("Square", 675, 400);
        square.setColorBackground(#4B70FF); 
        sine.setColorBackground(#002b5c);
        wavePattern = loadImage(topSketchPath+
          "/images/SquarePattern.jpg");

        image(wavePattern, 505, 90, 500, 309);
      }
      textSize(30);
      fill(0, 0, 0); 
      text("Machine run time: ", 15, 395);

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

      break;
    }
  case running:
    {

      //sleep(100);   
      displayedUser=false;

      background(bgColor);
      //wipe last displayed timer off canvas
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
      userName.hide();
      saveSettings.hide();
      loadUser.hide();
      eStopAux.hide();
      eStopResume.hide();

      //keep track of seconds to adjust timer
      if (start==1 && millis()<endTime) {
        if (millis()>=nextSec&&isPaused==false) {
          timerAdjust=int(millis()-nextSec);
          nextSec=millis()+1000-timerAdjust;

          secs--;
          if (secs<0) {
            mins--;
            secs=59;
          }

          if (mins<0) {
            hours--;
            mins=59;
          }
        }

        //displaying timer 

        fill(255, 255, 255);
        rect(37, 380, 400, 175);//for settings
        rect(485, 380, 500, 80);//for timer

        fill(0, 0, 0);
        //for settings
        textAlign(LEFT);
        int x=45, y=405;
        textSize(20);
        if (sinWave==1) {
          text("Wave: "+"Sinusoid", x, y);
        } else if (squareWave==1) {
          text("Wave: "+"Square", x, y);
        }
        text("Len: "+float(stretchLen.getText())+" mm", x, y+=35);
        text("Run Hrs: "+float(Hours.getText())+" hrs", x, y+=35);
        text("Run Mins: "+float(Minutes.getText())+" mins", x, y+=35);
        text("Run Secs: "+float(Seconds.getText())+" s", x, y+=35);
        text("A: "+float(TimeA.getText())+" s", x=300, y=425);
        text("B: "+float(TimeB.getText())+" s", x, y+=35);
        text("C: "+float(TimeC.getText())+" s", x, y+=35);
        text("D: "+float(TimeD.getText())+" s", x, y+=35);

        textFont(createFont("Arial Bold", 55, true));
        if (hours>9) {
          text(hours+":", 610, 440);
        } else {
          text("0"+hours+":", 610, 440);
        }

        if (mins>9) {
          text(mins+":", 710, 440);
        } else {
          text("0"+mins+":", 710, 440);
        }

        if (secs>9) {
          text(secs, 810, 440);
        } else {
          text("0"+secs, 810, 440);
        }
        textFont(createFont("Arial", 55, true));


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
        int nextP = (int) nextPosition1;    //negative to flip direction
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
        pauseShift=0;
        isPaused=false;
        //serialPort.write("S");  //telling arduino to return to stop state
        //returnInitPosTime=millis()+4000;
        returnInitPosTime=(int)Math.ceil(millis()+(Math.abs(nextPosition1))/5)+500;  //+500 to leave enough time for arduino to send proper state
        //println("nextPos: "+nextPosition1);
        //println("stop time millis "+Math.ceil(millis()+(Math.abs(nextPosition1))/5));
        //println("pause time "+(Math.abs(nextPosition1))/5);
      }

      plot();
      stroke(0, 0, 0);
      strokeWeight(1);

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
      eStopAux.hide();
      eStopResume.hide();

      isTared=0;
      isAux=0;
      tareButton.setColorBackground(#002b5c);
      tareButton.setColorForeground(#4B70FF);
      aux.setColorBackground(#002b5c);
      aux.setColorForeground(#4B70FF);

      //resetting plot
      Arrays.fill(XYplotFloatData[0], 0);
      Arrays.fill(XYplotFloatData[1], 0);
      Arrays.fill(XYplotFloatData[2], 0);
      Arrays.fill(XYplotFloatData[3], 0);
      Arrays.fill(XYplotFloatData[4], 0);
      XYplotCurrentSize=0;
      clearPlotCounter=1;

      plotSetup=0;

      textAlign(LEFT);
      fill(0, 0, 0);
      textFont(createFont("Arial Bold", 55, true));
      text("Please Wait...", 300, 250);

      nextPosition1=0;  //making sure last run's 'nextPosition1' value gets reset
      if (millis()<returnInitPosTime) {
        int nextP =0;   //moving back to initial position so sample can be removed
        float nextV = 500;
        String printthis = "p" + nextP + "\nv" + nextV + "\n";
        serialPort.write(printthis);
        System.out.println(printthis);
        StateTransitionPause=millis()+100;
      } else {
        //print(pauseTime);
        //sleep(4000);
        //serialPort.write("S");
        if (millis()>StateTransitionPause) {   //making sure arduino has time to change state before processing
          serialPort.write("B"); 

          //sending to hold state momentarily so machine will not skip past tare screen
          if (millis()>StateTransitionPause+100) {//more delay to make sure arduino state has transitioned before UI is set to tare state (to prevent occasional skipping of UI tare state)
            currentState=State.tare;
          }
        }
      }
      break;
    }
  case stopped:
    {
      background(bgColor);
      //hide everything
      user1.hide();
      user2.hide();
      user3.hide();
      user4.hide();
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
      aux.hide();
      jogFwd.hide();
      jogBak.hide();
      tareButton.hide();
      startButton.hide();
      userBack.hide();

      eStopAux.show();
      eStopResume.show();

      fill(255, 255, 255);
      rect(25, 25, 970, 400);
      fill(0,0,0); //red
      textFont(createFont("Arial Bold", 55, true));
      textAlign(CENTER);
      text("eStop Pressed", 500, 100);
      textAlign(LEFT);
      textFont(createFont("Arial ", 30, true));
 
      fill(#FF3B3B); //red
      text("1. Release THE EMERGENCY STOP button WHEN SAFE", 100, 200);
      fill(0, 0, 0);
      text("2. Press the AUX button ", 100, 250);
      text("3. Press the RESUME button to pick up where you left off", 100, 300);

      if (isAux==1) {
        eStopAux.setColorBackground(#0ACB15);
        eStopAux.setColorForeground(#5DFF5E);
      } else {
        eStopAux.setColorBackground(#002b5c);
        eStopAux.setColorForeground(#4B70FF);
      }

      if (displayAuxError==1) {
        fill(#FF3B3B); //red
        textSize(15);
        text("ERROR: Please AUX button before RESUME", 50, 375);
      }

      if (displayEstopError==1) {
        fill(#FF3B3B); //red
        textSize(15);
        text("ERROR: Please release ESTOP before AUX", 50, 400);
      }
      break;
    }
  }
}
import java.util.Arrays;

//=======PLOTTING!!!===================================================================
// Generate the plot
int[] XYplotFloatDataDims = {5, 10000};
int[] XYplotIntDataDims = {5, 10000};

// XY Plot
int[] XYplotOrigin = {133, 80};
int[] XYplotSize = {800, 230};
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

  // update the data buffer
  XYplotFloatData[0][XYplotCurrentSize] = velocity;
  XYplotFloatData[1][XYplotCurrentSize] = position;
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

  XYplotCurrentSize ++;

  // Copy data to plot into new array for plotting
  float[] plotTime = Arrays.copyOfRange(XYplotFloatData[3], 0, XYplotCurrentSize);
  float[] plotDisplacement = Arrays.copyOfRange(XYplotFloatData[1], 0, XYplotCurrentSize);
  float[] plotNewDisplacement = Arrays.copyOfRange(XYplotFloatData[4], 0, XYplotCurrentSize);

  // check if graph need to expand
  //if ( maxDisplacment > XYplot.xMax || maxForce > XYplot.xMin ) {
  if (plotTime[plotTime.length-1] > XYplot.xMax ) {
    Arrays.fill(XYplotFloatData[0], 0);
    Arrays.fill(XYplotFloatData[1], 0);
    Arrays.fill(XYplotFloatData[2], 0);
    Arrays.fill(XYplotFloatData[3], 0);
    Arrays.fill(XYplotFloatData[4], 0);
    XYplotCurrentSize=0;


    XYplot.xMin=XYplot.xMax;  
    XYplot.xMax=((timeA+timeB+timeC+timeD)/1000)*periodsDisplayed*clearPlotCounter; 
    clearPlotCounter++;
  }

  // draw the line graphs
  XYplot.DrawAxis();
  XYplot.DotXY(plotTime, plotDisplacement);
  XYplot.GraphColor = color(200, 20, 20);
  XYplot.GraphColor = XYplotColor;
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
    errors.add("ERROR: Input(s) contain invalid characters");
  }
}

void getUserSettings(int userNumber) {

  Hours.setText(str(userSettings.getFloat("hours"+userNumber)));
  Minutes.setText(str(userSettings.getFloat("mins"+userNumber)));
  Seconds.setText(str(userSettings.getFloat("secs"+userNumber)));
  stretchLen.setText(str(userSettings.getFloat("stretchLength"+userNumber)));
  TimeA.setText(str(userSettings.getFloat("timeA"+userNumber)));
  TimeB.setText(str(userSettings.getFloat("timeB"+userNumber)));
  TimeC.setText(str(userSettings.getFloat("timeC"+userNumber)));
  TimeD.setText(str(userSettings.getFloat("timeD"+userNumber)));

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

        runTime=hours*3600 +mins*60 +secs;  //in seconds
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
      if (isPaused==true) {
        isPaused=false;
        //pauseFin=millis();
        //endTime=endTime+(pauseFin-pauseStart);   //readjust endTime
        //pauseShift+=(pauseFin-pauseStart);
        //nextSec+=pauseFin-pauseStart;

        //resume.setColorBackground(#4B70FF); 
        //pause.setColorBackground(#002b5c);
      }

      currentState=State.returnInitPos;
      endTime=999999999;
      start=0;
      pauseShift=0;
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
      if (isPaused==true) {
        isPaused=false;
        pauseFin=millis();
        endTime=endTime+(pauseFin-pauseStart);   //readjust endTime
        pauseShift+=(pauseFin-pauseStart);
        nextSec+=pauseFin-pauseStart;

        resume.setColorBackground(#4B70FF); 
        pause.setColorBackground(#002b5c);
      }
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
      saveJSONObject(userSettings, topSketchPath+"/users.json");
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
      if (firstAux==true&& eStop==1) {
        displayEstopError=1;
      }
      firstAux=true;
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
      if (isAux==1) {
        serialPort.write("T");
      } else {
        displayAuxError=1;
      }
    }

    if (parameter=="Ready") {
      if (isTared==1 && isAux==1) {
        serialPort.write("R");
      } else {
        displayTareError=1;
      }
    }

    if (parameter=="eStopAux") {
      if (firstEstopAux==true&& eStop==1) {
        displayEstopError=1;
      }
      firstEstopAux=true;
      serialPort.write("A");
    }
    if (parameter=="eStopResume") {
      if (isAux==1) {
        serialPort.write("R");
        currentState=lastCurrentState;
        eStopAux.setColorBackground(#002b5c);
        eStopAux.setColorForeground(#4B70FF);
        savedLastState=false;
        if (currentState==State.running||currentState==State.returnInitPos) {
          if (isPaused==true) {
            isPaused=false;
            pauseFin=millis();
            endTime=endTime+(pauseFin-pauseStart);   //readjust endTime
            pauseShift+=(pauseFin-pauseStart);
            nextSec+=pauseFin-pauseStart;
            returnInitPosTime+=pauseFin-pauseStart;
          }
        }
      } else {
        displayAuxError=1;
      }
    }
  }
}
