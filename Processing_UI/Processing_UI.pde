//import libraries
//import java.awt.Frame;
//import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;
//import java.util.Arrays;
//import javax.swing.JOptionPane;
import java.lang.Math.*;


PFont buttonTitle_f, mmtkState_f, indicatorTitle_f, indicatorNumbers_f;

// If you want to debug the plotter without using a real serial port set this to true
boolean mockupSerial = false;

// Serial Setup
String serialPortName;
Serial serialPort;  // Create object from Serial class

// interface stuff
ControlP5 cp5;
//ControlFrame cf;

// Settings for MMUK UI are stored in this config file
JSONObject mmtkUIConfig;

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


Textfield stretchLen, TimeA, TimeB, TimeC, TimeD, Hours, Minutes, Seconds;
Button sine, square, run;
Textlabel label;

int start=0;
long runTime=0;
long endTime=999999999;
//int gotEndTime=0;
int state=0;
long nextSec;
int tempCounter=0;
int hours;
int mins;
int secs;

// Pattern image
PImage wavePattern;

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
    .setPosition(x=15, y=5)
    .setColorValue(color(0, 0, 0))
    .setFont(createFont("Arial", 22));

  square=cp5.addButton("Square")
    //.setValue(1)
    .setFont(createFont("Arial Black", 10))
    .setPosition(x, y=50)
    .setSize(100, 25);

  sine=cp5.addButton("Sinusoid")
    //.setValue(1)
    .setFont(createFont("Arial Black", 10))
    .setPosition(x+150, y=50)
    .setSize(100, 25);

  //println(sinWave);
  //println(squareWave);
  //sleep(2000);

  stretchLen=cp5.addTextfield("stretch length (mm)")
    .setPosition(x=15, y+80)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setFont(createFont("Arial", 14))
    .setText("20")
    .setSize(100, 30)
    .setAutoClear(false);

  run=cp5.addButton("Run")
    //.setValue(1)
    .setFont(createFont("Arial Black", 10))
    .setPosition(x+190, y+80)
    .setSize(100, 50);

  TimeA=cp5.addTextfield("time A")
    .setPosition(x, y = 195)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(68, 114, 196))
    .setColorBackground(color(68, 114, 196))
    .setFont(createFont("Arial", 14))
    .setText("5.0")
    .setSize(50, 30)
    .setAutoClear(false);

  TimeB=cp5.addTextfield("time B")
    .setPosition(x+80, y)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(237, 125, 49))
    .setColorBackground(color(237, 125, 49))
    .setFont(createFont("Arial", 14))
    .setText("2.0")
    .setSize(50, 30)
    .setAutoClear(false);

  TimeC=cp5.addTextfield("time C")
    .setPosition(x+160, y)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(255, 192, 0))
    .setColorBackground(color(255, 192, 0))
    .setFont(createFont("Arial", 14))
    .setText("5.0")
    .setSize(50, 30)
    .setAutoClear(false);

  TimeD=cp5.addTextfield("time D")
    .setPosition(x+240, y)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(112, 173, 71))
    .setColorBackground(color(112, 173, 71))
    .setFont(createFont("Arial", 14))
    .setText("2.0")
    .setSize(50, 30)
    .setAutoClear(false);

  Hours=cp5.addTextfield("Hour")
    .setPosition(x=15, y=285)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setFont(createFont("Arial", 14))
    .setText("0")
    .setSize(50, 30)
    .setAutoClear(false);

  Minutes=cp5.addTextfield("Min")
    .setPosition(x+80, y)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setFont(createFont("Arial", 14))
    .setText("0")
    .setSize(50, 30)
    .setAutoClear(false);

  Seconds=cp5.addTextfield("Sec")
    .setPosition(x+160, y)
    .setColorValue(color(0, 0, 0))
    .setColorCursor(color(0, 0, 0))
    .setColorLabel(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setFont(createFont("Arial", 14))
    .setText("0")
    .setSize(50, 30)
    .setAutoClear(false);

  textFont(createFont("Arial", 16, true));
}

