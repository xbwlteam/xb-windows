'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"progname"  ' program/file name without .x or any .extent
VERSION	"0.0000"    ' version number - increment before saving altered program
'
' Description:
'		Test for sqlite3 in which it is assumed that XBasic has been recompiled
' 	to incorporate the sqlite3 library
'
' You can stop the PDE from inserting the following PROLOG comment lines
' by removing them from the prolog.xxx file in your \xb\xxx directory.
'
' Programs contain:  1: PROLOG          - no executable code - see below
'                    2: Entry function  - start execution at 1st declared func
' * = optional       3: Other functions - everything else - all other functions
'
' The PROLOG contains (in this order):
' * 1. Program name statement             PROGRAM "progname"
' * 2. Version number statement           VERSION "0.0000"
' * 3. Import library statements          IMPORT  "libName"
' * 4. Composite type definitions         TYPE <typename> ... END TYPE
'   5. Internal function declarations     DECLARE/INTERNAL FUNCTION Func (args)
' * 6. External function declarations     EXTERNAL FUNCTION FuncName (args)
' * 7. Shared constant definitions        $$ConstantName = literal or constant
' * 8. Shared variable declarations       SHARED  variable
'
' ******  Comment libraries in/out as needed  *****
'
'	IMPORT	"xma"   ' Math library     : SIN/ASIN/SINH/ASINH/LOG/EXP/SQRT...
'	IMPORT	"xcm"   ' Complex library  : complex number library  (trig, etc)
	IMPORT	"xst"   ' Standard library : required by most programs
	IMPORT  "sqlite3"
'	IMPORT	"xgr"   ' GraphicsDesigner : required by GuiDesigner programs
'	IMPORT	"xui"   ' GuiDesigner      : required by GuiDesigner programs
'

