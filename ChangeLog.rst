===========
 ChangeLog
===========

0.7.0 (2022-08-09)
==================

Now all ``require`` dependencies are ignored and for package inferred systems only
their primary system names are collected.

0.6.0 (2022-10-16)
==================

All code for generation was moved to the lisp package. Now you can use
``(gen-deps-system:generate :my-system)``.

0.5.0 (2021-06-03)
==================

Now utility formats each dependency on it's own line,
making diffs more useful.

0.4.4 (2021-06-02)
==================

Fixed to work with latest DEFMAIN system.

0.4.3 (2020-01-03)
==================

Fixed error when ``app-deps.asd`` already exists and new
version is shorter. Previously, file was overwritten and
its tail become corrupted.

0.4.2 (2019-01-26)
==================

Fixed error in case when ``app-deps.asd`` file is absent.

0.4.1 (2019-01-25)
==================

Argument ``--except`` now can accept a comma-separated systems list.

0.4.0
=====

Overwrite file instead of supersede it. This allows to run
``gen-deps-system`` inside a docker container where files ``app.asd``
and ``app-deps.asd`` are mounted as volumes.

0.3.0
=====

Now command can accept additional ``--except`` parameter to exclude some
system from the dependencies list.

Also, now during exclusion, system primary names are checked agains a
system from input arguments and ``--except`` argument. Previously there
was a check if one strings has a prefix.

0.2.0
=====

Added handling of ``asdf:bad-system-name`` and
``asdf:system-out-of-date`` signals.

0.1.0
=====

Initial prototype.
