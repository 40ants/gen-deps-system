===========
 ChangeLog
===========

0.4.3 (2020-01-03)
==================

Fixed error when ``app-deps.asd`` already exists and new
version is shorter. Previously, file was overwritten and
its tail become corrupted,

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
