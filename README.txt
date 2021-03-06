This library is intended to make it possible to make compiler macros much more useful, by granting them access to lexical type information, making the protocol for declining expansion more convenient, and establishing some information for signaling optimization advice to programmers.  Some utilities to support this, especially for reasoning on types, are also included.

All symbols are available from the SANDALPHON.COMPILER-MACRO package.

Motivation

Writing macros for syntactic extensions is an integral part of Lisp systems, and is strongly supported by Lisp's homoiconicity.  However, at least in Common Lisp, another kind of code transform is not so utilized: those for optimization, i.e. source-to-source transforms.  There's no particular reason for these to be exclusively the domain of an opaque compiler system, any more than syntax is.

To support this, Common Lisp has compiler macros (define-compiler-macro, compiler-macro-function), which are intended as optimization advice to compilers.  Practically speaking compiler macros are like macros, but can be defined on symbols that exist as functions or macros (so as to separate the core logic for such functions from optimization advice on them), and can decline to expand (if an optimization is not applicable).

Compiler macros are, however, not that useful on their own.  Most compiler macros actually written rely mostly on picking out literal arguments to functions (via constantp) for a sort of partial inlining.  As there are no standard facilities for complicated program analysis or, importantly, accessing information that may be being used by the compiler anyway (e.g. OPTIMIZE information, type declarations), this is about the best they can do.

It's also not possible to define multiple compiler macros on a function, so either a wrapper around define-compiler-macro etc. must be provided, or all possible optimizations must be crammed into one compiler macro.

Basics

To support more involved optimization possibilities, this library includes a FORM-TYPE function for analyzing the possible type of a form, and POLICY and POLICY-QUALITY for optimizations conditional on programmer wants.  If possible, implementation-specific hooks are used to access declaration information in environments; otherwise policy is considered neutral, and all variables are considered of type T, etc.

Minimal lexical type information extraction is also supported, even if declarations are not implementationally available.  This means, for example, that (form-type '(the string foo)) will be STRING.  This mechanism is customizable.

Utilities for working with types directly, e.g. extracting bounds from scalar numeric types, are provided.

Compiler maros can note optimization information to programmers (that is, at compile time) with NOTE-OPTIMIZATION-FAILURE.  A tree of condition types is supported so that these conditions may be subclassed, muffled, etc.

A simple mechanism for defining multiple compiler macro functions, called "hints", is included (DEFINE-COMPILER-HINT, DEFINE-COMPILER-HINTER, COMPILER-HINT).  Each hint has a "qualifier", an unevaluated object compared with CL:EQUAL, for establishing uniqueness etc.  Hints can give up on expansion with the function DECLINE-EXPANSION, or abort expansion entirely (e.g. if a form is invalid) with ABORT-EXPANSION; with the same call they may provide optimization notes.

More involved custom mechanisms may be defined, that still use DECLINE-EXPANSION etc., with the macros WITH-EXPANSION-DECLINATION and WITH-EXPANSION-ABORTION.  Something with similar syntax to CLOS is planned, if this library gets users.

Finally, so that the results of optimizations can be seen easily, COMPILER-MACROEXPAND and COMPILER-MACROEXPAND-1 are trivially defined.  They are analogous to CL:MACROEXPAND and CL:MACROEXPAND-1.

Implementation support

Presently CCL and SBCL are supported.  Any other conforming CL implementation should work as well, but information will not be available from the environment.  Hope you like THE.

Implementation-specific hooks are exported from the SANDALPHON.COMPILER-MACRO-BACKEND package.  Functions needed are VARIABLE-TYPE, FUNCTION-TYPE, PARSE-MACRO (as in CLtL2), PARSE-COMPILER-MACRO (simple), POLICY, POLICY-QUALITY (for policy information), and TYPEXPAND/-1 (for type utilities).

Documentation

For more specific documentation, consult the docstrings; everything exported and most of that not exported should be documented.

If people get to using this library, a real manual will be constructed.

Examples

An edit of pkhuong's TABASCO-SORT library for efficient inline sorts, and a "port" of a bit of Cyrus Harmon's opticl, are in test/

Notes

Miscellaneous notes are collected in notes/
