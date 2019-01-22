R: Testing the various @-jumps
T: This is prelude text. Please type text or 'END'
A: $FOO
T($FOO<>"END"): You typed $FOO
J($FOO<>"END"): @A
T: END OF @A Testing
T: TEST JUMP TO @M
T: TYPE TEXT
A: $BAR
J: @M
T: This should not be printed
M: BAR
Y: You typed 'bar'
T: End of @M TEST
T: Test Jump @P
T: This will be printed with normal width
J: @P
T: This will not be printed
P: W20
T: This will be printed wrapping at 20 characters.
P: W75
T: End of @P test.
T: Testing @R
FO: #TESTFILE, testatjumps.p
FR: #TESTFILE, $LINE
JE: *ENDLOOP
T: $LINE
J: @R
*ENDLOOP
FC: #TESTFILE
T: END of @R TEST
T: Test @W
T: Enter text or 'END'
A: $INLINE
FB: #OUTFILE, TEST.TXT
FW: #OUTFILE, $INLINE
T: TYPE MORE TEXT OR 'END'
A: $INLINE
J($INLINE<>"END"):@W
FC: #OUTFILE
T: END OF TESTS
E:
