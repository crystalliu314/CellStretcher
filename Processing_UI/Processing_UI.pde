//import libraries
import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;
import java.util.Arrays;
import javax.swing.JOptionPane;
import java.lang.Math.*;
import processing.serial.*;

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

int XYplotCurrentSize = 0;

int patternReady = 0;
int squareWave = 0;
int sinWave = 1;
int startT = 0;
int currentT = 0;
float runT = 0;
int cycleN = 0;
double roundN = 0;

float mmtkVel = 50.0;
int bgColor = 200;
float stretchL = 20000;
float timeA = 5000;
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


void setup() {
  serialPort = new Serial(this, "COM4", 19200);
  cycleT = (timeA + timeB + timeC + timeD);
}

void draw(){  
  lastt = currentt;
  currentT = millis();
  runT = (currentT - startT);
  roundN = Math.floor(runT/cycleT);
  cycleN = (int) roundN;
  currentt = (float) (runT - cycleN*cycleT);


  /* for seth - creating a new wave: procedure
  1. find function of desired pattern: x(t)=.... assign x=nextPosition, t=currentT
  2. find velocity (nextVel) function of pattern: v(t)= x'(t) <-take derivative of x(t), you can use symbolab.com calculator if you haven't learned calculus yet
      see EXAMPLE below for steps 1 and 2
      
  3. pass nextPosition and nextVel to arduino via serial port:
      serialPort.write("p"+nextPosition+"\nv"+nextVel+"\n");
  */
  
  
  
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

  if (sinWave == 1) {
    if (currentt <= timeA) {
      nextPosition1 = (Math.sin(currentt/timeA * Math.PI-Math.PI*0.5)+1)*0.5*stretchL;
      float nextt = currentt + currentt - lastt;
      //double nextVel0 = Math.max(60*Math.cos(currentt/timeA * Math.PI - Math.PI/2)*Math.PI*stretchL/(2*timeA), 10);
      double nextVel2 = Math.max(60*Math.cos(nextt/timeA * Math.PI - Math.PI/2)*Math.PI*stretchL/(2*timeA), 10);
      nextVel1 = nextVel2;
    } else if (currentt > timeA && currentt < (timeA + timeB)) {
      nextPosition1 = stretchL;
      nextVel1 = stretchL/timeA*60;
    } else if (currentt >= (timeA+timeB) && currentt <= (timeA+timeB+timeC)) {
      currentt = currentt - timeA - timeB;
      nextPosition1 = (Math.sin(currentt/timeC * Math.PI+Math.PI*0.5)+1)*0.5*stretchL;
      nextVel1 = Math.max (Math.abs(60*Math.cos(currentt/timeC * Math.PI + Math.PI*0.5)*Math.PI*stretchL/(2*timeC)), 10);
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

  //sendData = 0;
  
}
