C_FLAGS := -std=c11 -Wall -Wextra -Wpedantic

RELEASE_FLAGS := -O2 -march=native -DNDEBUG
DEBUG_FLAGS   := -g -DDEBUG

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


BISON_FILES := $(TEMP)/shell.tab.c $(TEMP)/shell.tab.h
BISON_SRC := $(TEMP)/shell.tab.c
BISON_COMMAND := bison --defines=$(TEMP)/shell.tab.h --output=$(BISON_SRC) $(SRC)/shell.y

FLEX_FILE := $(TEMP)/shell.l.c

FLEX_COMMAND := flex -o$(FLEX_FILE) $(SRC)/shell.lex


SRC_FILES = $(wildcard $(SRC)/*.c) $(BISON_SRC) $(FLEX_FILE)
OBJ_FILES = $(patsubst $(SRC)/%.c,$(TEMP)/%.o,$(patsubst $(TEMP)/%.c,$(TEMP)/%.o,$(SRC_FILES)))

COMPILE = $(CC) -c $(C_FLAGS) -I$(INCLUDE) -o$@ $<

LINK = $(CC) $(C_FLAGS) -o$@ $^


.PHONY: all clean run debug release

all: release

release: C_FLAGS += $(RELEASE_FLAGS)
release: $(BIN) $(TEMP) $(BISON_FILES) $(FLEX_FILE) $(BIN)/$(EXECUTABLE)

debug: C_FLAGS += $(DEBUG_FLAGS)
debug: $(BIN) $(TEMP) $(BISON_FILES) $(FLEX_FILE) $(BIN)/$(EXECUTABLE)

clean:
	$(RM) $(wildcard $(BIN)/*) $(wildcard $(TEMP)/*)

run: all
	$(BIN)/$(EXECUTABLE)


$(BIN):
	mkdir $(BIN)

$(TEMP):
	mkdir $(TEMP)

$(TEMP)/%.o: $(SRC)/%.c $(wildcard $(INCLUDE)/*)
	$(COMPILE)

$(TEMP)/%.o: $(TEMP)/%.c $(wildcard $(INCLUDE)/*)
	$(COMPILE)

$(BISON_FILES): $(SRC)/shell.y
	$(BISON_COMMAND)

$(FLEX_FILE): $(SRC)/shell.lex
	$(FLEX_COMMAND)

$(BIN)/$(EXECUTABLE): $(OBJ_FILES)
	$(LINK)
