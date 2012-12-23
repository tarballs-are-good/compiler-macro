;;;; hint.lisp

;;;; a basic mechanism for multiple compiler macros on the same symbol.
;;;; see condition.lisp for how decline-expansion, with-expansion-declination etc. work.

;;;; TODO: better names

(in-package #:sandalphon.compiler-macro)

(defvar *compiler-hints* (make-hash-table)
  "A hash table from function names to alists of compiler macro hints.")

(defun compiler-hinter-lambda (name)
  "Return a compiler macroexpander closure that calls all the hints (in *COMPILER-HINTS*) for the given NAME, and returns the first successful expansion (or the form it's provided with)."
  ;; sure is arrow in here
  (lambda (form env)
    (block done
      (with-expansion-abortion
	(dolist (entry (gethash name *compiler-hints*))
	  (with-expansion-declination
	    (let ((new (funcall (cdr entry) form env)))
	      (unless (eql form new) ; handle old-style compiler macro declination semantics
		(return-from done new))))))
      ;; we aborted or didn't find an expansion, so
      form)))

(defmacro define-compiler-hinter (name lambda-list &body options)
  "Define NAME to have a hinter expansion as its compiler macro.  See DEFINE-COMPILER-HINT's documentation.

Supported options: :documentation"
  (declare (ignore lambda-list))
  (let* ((doc-p (assoc :documentation options))
	 (doc (second doc-p)))
    ;; more options later, e.g. "method combinations"
    `(eval-when (:compile-toplevel :load-toplevel :execute)
       (when (and (compiler-macro-function ',name)
		  (not (nth-value 1 (gethash ',name *compiler-hints*))))
	 (warn 'compiler-macro-redefinition-warning
	       :name ',name))
       (setf (gethash ',name *compiler-hints*) nil)
       (setf (compiler-macro-function ',name)
	     (compiler-hinter-lambda ',name))
       ,@(when doc-p
	       (list `(setf (documentation ',name 'compiler-macro) ',doc)))
       ',name)))

(defmacro define-compiler-hint (name lambda-list qual &body body &environment env)
  "Define a compiler hint for NAME.

LAMBDA-LIST is a compiler macro lambda list, that is a macro lambda list, and with BODY will be used to form a hint expander function.

QUAL is an arbitrary object, which is compared (with CL:EQUAL) to establish uniqueness of the hint, for redefinition, and retrieval with COMPILER-HINT.

Hint functions have an implicit block with the usual name, can have declarations and docstrings, etc.

Hint functions can signal conditions of type EXPANSION-DECLINATION in order to decline to expand without using the old-style \"return the original form\" protocol of compiler macros (though that is also supported).  The function DECLINE-EXPANSION is provided to simplify this."
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     ;; ew, double hash lookup
     (let ((existing? (compiler-hint ',name ',qual)))
       (when existing?
	 (warn 'compiler-macro-redefinition-warning :name ',name)))
     ;; TODO: set doc to qual? (or use the documentation from the function itself)
     (setf (compiler-hint ',name ',qual)
	   ,(parse-compiler-macro name lambda-list body env))))

(defun compiler-hint (name qual)
  "Retrieve the hint function for NAME, identified by QUAL compared via CL:EQUAL.

A hint function is a function of two arguments, a form and an environment, and which returns a form with the same semantics as FORM but (hopefully) more efficient.

A hint function signals a condition of type EXPANSION-DECLINATION to signal its caller that it cannot operate on the provided form.  The consequences of calling a hint function in an environment where such conditions are unhandled (i.e. do not transfer control out of the function) are undefined."
  (cdr (assoc qual (gethash name *compiler-hints*))))

(defun (setf compiler-hint) (new-value name qual)
  "Set the hint function for NAME, identified by QUAL compared via CL:EQUAL.

A hint function is a function of two arguments, a form and an environment, and which returns a form with the same semantics as FORM but (hopefully) more efficient, or otherwise changed.

A hint function should be prepared to receive a form beginning with its name, or a form beginning with CL:FUNCALL.  A hint function can expect that conditions of type EXPANSION-DECLINATION (possibly signaled by DECLINE-EXPANSION) will be handled."
  (check-type new-value function)
  ;; (setf (alexandria:assoc-value (gethash name *compiler-hints*) name :test #'equal) new-value)
  (let ((alist (gethash name *compiler-hints*)))
    (if alist
	(let ((assoc (assoc qual alist :test #'equal)))
	  (if assoc
	      (setf (cdr assoc) new-value)
	      (push (cons qual new-value) (gethash name *compiler-hints*))))
	(setf (gethash name *compiler-hints*)
	      (list (cons qual new-value)))))
  new-value)
