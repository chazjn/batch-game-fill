@echo off
setlocal ENABLEDELAYEDEXPANSION

set height=8
set width=16

SET TICKCOUNT=1
set FILLCOUNT=0
set /A CELLCOUNT=%HEIGHT%*%WIDTH%

SET DEAD=FALSE
set BOMBCOUNT=10
set MONSTER=FALSE
set MONSTER_CLEAN=FALSE


::set starting position, approx centre
SET /A X=%WIDTH%/2
SET /A Y=%HEIGHT%/2


set PREV_X=%X%
set PREV_Y=%Y%

:: set empty grid
FOR /L %%h IN (1, 1, %HEIGHT%) DO (
		FOR /L %%w IN (1, 1, %WIDTH%) DO (
			SET "G[%%w][%%h]= "
		)	
)

:: set starting position
SET "G[!X!][!Y!]=@


:TOP
cls
call :display
echo !BOMBCOUNT! bombs left
echo %FILLCOUNT%/%CELLCOUNT% cells complete
echo %TICKCOUNT% ticks elapsed

IF [%DEAD%]==[TRUE] (
	GOTO GAMEOVER
)

IF %FILLCOUNT% EQU %CELLCOUNT% (
	GOTO COMPLETE
)





:: 1 X = default (no move)
:: 2 I = up
:: 3 J = left
:: 4 K = down
:: 5 L = right
:: 6 Z = bomb
:: 7 Q = quit
CHOICE /C XIJKLZQ /T 1 /D X /N
SET EL=!ERRORLEVEL!


:: quit
IF !EL! EQU 7 (
	GOTO GAMEOVER
)

:: bomb
IF !EL! EQU 6 (
	
	IF %BOMBCOUNT% EQU 0 (
		GOTO TOP
	)
	IF !G[%X%][%Y%]!==o (
		GOTO TOP
	)
	
	SET DROPPEDBOMB=TRUE
	SET /A BOMBCOUNT=%BOMBCOUNT%-1
)


:: right
IF !EL! EQU 5 (
	IF !X! EQU !WIDTH! (
		SET /A X=1
	) ELSE (
		SET /A X=!X!+1
	)
)

::down
IF !EL! EQU 4 (
	IF !Y! EQU !HEIGHT! (
		SET /A Y=1
	) ELSE (
		SET /A Y=!Y!+1
	)
)

::left
IF !EL! EQU 3 (
	IF !X! EQU 1 (
		SET /A X=!WIDTH!
	) ELSE (
		SET /A X=!X!-1
	)
)

::up
IF !EL! EQU 2 (
	IF !Y! EQU 1 (
		SET /A Y=!HEIGHT!
	) ELSE (
		SET /A Y=!Y!-1
	)
)

:: If NOT nothing
IF NOT !EL! EQU 1 (

	IF !DROPPEDBOMB!==TRUE (
		SET G[!X!][!Y!]=o
		SET DROPPEDBOMB=FALSE
	) ELSE (
		REM see if we have a bomb there to pickup
		IF [!G[%X%][%Y%]!]==[o] (
			SET /A BOMBCOUNT=%BOMBCOUNT%+1
		)
		
		REM set the 'head'
		SET G[!X!][!Y!]=@
		
		REM set the 'tail'
		IF NOT [!G[%PREV_X%][%PREV_Y%]!]==[o] (
			SET G[!PREV_X!][!PREV_Y!]=.
		)
	)

	SET PREV_X=!X!
	SET PREV_Y=!Y!
)


:: randomly spawn 'monsters'
:: monsters move in 
:: > left 
:: < right
:: ^ down
:: v up 

:: first clean up the last monster
IF [%MONSTER_CLEAN%]==[TRUE] (
	SET "G[%x_prev_monster%][%y_prev_monster%]= "
	SET MONSTER_CLEAN=FALSE
	SET MONSTER=FALSE
)



