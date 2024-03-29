(uiop:define-package #:gen-deps-system
  (:use #:cl)
  (:import-from #:fset)
  (:import-from #:alexandria)
  (:nicknames #:gen-deps-system/core)
  (:export
   #:generate))
(in-package #:gen-deps-system)


;; https://github.com/quicklisp/quicklisp-client/issues/134
;; https://www.reddit.com/r/Common_Lisp/comments/82wiyt/how_to_collect_all_asdf_dependencies_for/

(defun get-dependencies (system)
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
                     (:require (second name)))))))))
    
    (let ((processed (fset:set))
          (results (fset:set))
          (queue (fset:set (normalize system))))
      
      (do ((current-name (fset:arb queue)
                         (fset:arb queue)))
          ((null current-name)
           ;; return result
           processed)

        ;; Remove current name from the queue
        (setf queue
              (fset:less queue current-name))
        ;; And put it into the "processed" pool
        (setf processed
              (fset:with processed current-name))

        (let ((result (ensure-primary current-name)))
          (when result
            (setf results
                  (fset:with results result))))
        
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
                         (asdf:find-system current-name)))
               (deps (when system
                       (asdf:component-sideway-dependencies system))))
          (dolist (dep deps)
            (let ((normalized-dep (normalize dep)))
              (unless (or
                       ;; If it is null, then this dependency should be skipped
                       ;; because it depends on a missing feature.
                       (null normalized-dep)
                       (fset:lookup processed normalized-dep)
                       (fset:lookup queue normalized-dep))
                (setf queue
                      (fset:with queue normalized-dep)))))))

      (values results))))


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
         (deps (fset:convert 'list deps))
         (deps (remove-if (lambda (name)
                            (let ((primary-name (asdf:primary-system-name name)))
                              (member primary-name (list* system
                                                          except)
                                      :test #'string-equal)))
                          deps))
         (deps (sort deps #'string<)))
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
