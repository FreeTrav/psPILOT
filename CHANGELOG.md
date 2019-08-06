# psPILOT Changelog

2019-08-06	Implemented optional case-sensitivity for text comparisons in M: and (conditionals). To turn on case-sensitivity, include "CS" on a P: line; to turn it off, include "CI". The default remains case-insensitive.

2019-01-25	Fixed a bug where if a subroutine was at the end of the source file and the `E:` statement was omitted, the program would not return from the subroutine.

2019-01-22	Implemented file commands and @-jumps

2019-01-17	Fixed a bug where variables were not being expanded in `C:` statements if the result was expected to be numeric.

2019-01-10	Implemented word-wrap and `H` modifier for `T:`, `Y:`, and `N:`. Implemented setting print width using `P:W##`.

2019-01-08	Compound conditionals implemented.

2019-01-03	`W:` statement implemented.

2018-12-27	Labels in `J:` and `U:` statements no longer require the leading `*`, though it is still accepted.

2018-12-26	Initial release (on [TIO](https://tio.run/#pilot-pspilot))

