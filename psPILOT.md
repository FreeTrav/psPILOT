# psPILOT

## Introduction

psPILOT is an implementation of the PILOT programming language (**P**rogrammed **I**nstruction, **L**earning, **O**r **T**eaching) written entirely in Microsoft's PowerShell scripting language. It implements most of the PILOT Core language as defined in the (now withdrawn) IEEE standard 1154 of 1991 (Corrected to November 1991). For historical information on and an overview of the language, the reader is referred to [Wikipedia's page on the PILOT language](https://en.wikipedia.org/wiki/PILOT).

This implementation has been tested using PowerShell 5 on Windows 7 and PowerShell 6 on Linux Mint, but it should work without issue on any PowerShell 5 or later system.

## psPILOT Syntax

### General notes

psPILOT preserves the case of string literals, but makes all comparisons in a case-insensitive manner - that is, `M:Yes`, `M:YES`, and `m:yes` are all identical instructions to psPILOT, but the user will see different output for `T:This is a test` and `T:THIS IS A TEST`.

In the syntax descriptions below, the following symbols are used:

`«variable-name»`: Variable names consist of a `#` (for integer numeric variables) or `$` (for string variables) followed by up to ten alphanumeric characters (including the underscore), beginning with a letter.

`«filename»`: Filenames are system-dependent as to syntax and allowable characters; psPILOT makes no effort to validate the existence of a file or the syntax of its name. Filenames may be stored in string variables, and the variable passed to PILOT statements that expect a `«filename»`.

`«label»`: A label is an alphanumeric string prefixed by `*`. In psPILOT, the label must be the only thing on the program line; the Standard allows it to be followed by whitespace and any PILOT command.

`«text»`: Text is arbitrary sequences of characters, with no specific meaning to the PILOT interpreter (though the PILOT program may attach significance to the text or a subset thereof).

`«number»`: An arbitrary sequence of digits, representing a number. At present in psPILOT, the number represented should be within the system range for an integer.

### Statement Structure

A PILOT statement consists of one or more letters identifying the specific operation to be performed, followed optionally by `Y`, `N`,  `E`, or a conditional expression in parentheses, followed by a colon `:`, followed by one or more operands which may or may not be optional, depending on the statement. In EBNF, 

`«statement»::=«command-letters»["Y"|"N"|"E"|(«conditional-expression»)]:[«operands»]`

The `«command-letters»` may be omitted only if there is a previous line where they were _not_ omitted; the omitted `«command-letters»` will be assumed to be the same as the most recent non-omitted one.

`T: This is line one`

`: This is line two`

`: This is line three`

is considered to be the same as

`T: This is line one`

`T: This is line two`

`T: This is line three`



The `«command-letters»` are described below.

### Core Statements

#### A: Accept

`A:`

`A: «variable-name»`

Accept input into "accept buffer". If a `«variable-name»` is supplied, the input is copied into the variable. If not (an "anonymous accept"), the input can only be used (implicitly) by `M:` statements.

Some implementations of PILOT permit multiple `«variable-name»`s to be supplied, with varying rules on how to parse the input to assign the values to variables. psPILOT only supports "anonymous accepts" or a single variable in an `A:` statement.

The `H` modifier for the `A:` statement is ignored; accepts are always terminated with a newline that is echoed to the display.

#### C: Compute

`C:«variable-name»=«expression»`

Compute and assign a value to a variable. 

If `«variable-name»` indicates a numeric value (begins with `#`), `«expression»` may contain basic mathematical operations `+`, `-`, `*`, `/`, and `%` (modulus, or remainder from division); the order of evaluation is multiplication and division (including modulus) before addition and subtraction, but may be changed through the use of parentheses `()`. Calculations will result in an integer value (though they will be carried out internally in floating point and rounded at the end - `(5/2) + (5/2) ` will evaluate to 5, not 4).

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

End (return from) subroutine or (if outside of a subroutine) end the program. In psPILOT, if an operand is supplied, it will be ignored, but does not cause an error. Most implementations of PILOT do not permit an operand to be supplied.

#### J: Jump

`J:«label»`

Jump to the line of the program indicated by `«label»`. If there is no line in the program matching the `«label»`, psPILOT will report that the label is undefined and exit the PILOT program. Different implementations of PILOT variously require, permit, or prohibit the leading `*` in the `«label»` in a `J` statement; psPILOT permits it but does not require it (i.e., `J: *TARGET` and `J: TARGET` are equivalent). 

There are a few special jumps that are permitted without using labels; all are single letters preceded by `@`:

`@A`: Jump to the most-recently executed `A:` (`Accept`) statement.

`@R`: Jump to the most-recently executed `FR:` (`File/Read`) statement.

`@W`: Jump to the most-recently executed `FW:` (`File/Write`) statement.

`@M`: Jump to the next `M:` (`Match`) statement.

`@P`: Jump to the next `P:` (`Problem` or `Parameter`) statement.

#### M: Match

`M:«match-value-list»`

`«match-value-list»` is a list of string values, separated by `,`, `!`, or `|`.

Match the accept buffer against string variables or string literals. Multiple values may be given separated by `,`, `!`, or `|`. 

The match flag is set to 'yes' or 'no', depending on whether a match is made. Any statement that has a Y following the command letter is processed only if the match flag is set to 'yes'. Statements with N are processed only if the flag is set to 'no'.

The first match string (if any) that is a substring of the accept buffer is assigned to the special (system) variable `%MATCH`. The buffer characters left of the first match are assigned to `%LEFT`, and the characters on the right are assigned to `%RIGHT`.

Matches are case-insensitive by default. Case-sensitivity for M: and parenthesized conditionals can be turned on; see the **P:** statement.

#### R: Remark

`R: «text»`

`«text»` is a comment, and therefore has no effect.

#### T: Type

`T:«string-value»`

'Type' operand as output to the default output device (usually the screen). Variables are expanded, but `«expression»`s that would be valid in a `C:` statement are not evaluated. If `«string-value»` is omitted, a blank line will be printed.

##### Y: Yes

`Y: «string-value»`

Equivalent to TY: (type if last match successful). 

##### N: No

`N:«string-value»`

Equivalent to TN: (type if last match unsuccessful)

The `H` modifier may be used on `T:`, `Y:`, and `N:` statements (`TH:`, `YH:`, and `NH:`). This causes the text specified in `«string-value»` to be output without a trailing newline. This is an extension mentioned in section 4.3 of the Standard for `T`, but not for `Y` or `N`.

#### U: Use

Use (call) a subroutine. A subroutine starts with a label and ends with `E:`. psPILOT saves the line number following the call, and jumps to the designated label, continuing execution from that point. When the `E:` statement is reached, psPILOT returns to the the saved line number, and resumes execution. Different implementations of PILOT variously require, permit, or prohibit the leading `*` in the `«label»` in a `U` statement; psPILOT permits it but does not require it (i.e., `U: *TARGET` and `U: TARGET` are equivalent). 

#### Conditional Execution

A psPILOT statement may be executed conditionally by including `Y`, `N`, `E`, or a parenthesized conditional expression (see next section) after the command letter. In all cases, if the condition represented is true, the statement will be executed, otherwise it will be skipped. The meaning of the conditional letters is as follows:

`Y`: The result of the most-recently executed `M:` (`Match`) statement was true (there was a match).

`N`: The result of the most-recently executed `M:` (`Match`) statement was false (there was no match).

`E`: The most-recently executed `FR:` (`File/Read`) statement encountered an end-of-file condition.

#### Conditional Expressions (Parentheses)

If there is parenthesized expression in a statement, it is a conditional expression, and the statement is processed only if the test has a value of 'true'. In EBNF, the conditional expression is 

`«conditional-expression»::=«value»«relational-operator»«value»`

`«relational-operator»::="<"|"<="|"="|">="|">"|"<>"`

If the `«value»`s are strings, comparison is done using lexical ordering; the default is case-insensitive, i.e., `"A"="a"` will be true. Case-sensitivity may be turned on for these comparisons and the M: statement; see the **P:** statement.

Example:
`R:Type message if x>y+z`

`T(#X>#Y+#Z):Condition met...`

psPILOT allows compound conditions using `&&` (and), `||` (or), and `!!` (not). See **Extensions Not Suggested in the Standard**, below.

### Extensions Suggested in the Standard

#### F: File Commands

The F command is listed as a Core Statement in the standard; however, no details are given. Some suggestions are given in Modifiers (section 4.3), but again without specifying behavior. 

psPILOT assumes that all file interaction will be as line-structured text, rather than structured data files.

File operations may be destructive of data. psPILOT does _not_ attempt to protect the author from such destruction.

psPILOT uses the following commands for file operations:

##### FA: Open File for Appending

`FA: «#handlevar», «filename»`

`«#handlevar»` is a numeric variable - _not_ a numeric value - which will hold the "file handle" for the file to be opened. `«filename»` is a system-dependent file name, including path. psPILOT does not check the filename for validity. `«#handlevar»` is subsequently used to identify the file for write operations and to close the file when done. If the file exists, the data in it will be preserved, and writes to the file will be appended at the end of the file. If the file does not exist, it will be created.

##### FB: Open File, Blank, for Writing

`FB: «#handlevar», «filename»`

`«#handlevar»` is a numeric variable - _not_ a numeric value - which will hold the "file handle" for the file to be opened. `«filename»` is a system-dependent file name, including path. psPILOT does not check the filename for validity. `«#handlevar»` is subsequently used to identify the file for write operations and to close the file when done. If the file exists, the data in it will be destroyed, and replaced by any data written to the file. If the file does not exist, it will be created.

##### FC: Close File

`FC: «#handlevar»`

`«#handlevar»` is the "file handle" created when the file was opened (using `FO:`, `FA:`, or `FB:`). Close the file. Further attempts to read or write to the file (unless it is re-opened with `FO:`, `FA:`, or `FB:`) will be invalid, and will cause an error.

##### FD: Delete File

`FD: «filename»`

Removes the file specified by `«filename»` from the system.

##### FO: Open File for Reading

`FO: «#handlevar», «filename»`

`«#handlevar»` is a numeric variable - _not_ a numeric value - which will hold the "file handle" for the file to be opened. `«filename»` is a system-dependent file name, including path. psPILOT does not check the filename for validity. `«#handlevar»` is subsequently used to identify the file for read operations and to close the file when done. If the file does not exist, the system will throw an error.

##### FR: Read a Line of Text from a File

`FR: «#handlevar», «$inputvariable»`

`«#handlevar»` is the "file handle" created when the file was opened using `FO:`. `«$inputvariable»`  is a string variable - _not_ a string value - in which the data read will be stored. 

If an attempt to read past the end of the existing data is made, a flag will be set, and conditional execution using the `E` condition flag will succeed.

##### FW: Write a Line of Text to a File

`FW: «#handlevar», «string-value»`

`«#handlevar»` is the "file handle" created when the file was opened with `FA:` or `FB:`. `«string-value»` is the data to be written to the file.

#### L: Link

`L: «filename»`

`«filename»` is a legal filename on the host system, which may include path information. psPILOT does not check the validity of the value, nor does it verify the existence of the file before attempting to load it.

The `L` (`Link`) statement is mentioned in section 4.1 of the Standard. `«filename»` is expected to be a program in the PILOT language, and replaces the previous program in memory. The Standard is silent on the matter of whether variables or status information (e.g., the `Accept` buffer or system variables) should be preserved or discarded upon `Link`; the documentation for Nevada PILOT implies that variables are preserved across a `Link` (which Nevada PILOT calls `LOAD`), but psPILOT does _not_ preserve variables or other program status information.

#### P: Problem (_alternatively, Parameters_)

The Standard suggests that this statement be used to define program sections ("problems") and to set parameters for the section. It also permits the use of `@P` as the target of a `J:`, meaning "jump to the next problem (`P:` statement)".

 `P: «text»`

`«text»` is optional, and treated by psPILOT as a comment, except for the following control sequences:

`W«number»` is a 'width control', which sets the width for word-wrapping in `T`, `Y`, and `N` statements. This control sequence should be separated by anything defined in regular expressions as a word boundary (technical note: the regexp used to find this is `\bw\d+\b`). Until the next `W` control sequence is encountered, word wrap in `T`, `N`, and `Y` statements will occur at the specified value - if a `J` or `U` statement causes program execution to bypass a `P` statement with a width control, that width control does not take effect.

The default width for word-wrapping is 75 characters.

`CS` instructs the psPILOT interpreter to use case-sensitive matching in `M` statements and parenthesized conditionals. When case-sensitive matching is turned on, "A"="a" will be false; it is normally true.

`CI` instructs the psPILOT interpreter to use case-insensitive matching in `M` statements and parenthesized conditionals. This is the default, but the instruction is provided to enable turning off case-sensitivity after it has been turned on.

The `P` (`Problem`) statement is mentioned in section 4.1 of the Standard. No discussion of what parameters should be supported, or with what specific syntax, is included.

#### W: Wait

`W: «seconds»`

`«seconds»` is a numeric expression evaluating to an integer representing the number of seconds to pause execution.

The `W` (`Wait`) statement is mentioned in section 4.1 of the Standard. 

#### Intraline Comments

Any program line may include a comment at the end of the statement; such comments start with `//` and run to the end of the line. If you need to use the string `//` as text rather than a comment indicator, prefix _both_ slashes with backslashes (`\/\/`).

`T: This text will be printed //this text will not`

`T: This text will be printed \/\/and so will this, including the slashes`

Intraline comments are mentioned in section 4.7 of the Standard.

### Extensions not suggested in the Standard

#### Modulus Operator

The Standard specifies only that `+`, `-`, `*`, and `/` be supported for integer math. The modulus operator, returning the _remainder_ from integer division (`/`), is also supported, using the operator character `%`.

`C:#ONE=5%2  //#ONE contains the value 1`

#### Compound Conditions

The PILOT standard (and most extant implementations) permit simple conditions only - that is, only one test may be performed. psPILOT has been extended to allow logical conjunction (_and_, `&&`), logical disjunction (_or_, `||`), and logical negation (_not_, `!!`), along with nested parentheses, in conditional expressions:

`T((#A>5)&&($B="FOO")):This will be typed if \#A is greater than 5 and \$B is the string FOO`

`T(!!(#B=0)):This will be typed if \#B is not equal to 0`

It is strongly recommended, but not enforced, that compound conditional expressions be fully parenthesized, as in the examples.

#### Shorthand Jumps ("@-Jumps")

In addition to the `@P`, `@M`, and `@A` jumps recommended in section 4.9 of the Standard, psPILOT supports `@R` for jumping to the most-recently executed `FR:` statement, and `@W` for jumping to the most-recently executed `FW:` statement.

## Known Bugs and Other Infelicities

There are no known bugs or other infelicities at the present time.

## Differences between IEEE Standard PILOT and psPILOT

### A: Permanent Differences

Numbers in brackets represent sections of the standard from which psPILOT differs.

1. Only the short-form commands (`T`, `A`, `M`, etc.) are accepted; the full keywords (`Type`, `Accept`, `Match`, etc.) cannot be used. [2.2, 2.3]
2. The `G` (`Graphic`) Core statement simply prints a message `psPILOT does not support graphics`, but does not throw an error. [2.2, 2.3]
3. Variables must use the type-indicator as the lead character; strings must be `$name`, numbers must be `#name`. [3.1, 3.2]
4. The system variables `%expression`, `%term`, `%factor`, `%nextstmt`, `%maxuses`, `%return*`, `%relation`, and `%text` are not supported. [2.3]
5. The standard states that early (pre-Standard) implementations of the `C` (`Compute`) statement 'dropped' into the host language (most PILOT interpreters were not in machine-native code, but ran 'on top' of other languages like BASIC) to evaluate the expression, and implies that the conformant interpreter should parse the expression and evaluate it directly, using conventions similar to those of BASIC. psPILOT returns to the original design, and internally converts the BASIC-convention expressions into PowerShell conventions, and then asks PowerShell to evaluate them. This is the reason that the system variables `%expression`, `%term`, and `%factor`, mentioned in 4. above, are not available. (The same technique is also used for handling conditional expressions.)
6. There is no defined limit on the number of levels of `U` statement nesting; this is the reason that the system variables `%maxuses` and `%return*`, mentioned in 4. above, are not supported.
7. String literals in conditions must be quoted (e.g., `T($foo="bar")`, not `T($foo=bar)`). However, they should ***not*** be quoted in assignments (e.g., `C:$foo=bar`, not `C:$foo="bar"`). [2.2, 4.5]
8. Labels are not limited to ten characters in length. [2.3]
9. Labels as the operand of `J:` and `U:` statements do not require the initial `*`, but permit it. This is for compatibility with PILOT implementations that also do not require it, or which prohibit it. [2.3]
10. The `H` modifier to `A` is not supported. (This is due to limitations in PowerShell). It _is_ supported for `T`, `Y`, and `N`. [4.3]

### B: To Be Changed

1. Labels must be on lines by themselves (that is, you cannot do `*HERE T: We're here`). [2.3]
2. Many Extensions in sections 4.1 through 4.4 of the standard are not supported (some will be unsupported permanently). [4.1, 4.2, 4.3, 4.4]

### Differences from Other PILOT Implementations

1. **RPILOT:** The `S` command (execute a system command) and the `X` command (Execute a string as a PILOT command) are not supported. Note that the Standard recommends that `S` be used for playing sound, and execution of system commands use the two-character command `XS`, with `X` suggested as the command for executing a string expression as a psPILOT statement.
2. **RPILOT** allows matching in the `M` statement of any of several words separating them with spaces (e.g., `M: YES YEP YEA`) . IEEE Standard 1154-1991 does not indicate that this is permissible, specifying only `,`, `!`, or `|` as separators (e.g., `M: YES, YEP, YEA`). psPILOT follows the standard, not RPILOT, in this.
3. **Nevada PILOT** allowed leading or trailing spaces in multiple-alternative matches - that is, `M:THIS,THAT` was different from `M:THIS , THAT` - the latter matched the word THIS followed by a space, or the word THAT following a space. psPILOT does not support matching leading or trailing spaces.
4. **Nevada PILOT** allowed `@P` and `@M` as targets for `U:` (`Use`) statements. psPILOT does not support this usage.
5. **Nevada PILOT** allowed indirect references in string variables by using multiple `$`, e.g., if `$foo` contains `bar` and `$bar` contains `baz`, one could use the expression `$$foo` and it would evaluate to `baz`. This usage is not supported by psPILOT.