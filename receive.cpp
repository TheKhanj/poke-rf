#include "RCSwitch.h"
#include <Arduino.h>

RCSwitch mySwitch = RCSwitch();

void setup() {
	Serial.begin(9600);
	mySwitch.enableReceive(0); // interrupt 0 => digital pin 2 on Uno/Nano
	Serial.println("Ready to sniff 315MHz signals...");
}

void loop() {
	if (mySwitch.available()) {
		long value = mySwitch.getReceivedValue();

		if (value == 0) {
			Serial.println("Unknown encoding");
		} else {
			Serial.print("Received: ");
			Serial.print(value);
			Serial.print(" / ");
			Serial.print(mySwitch.getReceivedBitlength());
			Serial.print(" bits ");
			Serial.print("Protocol: ");
			Serial.println(mySwitch.getReceivedProtocol());
		}

		mySwitch.resetAvailable();
	}
}

int main() {
	init();
	setup();
	while (true) {
		loop();
	}
}