void draw() { //----------------------------------------------------------------------------------------------------------------------------------------------- 
  if (serialPort.available()>0) {
    //String incomingVal=serialPort.readStringUntil('\n');
    char incomingVal=serialPort.readChar();
    println();
    print(incomingVal);
    // println("Tare");
    //println(incomingVal.equals("Tare"));
    if (incomingVal=='S') {
      //println(state); 
      state=1; 
      //println(state);
    }
  }
  if (state==0) {
    background(#CE8787);
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

    int nextP =0;   //moving back to initial position
    float nextV = 200;
    String printthis = "p" + nextP + "\nv" + nextV + "\n";
    serialPort.write(printthis);
    //System.out.println(printthis);
    
    fill(0, 0, 0);
    textSize(50);
    text("Please Set Initial Position", 155, 135);
    textSize(30);
    text("1. Press AUX button until red LED disappears", 100, 250);
    text("2. Jog stretcher using FORWARD and BACK jog buttons", 100, 300);
    text("3. Press TARE button to set initial position", 100, 350);
    text("4. Press START button to ready stretcher for pattern input", 100, 400);
    
  } else if (state==1) {

    background(bgColor);
    textSize(16);
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
    //text("Current Speed: " + String.format("%.02f", mmtkVel) + " mm/min", 125, 70);
    text("Wave Form: ", 15, 100);

    if (sinWave == 1) {
      text("Sinusoid", 105, 100);
      wavePattern = loadImage(//topSketchPath+
        "/images/SinPattern.jpg");

      image(wavePattern, 350, 50, 293, 181);
    }

    if (squareWave == 1) {
      text("Square", 105, 100);
      wavePattern = loadImage(//topSketchPath+
        "/images/SquarePattern.jpg");

      image(wavePattern, 350, 50, 293, 181);
    }

    text("Machine run time: ", 15, 270);

    stretchL = float(stretchLen.getText())*1000;
    timeA = float(TimeA.getText())*1000;
    timeB = float(TimeB.getText())*1000;
    timeC = float(TimeC.getText())*1000;
    timeD = float(TimeD.getText())*1000;
    cycleT = (timeA + timeB + timeC + timeD);

    //println(start);
    //sleep(2000);
  } else if (state==2) {
    background(#18C452);
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
    
    if (start==1 && millis()<endTime) {
      if(millis()>=nextSec){
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
      currentT = millis();
      runT = (currentT - startT);
      roundN = Math.floor(runT/cycleT);
      cycleN = (int) roundN;
      currentt = (float) (runT - cycleN*cycleT);

      if (squareWave == 1) {
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
      /*
    if (sinWave == 1) {
       if (currentt <= timeA) {
       nextPosition1 = (Math.sin(currentt/timeA * Math.PI-Math.PI*0.5)+1)*0.5*stretchL;
       float nextt = currentt + currentt - lastt;   //nextt for calculating velocity
       //double nextVel0 = Math.max(60*Math.cos(currentt/timeA * Math.PI - Math.PI/2)*Math.PI*stretchL/(2*timeA), 10);
       double nextVel2 = Math.max(60*Math.cos(currentt/timeA * Math.PI - Math.PI/2)*Math.PI*stretchL/(2*timeA), 100);
       nextVel1 = nextVel2;
       } else if (currentt > timeA && currentt < (timeA + timeB)) {
       nextPosition1 = stretchL;
       nextVel1 = stretchL/timeA*60;
       } else if (currentt >= (timeA+timeB) && currentt <= (timeA+timeB+timeC)) {
       currentt = currentt - timeA - timeB;
       nextPosition1 = (Math.sin(currentt/timeC * Math.PI+Math.PI*0.5)+1)*0.5*stretchL;
       nextVel1 = Math.max (Math.abs(60*Math.cos(currentt/timeC * Math.PI + Math.PI*0.5)*Math.PI*stretchL/(2*timeC)), 100);
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
       */
      if (sinWave == 1) {
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
    if (millis()>endTime) {
      //gotEndTime=0;
      state=0;
      endTime=999999999;
      start=0;
    }
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
    /*
    if (parameter == "stretch length (mm)") {
     stretchL = float(stretchLen.getText())*1000;
     }
     
     if (parameter == "time A") {
     timeA = float(TimeA.getText())*1000;
     }
     
     if (parameter == "time B") {
     timeB = float(TimeB.getText())*1000;
     }
     
     if (parameter == "time C") {
     timeC = float(TimeC.getText())*1000;
     }
     
     if (parameter == "time D") {
     timeD = float(TimeD.getText())*1000;
     }
     
     cycleT = (timeA + timeB + timeC + timeD);
     */
    if (parameter == "Run") {
      //patternReady = 1;
      println("run pressed");
      // sleep(1000);
      start=1;
      state=2;
      //nextPosition=0;
      //nextPosition1=0;
      //nextVel=0;
      //nextVel1=0;
      startT=millis();
      // startT = millis();
      //if (gotEndTime==0) {
        hours=int(Hours.getText());
        mins=int(Minutes.getText());
        secs=int(Seconds.getText());
        
        runTime=hours*1200 +mins*60 +secs;  //in seconds
        //println(runTime);
        endTime=millis()+runTime*1000;
        //println(endTime);
        nextSec=millis()+1000;
       // gotEndTime=1;
        //start=1;
      //}
    }

    if (parameter == "Square") {
      squareWave = 1;
      sinWave = 0;
    }

    if (parameter == "Sinusoid") {
      sinWave = 1;
      squareWave = 0;
    }


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
  }
}
//}

/* for seth - creating a new wave: procedure
 1. find function of desired pattern: x(t)=.... assign x=nextPosition, t=currentT
 2. find velocity (nextVel) function of pattern: v(t)= x'(t) <-take derivative of x(t), you can use symbolab.com calculator if you haven't learned calculus yet
 see EXAMPLE below for steps 1 and 2
 
 3. pass nextPosition and nextVel to arduino via serial port:
 serialPort.write("p"+nextPosition+"\nv"+nextVel+"\n");
 */
