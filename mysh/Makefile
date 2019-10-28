CC      := g++
C_FLAGS := -std=c++17 -Wall -Wextra -Wpedantic -g

BIN     := bin
SRC     := src
INCLUDE := include
LIB     := lib
TEMP    := tmp


ifeq ($(OS),Windows_NT)
EXECUTABLE  := main.exe
else
EXECUTABLE  := main
endif


OBJ_FILES   := $(patsubst $(SRC)/%.cpp,$(TEMP)/%.o,$(wildcard $(SRC)/*.cpp))


COMPILE = $(CC) -c $(C_FLAGS) -I$(INCLUDE) -o$@ $<

LINK = $(CC) $(C_FLAGS) -o$@ $^


.PHONY: all clean run

all: $(BIN) $(BIN)/$(EXECUTABLE)

clean:
	$(RM) $(BIN)/$(EXECUTABLE) $(wildcard $(TEMP)/*)

run: all
	./$(BIN)/$(EXECUTABLE)


$(BIN):
	mkdir $(BIN)

$(TEMP):
	mkdir $(TEMP)


$(TEMP)/%.o: $(SRC)/%.cpp $(wildcard $(INCLUDE)/*)  $(TEMP)
	$(COMPILE)

$(BIN)/$(EXECUTABLE): $(OBJ_FILES)
	$(LINK)
