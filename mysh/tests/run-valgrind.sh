while read x; do valgrind --leak-check=summary ../bin/mysh test-$x.mysh 3>&1 1>&2- 2>&3- | less; done < phase-1.tests