DECLARE FUNCTION  Entry ()
DECLARE CFUNCTION  callback (NotUsed, argc, argv, azColName)
DECLARE FUNCTION  ReadCStringArray$ (argc, argv, i, @null)
DECLARE FUNCTION  GetMemChars$ (ptr, len, @n$)
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
' Programs contain:
'   1. A PROLOG with type/function/constant declarations.
'   2. This Entry() function where execution begins.
'   3. Zero or more additional functions.
'
FUNCTION  Entry ()

	lpsqlite3 db
	XLONG rc
	XLONG zErrMessg

	XstDisplayConsole()
	XstClearConsole()

	PRINT "START OF PROCEDURE"
	x$ = INLINE$("Press Return")

	db$ = "mydb"
	rc = sqlite3_open(&db$, &db)
	IF rc THEN
		PRINT "Could not open database"
		sqlite3_close(db)
		x$ = INLINE$("Press Return")
		RETURN
	END IF

	PRINT "After OPEN"
	x$ = INLINE$("Press Return")

	sql$ = "DROP TABLE MyTable"
	rc = sqlite3_exec(db, &sql$, &callback(), 0, &zErrMessg)
	IF rc != $$SQLITE_OK THEN
		t$ = CSTRING$(zErrMessg)
		PRINT "Drop Error: "; t$
		x$ = INLINE$("Press Return")
		sqlite3_free(zErrMessg)
	END IF

	sql$ = "CREATE TABLE MyTable (MyCol CHAR(30), MyFlag INT)"
	rc = sqlite3_exec(db, &sql$, &callback(), 0, &zErrMessg)
	IF rc != $$SQLITE_OK THEN
		s$ = CSTRING$(zErrMessg)
		PRINT "Exec Error: "; s$
		sqlite3_free(zErrMessg)
		x$ = INLINE$("Press Return")
		RETURN
	END IF

	sql$ = "INSERT INTO MyTable (MyCol, MyFlag) VALUES (\"Hello World\", 1)"
	rc = sqlite3_exec(db, &sql$, &callback(), 0, &zErrMessg)
	IF rc != $$SQLITE_OK THEN
		s$ = CSTRING$(zErrMessg)
		PRINT "Exec Error: "; s$
		sqlite3_free(zErrMessg)
		x$ = INLINE$("Press Return")
		RETURN
	END IF

	zErrMessg = 0
	sql$ = "INSERT INTO MyTable (MyCol, MyFlag) VALUES (\"Hello Programmer\", 1)"
	rc = sqlite3_exec(db, &sql$, &callback(), 0, &zErrMessg)
	IF rc != $$SQLITE_OK THEN
		s$ = CSTRING$(zErrMessg)
		PRINT "Exec Error: "; s$
		sqlite3_free(zErrMessg)
		x$ = INLINE$("Press Return")
		RETURN
	END IF

	sql$ = "INSERT INTO MyTable (MyCol, MyFlag) VALUES (\"Hello Cat\", 2)"
	zErrMessg = 0
	rc = sqlite3_exec(db, &sql$, &callback(), 0, &zErrMessg)
	IF rc != $$SQLITE_OK THEN
		s$ = CSTRING$(zErrMessg)
		PRINT "Exec Error: "; s$
		sqlite3_free(zErrMessg)
		x$ = INLINE$("Press Return")
		RETURN
	END IF

	zErrMessg = 0
	void = 0
	sql$ = "SELECT * FROM MyTable WHERE MyFlag = 1"
	rc = sqlite3_exec(db, &sql$, &callback(), &void, &zErrMessg)
	PRINT "rc: "; rc
	x$ = INLINE$("Press Return")
	IF rc != $$SQLITE_OK THEN
		PRINT "Got Here"
		s$ = XstNextCLine$(zErrMessg, @ix, @done)
		PRINT "Exec Error: "; s$
		sqlite3_free(zErrMessg)
		x$ = INLINE$("Press Return")
		RETURN
	END IF

	sql$ = "SELECT * FROM MyTableOne" + CHR$(0)
	rc = sqlite3_exec(db, &sql$, &callback(), 0, &zErrMessg)
	IF rc != $$SQLITE_OK THEN
		s$ = CSTRING$(zErrMessg)
		PRINT "Exec Error: "; s$
		sqlite3_free(zErrMessg)
		x$ = INLINE$("Press Return")
		RETURN
	END IF

	sqlite3_close(db)
	x$ = INLINE$("Completed OK - Press Return")

END FUNCTION
'
'
' #########################
' #####  callback ()  #####
' #########################
'
CFUNCTION  callback (NotUsed, argc, argv, azColName)

	FOR i = 0 TO argc - 1
		s$ = ReadCStringArray$ (argc, azColName, i, @null)
		PRINT s$,
		s$ = ReadCStringArray$ (argc, argv, i, @null)
		IF null THEN
			PRINT "NULL"
		ELSE
			PRINT s$
		END IF
	NEXT

	RETURN 0

END FUNCTION
'
'
' #################################
' #####  ReadCStringArray ()  #####
' #################################
'
FUNCTION  ReadCStringArray$ (argc, argv, index, @null)
' Function Notes:
' Summary: Read a string element from a C array pointed to by argv
' End Function Notes
' --------------------------------------------------------------------
	null = $$FALSE

	IF index < 0 || index >= argc THEN
		RETURN ""
	END IF

	n = SIZE(XLONG)
	p1 = argv + index * n
	p2 = XLONGAT(p1)
	IF p2 = 0 THEN
		null = $$TRUE
		RETURN ""
	END IF
	s$ = CSTRING$(p2)

	RETURN s$

END FUNCTION
'
'
' #############################
' #####  GetMemChars$ ()  #####
' #############################
'
FUNCTION  GetMemChars$ (ptr, len, @n$)

	s$ = ""
	n$ = ""
	FOR i = ptr TO ptr + len - 1
		s$ = s$ + CHR$(UBYTEAT(i))
		n$ = n$ + STRING$(UBYTEAT(i)) + " "
	NEXT

	RETURN s$

END FUNCTION
END PROGRAM
