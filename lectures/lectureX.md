Hints for HW
============

Fork + exec is very inefficient -> it's much better to use spawn

- although for our needs this combo is sufficient (pipe sequences - mysh)
- we will use pipe, but forking after that (cannot be done before) also forks pipe's file descriptors?
  - pipe takes int fildes[2] and sets the first to describe stdin of the pipe and the second to describe stdout of the pipe.
