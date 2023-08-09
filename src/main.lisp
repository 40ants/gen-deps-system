(uiop:define-package #:gen-deps-system/main
  (:use #:cl)
  (:import-from #:cl-strings)
  (:import-from #:gen-deps-system
                #:generate)
  (:import-from #:defmain
                #:defmain
                #:print-help)
  (:export #:main))
(in-package #:gen-deps-system/main)


(defmain (main) ((except "A comma-separated systems to exclude from dependencies")
                 &rest system)
  "Generates an asd file with a system depending on all dependencies of the given Common Lisp system."

  (if system
      (generate
       (first system) :except (when except
                                (cl-strings:split except ",")))
      (print-help)))
