(uiop:define-package #:gen-deps-system
  (:use #:cl)
  (:import-from #:alexandria)
  (:nicknames #:gen-deps-system/core)
  (:export
   #:generate))
(in-package #:gen-deps-system)


;; https://github.com/quicklisp/quicklisp-client/issues/134
;; https://www.reddit.com/r/Common_Lisp/comments/82wiyt/how_to_collect_all_asdf_dependencies_for/

(defun get-dependencies (system-name)
  "Returns dependencies starting from the leafs and ending to the direct dependencies of the given SYSTEM"
  (let ((seen nil)
        (results nil)
        ;; (queue (list (normalize system)))
        )
    (labels ((ensure-primary (name)
               (check-type name string)
               (let* ((asdf-system (asdf:find-system name)))
                 (typecase asdf-system
                   ;; We don't want to list all subsystems of
                   ;; package inferred system and collect only primary systems instead.
                   ;; Moreover, Quicklisp often is unable to download a subsystem
                   ;; and using primary system helps to download all system files
                   ;; making subsystems visible for ASDF.
                   (asdf/package-inferred-system:package-inferred-system
                    (asdf:primary-system-name asdf-system))
                   ;; This kind of system we ignore, because they can't
                   ;; be installed using Quicklisp.
                   (asdf/operate:require-system
                    nil)
                   ;; Usual asdf systems are listed as is.
                   (t
                    name))))
             (normalize (name)
               (etypecase name
                 (null) ;; Name can be a nil. In this case we have to return it as is.
                 (string
                  (string-downcase name))
                 (symbol
                  (normalize (symbol-name name)))
                 (list
                  (let ((dep-type (first name))
                        (supported-dep-types (list :version :feature :require)))
                    (unless (member dep-type
                                    supported-dep-types)
                      (error "This component \"~A\" should have first element from this list: ~A."
                             name
                             supported-dep-types))
                   
                    (normalize
                     (case dep-type
                       (:version (second name))
                       ;; Dependencies which depends on some
                       ;; features are only collected if this feature is
                       ;; present in the current Lisp. This was, using
                       ;; get-dependencies in different Lisps can return
                       ;; different sets of dependencies.
                       (:feature (when (member (second name)
                                               *features*)
                                   (third name)))
                       (:require (second name))))))))
             (get-deps (system-name)
               ;; And add it's dependencies which aren't processed or in the queue already
               ;; Sometimes system can't be found because itself depends on some feature,
               ;; for example, you can specify dependency as a list:
               ;; (:FEATURE :SBCL (:REQUIRE :SB-INTROSPECT))
               ;; and it will be loaded only on SBCL.
               ;; When we are collecting dependencies on another implementation,
               ;; we don't want to fail with an error because ASDF is unable to find
               ;; such dependencies
               (let* ((system (handler-bind ((asdf:system-out-of-date
                                               (lambda (c)
                                                 (declare (ignorable c))
                                                 (invoke-restart 'continue)))
                                             (asdf:bad-system-name
                                               (lambda (c)
                                                 (declare (ignorable c))
                                                 (muffle-warning))))
                                (asdf:find-system system-name)))
                      (deps (when system
                              (asdf:component-sideway-dependencies system))))
                 (remove-if #'null
                            (mapcar #'normalize deps))))
             (recurse (system-name)
               (unless (member system-name seen
                               :test #'string-equal)
                 (push system-name seen)

                 (mapcar #'recurse
                         (get-deps system-name))

                 (let ((result (ensure-primary system-name)))
                   (when result
                     (pushnew result results
                              :test #'string-equal))))))
      (recurse system-name))
    (values (nreverse results))))


(defun generate (system &key except)
  "Creates <system>-deps.asd file with all external dependencies for a given ASDF system."
  (check-type except (or null list))
  
  (let* ((deps-system-name (format nil "~A-deps"
                                   (typecase system
                                     (string system)
                                     (symbol (string-downcase
                                              (symbol-name system))))))
         (filename (asdf:system-relative-pathname system
                                                  (format nil "~A.asd" deps-system-name)))
         (deps (get-dependencies system))
         (deps (remove-if (lambda (name)
                            (let ((primary-name (asdf:primary-system-name name)))
                              ;; Now we will remove from the list any system
                              ;; if which was excluded explicitly or equal to the
                              ;; system we are building dependencies list for.
                              (member primary-name (list* system
                                                          except)
                                      :test #'string-equal)))
                          deps)))
    (format t "System: ~A, filename: ~A~%" system filename)
    (alexandria:with-output-to-file (s filename
                                       :if-exists :supersede
                                       :if-does-not-exist :create)
      (let (
            ;; (*print-pretty* t)
            ;; (*print-right-margin* 1)
            (*package* (find-package "ASDF")))
        (write
         `(asdf:defsystem ,deps-system-name
            :class :package-inferred-system
            :depends-on (,@deps))
         :stream s
         :pretty t
         :right-margin 1
         :case :downcase)

        (values)))))
