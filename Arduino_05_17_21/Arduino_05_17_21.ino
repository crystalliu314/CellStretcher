#include <AccelStepper.h>
#include <Stepper.h>

//constants
#define MECH_MM_PER_REV 5
#define MECH_STEP_PER_REV 1600

//motor pin config
#define DRIVER_DIR 8
#define DRIVER_PUL 9

//calibration button pin config
#define TARE_BUTTON 4

//E-stop pin configs
#define ESTOP_BUTTON 2   //exteral interrupt 
#define ESTOP_LED 5

//Jog buttons pin config
#define FWD_JOG_BUTTON 7
#define BAK_JOG_BUTTON 6

//user inputs
int waveSelect;  //1=sin, 2=triangle, 3=square, 4=ramp
float amplitude;  //mm
float periodInSeconds;  //seconds
float runTime; //seconds, change to long?? (may expand functionality to include hours and minutes)

//calculated variable initializations
int moveToPosition;
//for sine
float max_Speed;
float acceleration;
//for triangle
float speedTriangle;

//for runtime
float endTime;  // change to long?? 

//creating motor objects
AccelStepper motor(1, DRIVER_PUL, DRIVER_DIR);
//Stepper motor1(2084, MOTOR_PIN1, MOTOR_PIN3, MOTOR_PIN2, MOTOR_PIN4);

//additional function definitions------------------------------------------------------------
void EStop(){
  digitalWrite(ESTOP_LED, HIGH);
  while(true){}  //stall
}

