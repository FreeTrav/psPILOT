# PSPILOT

## Introduction

psPILOT is an implementation of the PILOT programming language (**P**rogrammed **I**nstruction, **L**earning, **O**r **T**eaching) written entirely in Microsoft's PowerShell scripting language. It implements most of the PILOT Core language as defined in the (now withdrawn) IEEE standard 1154 of 1991 (Corrected to November 1991). For historical information on and an overview of the language, the reader is referred to [Wikipedia's page on the PILOT language](https://en.wikipedia.org/wiki/PILOT).

This implementation has been tested using PowerShell 5 on Windows 7 and PowerShell 6 on Linux Mint, but it should work without issue on any PowerShell 5 or later system, and quite likely on any PowerShell 3 or later system.

## Overview of PILOT programs

...

## PSPILOT Syntax

In the syntax descriptions below, the following symbols are used:

`«variable-name»`: Variable names consist of a `#` (for integer numeric variables) or `$` (for string variables) followed by up to ten alphanumeric characters (including the underscore), beginning with a letter.

`«filename»`: Filenames are system-dependent as to syntax and allowable characters; PSPILOT makes no effort to validate the existence of a file or the syntax of its name. Filenames may be stored in string variables, and the variable passed to PILOT statements that expect a `«filename»`.

`«label»`: A label is an alphanumeric string prefixed by `*`. In PSPILOT, the label must be the only thing on the program line; the Standard allows it to be followed by whitespace and any PILOT command.

### Core Statements

#### A: Accept

`A:`

`A: «variable-name»`

Accept input into "accept buffer". If a `«variable-name»` is supplied, the input is copied into the variable. If not (an "anonymous accept"), the input can only be used (implicitly) by `M:` statements.

Some implementations of PILOT permit multiple `«variable-name»`s to be supplied, with varying rules on how to parse the input to assign the values to variables. PSPILOT only supports "anonymous accepts" or a single variable in an `A:` statement.

#### C: Compute

`C:«variable-name»=«expression»`

Compute and assign a value to a variable. 

If `«variable-name»` indicates a numeric value (begins with `#`), `«expression»` may contain basic mathematical operations `+`, `-`, `*`, and `/`; the order of evaluation is multiplication and division before addition and subtraction, but may be changed through the use of parentheses `()`. Calculations will result in an integer value (though they will be carried out internally in floating point and rounded at the end - `(5/2) + (5/2) ` will evaluate to 5, not 4).

If `«variable-name»` indicates a string value (begins with `$`), no computation other than variable expansion will occur; effectively, the only operation available is concatenation: 

##### Concatenation of a variable on the end of a fixed string:

`C:$foo=iso$quux` will assign the string `isobar` to `$foo` if `$quux` contains the string `bar`

##### Concatenation of two variables:

`C:$baz=$foo$bar` will yield `shazbat` for the value of `$baz` if `$foo` contains `shaz` and `$bar` contains `bat`

##### Concatenation of a fixed string on the end of a variable:

This requires the use of the backslash (`\`) to separate the fixed string from the variable name.

`C:$quux=$foo\bie` will yield `barbie` for the value of `$quux` if the value of `$foo` is `bar`.

##### Other uses of the backslash:

If you wish to include the characters **$** (indicates string variables), **#** (indicates numeric variables), **%** (indicates system variables), or **\\** (backslash, the 'escape' character) in a string, prefix them with a backslash **\\**. Thus, `T:\$FOO` will cause the string `$FOO` to be printed, instead of the value of the string variable `$foo`; the backslash prevents the `$` from being interpreted as a signal that a string variable is being referenced.

#### E: End

`E:`

End (return from) subroutine or (if outside of a subroutine) end the program. In PSPILOT, if an operand is supplied, it will be ignored, but does not cause an error. Most implementations of PILOT do not permit an operand to be supplied.

#### J: Jump

`J:«label»`

Jump to the line of the program indicated by `«label»`. 

 J:*RESTART

M
Match the accept buffer against string variables or string literals. Example:

 R:Search accept buffer for "TRUTH", the value of MEXICO and "YOUTH", in that order
 M:TRUTH,$MEXICO,YOUTH

The first match string (if any) that is a substring of the accept buffer is assigned to the special variable $MATCH. The buffer characters left of the first match are assigned to $LEFT, and the characters on the right are assigned to $RIGHT.

The match flag is set to 'yes' or 'no', depending on whether a match is made. Any statement that has a Y following the command letter is processed only if the match flag is set. Statements with N are processed only if the flag is not set.

N
Equivalent to TN: (type if last match unsuccessful)
R
The operand of R: is a comment, and therefore has no effect.
T
'Type' operand as output. Examples:

 R:Output a literal string
 T:Thank you for your support.
 R:Output a variable expression
 T:Thank you, $NAME.

U
Use (call) a subroutine. A subroutine starts with a label and ends with E: Example:

 R:Call subroutine starting at label *INITIALIZE
 U:*INITIALIZE

Y
Equivalent to TY: (type if last match successful)
Parentheses
If there is parenthesized expression in a statement, it is a conditional expression, and the statement is processed only if the test has a value of 'true'. Example:

 R:Type message if x>y+z
 T(#X>#Y+#Z):Condition met...

### Extensions suggested in the Standard

#### L: Link

`L: «filespec»`

`«filespec»` is a legal filename on the host system, which may include path information. PSPILOT does not check the validity of the value, nor does it verify the existence of the file before attempting to load it.

The `L` (`Link`) statement is mentioned in section 4.1 of the Standard. `«filespec»` is expected to be a program in the PILOT language, and replaces the previous program in memory. The Standard is silent on the matter of whether variables or status information (e.g., the `Accept` buffer or system variables) should be preserved or discarded upon `Link`; the documentation for Nevada PILOT implies that variables are preserved across a `Link` (which Nevada PILOT calls `LOAD`), but PSPILOT does _not_ preserve variables or other program status information.

### Extensions not suggested in the Standard

...

## Known Bugs and Other Infelicities

1. Running off the end of the program (no `E` statement) while in a subroutine call (`U` statement) does not return from the subroutine.

## Differences between IEEE Standard PILOT and PSPILOT

### A: Permanent Differences

Numbers in brackets represent sections of the standard from which PSPILOT differs.

1. Only the short-form commands (`T`, `A`, `M`, etc.) are accepted; the full keywords (`Type`, `Accept`, `Match`, etc.) cannot be used. [2.2, 2.3]
2. The `G` (`Graphic`) Core statement simply prints a message `PSPILOT does not support graphics`, but does not throw an error. [2.2, 2.3]
3. Variables must use the type-indicator as the lead character; strings must be `$name`, numbers must be `#name`. [3.1, 3.2]
4. The system variables `%expression`, `%term`, `%factor`, `%nextstmt`, `%maxuses`, `%return*`, `%relation`, and `%text` are not supported. [2.3]
5. The standard states that early (pre-Standard) implementations of the `C` (`Compute`) statement 'dropped' into the host language (most PILOT interpreters were not in machine-native code, but ran 'on top' of other languages like BASIC) to evaluate the expression, and implies that the conformant interpreter should parse the expression and evaluate it directly, using conventions similar to those of BASIC. PSPILOT returns to the original design, and internally converts the BASIC-convention expressions into PowerShell conventions, and then asks PowerShell to evaluate them. This is the reason that the system variables `%expression`, `%term`, and `%factor`, mentioned in 4. above, are not available.
6. There is no defined limit on the number of levels of `U` statement nesting; this is the reason that the system variables `%maxuses` and `%return*`, mentioned in 4. above, are not supported.
7. String literals in conditions must be quoted (e.g., `T($foo="bar")`, not `T($foo=bar)`). However, they should ***not*** be quoted in assignments (e.g., `C:$foo=bar`, not `C:$foo="bar"`). [2.2, 4.5]
8. Labels are not limited to ten characters in length. [2.3]
9. The `H` modifier to `T` and `A` is not supported. (This is due to limitations in PowerShell). [4.3]

### B: To Be Changed

1. Labels must be on lines by themselves (that is, you cannot do `*HERE T: We're here`). [2.3]
2. The target of a `J` statement must include the leading `*`. That is, the standard describes a `J` statement as being written `J:LABEL`; PSPILOT requires you to write `J:*LABEL`. This is consistent with Nevada PILOT; RPILOT follows the standard. This will be fixed to allow either style as equivalent. [2.3]
3. The `F` (`File`) Core statement is not supported. Note that the standard does not specify how to select file operations. [2.2, 2.3]
4. The Extensions of sections 4.1 through 4.4 of the standard are not supported (some will be unsupported permanently). [4.1, 4.2, 4.3, 4.4]
5. `T`, `N`, and `Y` statements that would wrap past the maximum width of the output device do not word-wrap; they 'letter wrap'. [4.6]

### Differences from Other PILOT Implementations

1. **RPILOT:** The `S` command (execute a system command) and the `X` command (Execute a string as a PILOT command) are not supported. Note that the Standard recommends that `S` be used for playing sound, and execution of system commands use the two-character command `XS`.
2. **RPILOT** allows matching in the `M` statement of any of several words separating them with spaces (e.g., `M: YES YEP YEA`) . IEEE Standard 1154-1991 does not indicate that this is permissible, specifying only `,`, `!`, or `|` as separators (e.g., `M: YES, YEP, YEA`). PSPILOT follows the standard, not RPILOT, in this.