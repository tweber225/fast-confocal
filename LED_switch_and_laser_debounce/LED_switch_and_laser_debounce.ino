/* 
  Widefield LED Channel Switch and Laser Modulation Debouncer
  Timothy D. Weber, BU Biomicroscopy Lab, 2020

  The program solves two issues:
    1. "Debounces" a high duty rate frameclock signal to provide a continuous ON digital signal for laser modulation
    2. With an electrically shorting push button, switch between three different LED modes/channels. 
    Modes are 1) All OFF (when laser is active), 2) Epi-illumination widefield fluorescence, 3) Oblique transillumination mode
  
  History:
  Version 1.0: 9 Nov. 2020
  
 */



// Include the fast digital read/write library
#include "digitalWriteFast.h"

// set up constant parameters
const int laserDebounceTimeUs = 100; // time in microseconds to wait to debounce frameclock
const int switchDebounceTimeMs = 10;  // time in milliseconds for switch button debouncing

// Inputs
const int switchPin = 0;
const int frameClkPin = 5;

// Outputs
const int epiLEDPin = 2;
const int transLEDPin = 3;
const int laserModPin = 6;

const int blinkPin = 13;


// set up some state variables
boolean currentSwitch = HIGH;
boolean previousSwitch = HIGH;

boolean currentFrameClk = LOW;
boolean previousFrameClk = LOW;

int currentLEDMode = 0;


void setup() {
  // Input signals
  pinModeFast(switchPin, INPUT);
  pinModeFast(frameClkPin, INPUT);

  // Output signals
  pinModeFast(blinkPin, OUTPUT);
  pinModeFast(epiLEDPin, OUTPUT);
  pinModeFast(laserModPin, OUTPUT);
  pinModeFast(transLEDPin, OUTPUT);

}

void loop() {
  
  // Check ScanImage frame clock
  currentFrameClk = digitalReadFast(frameClkPin);

  if (currentFrameClk == HIGH) {
    if (previousFrameClk == LOW) {
      // UP edge received, turn on laser immediately
      digitalWriteFast(laserModPin,HIGH);
    } // Otherwise, frame clock is HIGH, but also was HIGH last loop cycle
  }
  else {
    // Frame clock is LOW
    if (previousFrameClk == HIGH) {
      // DOWN edge received, wait some time before checking again
      delayMicroseconds(laserDebounceTimeUs);

      // If it is still low after the debounce time, then we can be sure the acquisition has ended
      if (digitalReadFast(frameClkPin) == LOW) {
        digitalWriteFast(laserModPin,LOW);
      }
    }
  }
  
  
  // Get status of switch button
  currentSwitch = digitalReadFast(switchPin);

  if (currentSwitch == LOW) {
    // Check whether last iteration was also LOW
    if (previousSwitch == HIGH) {
      // This is a DOWN edge

      // Debounce: wait some time and recheck
      delay(switchDebounceTimeMs);

      // If it is still LOW, then this is a valid switch button use
      if (digitalReadFast(switchPin) == LOW) {

        // Increment LED mode
        currentLEDMode = (currentLEDMode+1) % 3; // modulo 3 for the 3 modes
  
        // Switch modes
        // Laser Mode
        if (currentLEDMode == 0) {
          digitalWriteFast(blinkPin,HIGH);
          digitalWriteFast(epiLEDPin,LOW);
          digitalWriteFast(transLEDPin,LOW);
        }
        // Epi-illumination Widefield Fluorescence Mode
        else if (currentLEDMode == 1) {
          digitalWriteFast(blinkPin,LOW);
          digitalWriteFast(epiLEDPin,HIGH);
          digitalWriteFast(transLEDPin,LOW);
        }
        // Oblique Transillumination Mode
        else if (currentLEDMode == 2) {
          digitalWriteFast(blinkPin,LOW);
          digitalWriteFast(epiLEDPin,LOW);
          digitalWriteFast(transLEDPin,HIGH);
        }

      }
      
    }

  }
  

  // At the end of loop, update previous state variables
  previousFrameClk = currentFrameClk;
  previousSwitch = currentSwitch;
  
}
