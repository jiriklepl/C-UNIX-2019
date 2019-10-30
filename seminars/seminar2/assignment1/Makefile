CC		:= cc
CFLAGS	:= -Wall -Wextra -g

BIN		:= bin
SRC		:= src
INCLUDE	:= include
LIB		:= lib

LIBRARIES	:=

ifeq ($(OS),Windows_NT)
EXECUTABLE	:= main.exe
else
EXECUTABLE	:= main
endif

SOURCEDIRS	:= $(shell find $(SRC) -type d)
INCLUDEDIRS	:= $(shell find $(INCLUDE) -type d)
LIBDIRS		:= $(shell find $(LIB) -type d)

CINCLUDES	:= $(patsubst %,-I%, $(INCLUDEDIRS))
CLIBS		:= $(patsubst %,-L%, $(LIBDIRS))

SOURCES		:= $(wildcard $(patsubst %,%/*.c, $(SOURCEDIRS)))
OBJECTS		:= $(SOURCES:.c=.o)

.PHONY: all, run, clean

all: $(BIN)/$(EXECUTABLE)

clean:
	-$(RM) $(BIN)/$(EXECUTABLE)
	-$(RM) $(OBJECTS)


run: all
	./$(BIN)/$(EXECUTABLE) ${ARGS}

%.o: %.c
	$(CC) $(CFLAGS) -c $(CINCLUDES) $(CLIBS) -o $@ $(LIBRARIES) $^

$(BIN)/$(EXECUTABLE): $(OBJECTS)
	$(CC) $(CFLAGS) $(CINCLUDES) $(CLIBS) -o $@ $(LIBRARIES) $^