:: 1 = Up, 2 = Down, 3 = Left, 4 = Right
:: first calculate starting direction (up, down, left right)
:: then calculate starting X, Y (has to be on edge)
:: then calculate the speed.
:: (1) normal speed = moves every ticks
:: (2,3) slow speed = on even ticks
IF [%MONSTER%]==[FALSE] (

	set x_monster=1
	set y_monster=1

	REM calculate probability of monster appearing
	SET /A probability_monster=%RANDOM% * 20 / 32768 + 1
	IF !probability_monster! GEQ 20 (
	
		SET /A speed_monster=%RANDOM% * 3 / 32768 + 1	
		SET /A direct_monster=%RANDOM% * 4 / 32768 + 1
		IF !direct_monster! EQU 1 (
			SET /A x_monster=%RANDOM% * %width% / 32768 + 1
			SET /A y_monster=%height%
		)
		IF !direct_monster! EQU 2 (
			SET /A x_monster=%RANDOM% * %width% / 32768 + 1
			SET /A y_monster=1
		)
		IF !direct_monster! EQU 3 (
			SET /A x_monster=%width%
			SET /A y_monster=%RANDOM% * %height% / 32768 + 1
		)
		IF !direct_monster! EQU 4 (
			SET /A x_monster=1
			SET /A y_monster=%RANDOM% * %height% / 32768 + 1
		)
		
		SET MONSTER=TRUE
	)
) 



IF [%MONSTER%]==[TRUE] (

	IF !speed_monster! GEQ 2 (
		SET /A EVEN=%TICKCOUNT% %% 2
		IF !EVEN! NEQ 0 (
			GOTO SKIP_MONSTER
		)
	)

	REM get this current monster cell so we can set it as blank on the next display
	SET x_prev_monster=%x_monster%
	SET y_prev_monster=%y_monster%
	
	REM see if a monster has touched a bomb
	IF [!G[%x_monster%][%y_monster%]!]==[o] (
		SET G[%x_monster%][%y_monster%]=#
		SET MONSTER_CLEAN=TRUE
	) ELSE (

		IF !direct_monster! EQU 1 (
			SET G[%x_monster%][%y_monster%]=v
			SET /A y_monster=%y_monster%-1
			IF %y_monster% EQU 1 (SET MONSTER_CLEAN=TRUE) 
		)
		IF !direct_monster! EQU 2 (
			SET G[%x_monster%][%y_monster%]=^^
			SET /A y_monster=%y_monster%+1
			IF %y_monster% EQU %height% (SET MONSTER_CLEAN=TRUE) 
		)
		IF !direct_monster! EQU 3 (
			SET G[%x_monster%][%y_monster%]=^>
			SET /A x_monster=%x_monster%-1
			IF %x_monster% EQU 1 (SET MONSTER_CLEAN=TRUE) 
		)
		IF !direct_monster! EQU 4 (
			SET G[%x_monster%][%y_monster%]=^<
			SET /A x_monster=%x_monster%+1
			IF %x_monster% EQU %width% (SET MONSTER_CLEAN=TRUE) 
		)
	)
	SET "G[%x_prev_monster%][%y_prev_monster%]= "	
)
:SKIP_MONSTER



:: monster collision detection
IF [!G[%X%][%Y%]!]==[^^] (
	SET G[!X!][!Y!]=x
)
IF [!G[%X%][%Y%]!]==[v] (
	SET G[!X!][!Y!]=x
)
IF [!G[%X%][%Y%]!]==[^>] (
	SET G[!X!][!Y!]=x
)
IF [!G[%X%][%Y%]!]==[^<] (
	SET G[!X!][!Y!]=x
)

SET /A TICKCOUNT=%TICKCOUNT%+1


goto top

:DISPLAY
:: As we draw each cell we can count how many are filled
:: SET FILLCOUNT to 1 because we need to count the 'head' (@)
:: we are also check for 'X' (died)
SET FILLCOUNT=1
SET TOP=
SET BOT=
FOR /L %%h IN (1, 1, %height%) DO (

	IF %%h EQU 1 (FOR /L %%w IN (1, 1, %width%) DO (SET TOP=_!TOP!))
	IF %%h EQU 1 ECHO .!TOP!.
	
	SET ROW=
	FOR /L %%w IN (1, 1, %WIDTH%) DO (
			IF [!G[%%w][%%h]!]==[.] (
				SET /A FILLCOUNT=!FILLCOUNT!+1
			)
			IF [!G[%%w][%%h]!]==[x] (
				SET DEAD=TRUE
			)
			
			SET ROW=!ROW!!G[%%w][%%h]!
	)
	
	ECHO ^|!ROW!^|
		
	IF %%h EQU %height% (FOR /L %%w IN (1, 1, %width%) DO (SET BOT=~!BOT!))
	IF %%h EQU %height% ECHO `!BOT!'	
)
GOTO EOF

:COMPLETE
echo Congratulations^^!
GOTO EOF


:GAMEOVER
echo Game over^^!
GOTO EOF


:CRUFT



:EOF



