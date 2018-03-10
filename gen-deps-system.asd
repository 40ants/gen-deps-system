(defsystem "gen-deps-system"
  :class :package-inferred-system
  :version "0.1.0"
  :author "Alexander Artemenko"
  :license "BSD 3-Clause"
  :depends-on ("")
  :description "This command line utility collects all dependencies of given Common Lisp system and generates an ASDF system definition file with a \"fake\" system depending on all these depedencies.")
