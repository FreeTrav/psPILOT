T: This is a properly marked line.
 : This is a repeat-command line; it should print.
 : Another continuation line
 : The next line should link to a different source file
T: A properly marked line again
C:$foo = bar
A: $BAR
M: JUMP
JY:@P
M: BAR
TN: You didn't type BAR
JN:@A
C:$elephant = $foo$foo\bar
T:$elephant
C: #FOO = (5/2) + (5/2)
C: $OOF = FOO
T: This is the value of \#FOO: #FOO; \$OOF is $OOF
T(#foo=5): The string matched
A: $BAR
M: YES
JN: @M
T: Typed yes
M: No
JN: *SKIP
T: Typed No
*SKIP
P:
T: exit decision struct
E:


