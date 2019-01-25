===========
 ChangeLog
===========

0.4.0
=====

Argument ``--except`` now can accept a comma-separated systems list.

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
