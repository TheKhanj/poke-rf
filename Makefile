ARDUINO_BASE := $(HOME)/.arduino15/packages/arduino
ARDUINO_VER := 186
AVR_CORE_VER := 1.8.6
GCC_VER := 7.3.0-atmel3.6.1-arduino7

AVR_CORE := $(ARDUINO_BASE)/hardware/avr/$(AVR_CORE_VER)
TOOLCHAIN := $(ARDUINO_BASE)/tools/avr-gcc/$(GCC_VER)
INCLUDES := \
	-Irc-switch \
	-I$(AVR_CORE)/cores/arduino \
	-I$(AVR_CORE)/variants/standard \
	-I$(TOOLCHAIN)/avr/include

CXX := $(TOOLCHAIN)/bin/avr-g++
CC := $(TOOLCHAIN)/bin/avr-gcc
AR := $(TOOLCHAIN)/bin/avr-ar
NM := $(TOOLCHAIN)/bin/avr-nm
OBJCOPY := $(TOOLCHAIN)/bin/avr-objcopy

MCU := atmega328p
F_CPU := 16000000UL
CXXFLAGS := -Os -DF_CPU=$(F_CPU) -mmcu=$(MCU) -std=gnu++11 \
	-fno-exceptions $(INCLUDES) -DARDUINO=$(ARDUINO_VER)
CFLAGS := -Os -DF_CPU=$(F_CPU) -mmcu=$(MCU) -std=gnu++11 \
	-fno-exceptions $(INCLUDES) -DARDUINO=$(ARDUINO_VER)

# Core
CORE_SRC_C := $(wildcard $(AVR_CORE)/cores/arduino/*.c)
CORE_SRC_CPP := $(wildcard $(AVR_CORE)/cores/arduino/*.cpp)
CORE_OBJ_C := $(CORE_SRC_C:.c=.o)
CORE_OBJ_CPP := $(CORE_SRC_CPP:.cpp=.o)
CORE_LIB := core.a

TARGETS := send receive

all: $(patsubst %,%.hex,$(TARGETS))

$(CORE_OBJ_C): %.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(CORE_OBJ_CPP): %.o : %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(CORE_LIB): $(CORE_OBJ_C) $(CORE_OBJ_CPP)
	$(AR) rcs $@ $^

clean-core:
	rm $(CORE_LIB) $(CORE_OBJ_C) $(CORE_OBJ_CPP)

# env
env:
	echo "TOOLCHAIN=$(TOOLCHAIN)"
	echo "CC=$(CC)"
	echo "CXX=$(CXX)"
	echo "AR=$(AR)"
	echo "NM=$(NM)"
	echo "OBJCOPY=$(OBJCOPY)"

# RCSwitch
RC_SWITCH_SRC := rc-switch/RCSwitch.cpp
RC_SWITCH_OBJ := $(RC_SWITCH_SRC:.cpp=.o)
RC_SWITCH_LIB := rc-switch.a

$(RC_SWITCH_OBJ): %.o : %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(RC_SWITCH_LIB): $(RC_SWITCH_OBJ)
	$(AR) rcs $@ $^

clean-rc-switch: clean-core
	rm $(RC_SWITCH_LIB) $(RC_SWITCH_OBJ)

# Main
SRC := send.cpp receive.cpp
OBJ := $(SRC:.cpp=.o)

$(OBJ): %.o : %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.elf: %.o $(RC_SWITCH_LIB) $(CORE_LIB)
	$(CXX) $(CXXFLAGS) $^ -o $@

%.hex: %.elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@

clean: clean-rc-switch clean-core
	rm $(OBJ) $(TARGETS)

flash-send: send.hex
	avrdude -v -p$(MCU) -carduino -P$(wildcard /dev/ttyUSB*) \
		-b115200 -D -Uflash:w:send.hex:i

flash-receive: receive.hex
	avrdude -v -p$(MCU) -carduino -P$(wildcard /dev/ttyUSB*) \
		-b115200 -D -Uflash:w:receive.hex:i

.PHONY: clean clean-rc-switch clean-core env
