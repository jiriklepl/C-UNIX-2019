# MYSH

This is my solution to the assignment for **Unix/Linux Programming in C (NSWI015)** MFF UK, winter semester 2019/2020.

The assignment can be found [here](https://devnull-cz.github.io/unix-linux-prog-in-c/class-assignments/labs-assignment-2019.txt).

---

Checked statically by clang-tidy (ignoring C11 standard noncompliance) and dinamically by valgrind on heavy inputs.

## How to Build

Just run the makefile: (supports gcc and clang)

```bash
make
```

Build with a compiler of your choice: (e.g. gcc)

```bash
make CC=gcc
```

Build a debug version:

```bash
make debug
```

## Supported Shell Commands

- cd
- exit
