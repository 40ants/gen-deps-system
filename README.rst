This command line utility collects all dependencies of given Common Lisp
system and generates an ASDF system definition file with a "fake" system
depending on all these depedencies.

This fake system can be used to improve caching when building docker
container for your application.

TODO: add example.

