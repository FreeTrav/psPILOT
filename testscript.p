R: Tests various commands as they're added to psPILOT
U: *TESTLABEL
E:

*RPTCMDS
T: This is a properly marked line.
 : This is a repeat-command line; it should print.
 : Another continuation line
T: A properly marked line again
E:

*JUMPAT
T: Type a word:
A: $BAR
M: JUMP
TY:Jumping to @P (next P line)
JY:@P
M: BAR
TN: You didn't type BAR
TN: Jumping to @A (back to the previous A line). Type a word:
JN:@A
T: You typed BAR, test ending.
P:
T: @J works.
E:

*COMPUTE
R: Tests numerics
C: #NUMBER = (22 / 7) * 100
T: \#NUMBER should be 314. Actually is #NUMBER
R: Test strings
C: $STRING = TEXT
T: \$STRING is $STRING. Test head-concatenation:
C: $HEAD = $STRING\BOOK
T: \$HEAD should be TEXTBOOK: $HEAD. Test tail concatenation:
C: $TAIL = TELE$STRING
T: \$TAIL should be TELETEXT: $TAIL. Test variable-variable concatenation:
C: $VARVAR = $HEAD$TAIL
T: \$VARVAR should be TEXTBOOKTELETEXT: $VARVAR
E:

*TESTLINK
L:TESTLINK.P
E:

*TESTLABEL
T: Entered TESTLABEL
J: *NOSTAR
T: This line should not be printed
*NOSTAR
T: This line is printed.
E:

