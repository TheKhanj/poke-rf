#include "RCSwitch.h"
#include <Arduino.h>

RCSwitch mySwitch = RCSwitch();

void setup() {
	Serial.begin(9600);
	mySwitch.enableTransmit(10);
	mySwitch.setProtocol(1);
	mySwitch.setRepeatTransmit(10);

	Serial.println("Ready to send 315MHz signals...");
}

void loop() {
	mySwitch.send(43778561, 26);
	delay(1000);
}

int main() {
	init();
	setup();
	while (true) {
		loop();
	}
}