float Stop() {
  long pauseMoment = millis();
  long pauseEnd;
  while (true) {
    //pause timer:
    pauseEnd = millis();
    //look for serial input for start to resume stretch
    if (Serial.available() > 0) {
      //look for resume press
      String incomingVal = Serial.readStringUntil('\n');
      if (incomingVal == "resume")return endTime+(pauseEnd-pauseMoment);
    }
  }
}

  void tarePosition() {
    bool TareIsPressed = false;
    int pulsePause = 100;
    while (TareIsPressed == false) {
      if (digitalRead(FWD_JOG_BUTTON) == LOW) {  //jog forward
        digitalWrite(DRIVER_DIR, HIGH);
        digitalWrite(DRIVER_PUL, HIGH);
        delayMicroseconds(pulsePause);
        digitalWrite(DRIVER_PUL, LOW);
        delayMicroseconds(pulsePause);
      }
      if (digitalRead(BAK_JOG_BUTTON) == LOW) {
        digitalWrite(DRIVER_DIR, LOW);
        digitalWrite(DRIVER_PUL, HIGH);
        delayMicroseconds(pulsePause);
        digitalWrite(DRIVER_PUL, LOW);
        delayMicroseconds(pulsePause);

      }
      if (digitalRead(TARE_BUTTON) == LOW) {
        TareIsPressed = true;
        motor.setCurrentPosition(0);
        //Serial.println("Tare");//trouble recieving strings in processing
        Serial.println('T');
      }
    }
  }

  void getInputs() {
    //Send signal to processing to get user inputs
    //Serial.println("getInputs");

    for (int i = 0; i < 4; i++) {
      while (Serial.available() == 0) {}
      int incomingByte = Serial.read();

      if (incomingByte == 'w' || incomingByte == 'W') {
        String incomingWave = Serial.readStringUntil('\n');
        if (incomingWave == "triangle") waveSelect = 2;
        if (incomingWave == "sine") waveSelect = 1;
        //add other modes
      }

      //while (Serial.available() == 0) {}
      if (incomingByte == 'a' || incomingByte == 'A') {
        amplitude = Serial.parseFloat();
      }
      //while (Serial.available() == 0) {}
      if (incomingByte == 'p' || incomingByte == 'P') {
        periodInSeconds = Serial.parseFloat();
      }
      //while (Serial.available() == 0) {}
      if (incomingByte == 't' || incomingByte == 'T') {
        runTime = Serial.parseFloat();
      }
    }
  }

  void performCalcs() {
    //calc how many steps for set wave height (2*amplitude)
    moveToPosition = round((2 * amplitude * MECH_STEP_PER_REV) / (MECH_MM_PER_REV)) + 1; //+1 to compensate for missed step during "if (motor.distanceToGo() == 0)"

    //calcs for "sine" pattern
    max_Speed = 8 * amplitude * MECH_STEP_PER_REV / ((periodInSeconds) * MECH_MM_PER_REV);
    acceleration = (32 * amplitude * MECH_STEP_PER_REV) / (pow(periodInSeconds, 2) * MECH_MM_PER_REV);

    //calcs for triangle pattern
    //speedTriangle = 48 * amplitude / periodInSeconds;   //using stepper libarary
    speedTriangle = (4 * amplitude * MECH_STEP_PER_REV) / (periodInSeconds * MECH_MM_PER_REV); //using accel stepper library
  }
  //-------------------------------------------------------------------------------------------
  void setup() {
    Serial.begin(9600);

    attachInterrupt(digitalPinToInterrupt(ESTOP_BUTTON), EStop, FALLING);   //E stop interrupt on falling edge of button press

    pinMode(TARE_BUTTON, INPUT_PULLUP);  //not pressed=high, pressed=low

    pinMode(ESTOP_BUTTON, INPUT_PULLUP);  //not pressed=high, pressed=low
    pinMode(ESTOP_LED, OUTPUT);  //not pressed=high, pressed=low

    pinMode(FWD_JOG_BUTTON, INPUT_PULLUP);
    pinMode(BAK_JOG_BUTTON, INPUT_PULLUP);

    pinMode(DRIVER_DIR, OUTPUT);
    pinMode(DRIVER_PUL, OUTPUT);
  }

  //-------------------------------------------------------------------------------------------
  void loop() {
    tarePosition();  //callibrate for initial position
    getInputs(); //get user inputs via serial port
    Serial.println(waveSelect);
    Serial.println(amplitude);
    Serial.println(periodInSeconds);
    Serial.println(runTime);
    performCalcs();  //perform required calculations for movements

    //this marks the "start" of the timer, calculate when timer should end
    //Serial.println(millis());
    endTime = millis() + (runTime * 1000);
    //Serial.println(endTime);

    //sin
    if (waveSelect == 1) {     //sine wave
      //Serial.println("entered sine");
      motor.setMaxSpeed(max_Speed);
      motor.setAcceleration(acceleration);
      motor.moveTo(moveToPosition / 2);

      while (millis() != endTime) {
        //looking for pause
        if (Serial.available() > 0) {
          String incomingVal = Serial.readStringUntil('\n');
          if (incomingVal == "pause"){
            endTime=Stop();
          }
        }
        
        if (motor.distanceToGo() == 0) {
          moveToPosition = -moveToPosition;
          motor.setCurrentPosition(0);
          motor.moveTo(moveToPosition);
        }
        //long currentPos=motor.currentPosition();
        //Serial.println(currentPos);
        motor.run();
      }
    } else if (waveSelect == 2) {    //triangle wave
      /*
        //using stepper library  (blocks while moving, not preferred)
        motor1.setSpeed(speedTriangle);  //change speedTriangle to RPM!!!
        motor1.step(moveToPosition/2);
        while (true) {
        motor1.step(-moveToPosition);
        motor1.step(moveToPosition);
        }
      */

      //using accel stepper library (non-blocking)
      //speedTriangle=300;
      motor.setMaxSpeed(speedTriangle);
      motor.moveTo(moveToPosition / 2);
      motor.setSpeed(speedTriangle);

      while (millis() != endTime) {
        //looking for pause
        if (Serial.available() > 0) {
          String incomingVal = Serial.readStringUntil('\n');
          if (incomingVal == "pause"){
            endTime=Stop();
          }
        }
        
        if (motor.distanceToGo() == 0) {
          motor.stop();
          moveToPosition = -moveToPosition;
          speedTriangle = -speedTriangle;
          motor.setCurrentPosition(0);

          motor.setMaxSpeed(speedTriangle);
          motor.moveTo(moveToPosition);
          motor.setSpeed(speedTriangle);
        }
        //long currentPos=motor.currentPosition();
        //Serial.println(currentPos);
        motor.runSpeed();
      }
    }
    Serial.println("D");  //D as in Done
    //button test
    /*
      int sensorVal = digitalRead(2);
      Serial.println(sensorVal);
    */
  }
  //EXTRAS

  /*
    //calcs for "square" pattern   //problematic
    float RPM = 15.0; //has to be as quick as possible, approx 19rmp is fastest speed of 28BYJ84
    float eachDelay = (periodInSeconds-2*(moveToPosition/(RPM*MECH_STEP_PER_REV*60)))/2;   //travelTime = moveToPosition/(RPM*MECH_STEP_PER_REV);
  */


  /*   OTHER WAVE PTTERNS
    } else if (waveSelect == 3) {    //square wave   //problematic
      motor1.setSpeed(RPM);

      //for (int fakeTimer; fakeTimer < 10; fakeTimer++) {
      while(true){
        motor1.step(moveToPosition);
        delay(eachDelay*1000);
        motor1.step(-moveToPosition);
        delay(eachDelay*1000);
      }
    } else if (waveSelect == 4) {    //ramp wave  (problematic)
      //using stepper library
      //for (int fakeTimer; fakeTimer < 10; fakeTimer++) {
      while(true){
        motor1.setSpeed(10);
        motor1.step(moveToPosition);
        motor1.setSpeed(17);
        motor1.step(-moveToPosition);
      }
    }
  */
