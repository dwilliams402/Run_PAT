#include <heartRate.h>
#include <MAX30105.h>
#include <spo2_algorithm.h>

#include <Wire.h>

//EDIT THESE VALUES FOR YOUR OWN PURPOSES
const uint8_t arduino_analog_pin = A0;

//DO NOT EDIT THESE VALUES UNLESS YOU KNOW WHAT YOU ARE DOING
const uint32_t baudrate = 250000;

MAX30105 particleSensor;

void setup()
{
  InitializeADCSettings();
  BasicSetup();
  PulseOxSetup();
}

void loop()
{
    int now = millis();
    // Serial.print(String(analogRead(arduino_analog_pin)) + "," + String(particleSensor.getIR()) + "," + String(millis()) + "\n"); //Send raw data
    Serial.print(String(particleSensor.getIR()) + "\n"); //Send raw data
}

void BasicSetup()
{
  Serial.begin(baudrate);
}

void PulseOxSetup()
{
  // Initialize sensor
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) //Use default I2C port, 400kHz speed
  {
    Serial.println("MAX30105 was not found. Please check wiring/power. ");
    while (1);
  }

  //Setup to sense a nice looking saw tooth on the plotter
  byte ledBrightness = 0x1F; //Options: 0=Off to 255=50mA
  byte sampleAverage = 1; //Options: 1, 2, 4, 8, 16, 32
  byte ledMode = 3; //Options: 1 = Red only, 2 = Red + IR, 3 = Red + IR + Green
  int sampleRate = 1000; //Options: 50, 100, 200, 400, 800, 1000, 1600, 3200
  int pulseWidth = 411; //Options: 69, 118, 215, 411
  int adcRange = 2048; //Options: 2048, 4096, 8192, 16384

  particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange); //Configure sensor with these settings
}

// ADC Setup
void InitializeADCSettings()
{
  // Disable global interrupts
  cli();
 
  // Set the Prescaler (16000KHz/128 = 125KHz)
  // Above 200KHz 10-bit results are not reliable.
  // About 8-bit resolution up to 1MHz (Prescaler = 16)
  //ADCSRA |= bit (ADPS0);                               //   2  No precision
  //ADCSRA |= bit (ADPS1);                               //   4  No precision
  //ADCSRA |= bit (ADPS0) | bit (ADPS1);                 //   8  Low precision
  //ADCSRA |= bit (ADPS2);                               //  16  Okay precision  (up to 77K conversions/s)
  ADCSRA |= bit (ADPS0) | bit (ADPS2);                 //  32 Good precision (up to 38.5K conversions/s)
  //ADCSRA |= bit (ADPS1) | bit (ADPS2);                 //  64 Good precision (up to 19.2K conversions/s)
  //ADCSRA |= bit (ADPS0) | bit (ADPS1) | bit (ADPS2);   // 128 Most precision (up to 9.6K conversions/s)
  
  // Enable global interrupts
  sei();
}
