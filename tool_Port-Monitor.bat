@echo off &setlocal EnableDelayedExpansion
call :setESC &call :port_list
call :setting &goto init

:setting
set show_detail=1
set color_text=1
set enter_mode=img
set quick_mode=0
exit /B

:main
cls
if "%enter%"=="exit" exit
if not defined enter (
if "%enter_mode%"=="img" (set /p "enter=Please enter The Image name(or /pid):") ^
else if "%enter_mode%"=="pid" (set /p "enter=Please enter The PID(or /img):") ^
else (set "enter_mode=img")
) else (goto command)
goto main

:command
set "cmd_all=img pid all wg"
if "!enter:~0,1!"=="/" (
for %%a in (%cmd_all%) do if !enter:~1!==%%a goto %enter%
goto /help)
goto check

REM Commands
:/help
set "enter="
echo [help]
echo. &echo Commands:
for %%a in (%cmd_all%) do echo /%%a
pause &goto main
:/img
set "enter_mode=img" &set "enter=" &goto main
:/pid
set "enter_mode=pid" &set "enter=" &goto main
:/all
goto all
:/wg
goto watchdog

:check
if defined enter (
if %enter_mode%==img (
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq %enter%" ^| findstr /b /i %enter%') do set pid=%%a &goto start
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq %enter%.exe" ^| findstr /b /i %enter%.exe') do set pid=%%a &goto start
) else if %enter_mode%==pid (
tasklist /fi "pid eq %enter%" | findstr %enter% 2>&1>nul
if !errorlevel!==0 set pid=%enter% &goto start))
set "enter=" &goto main

:start
cls &color 07
echo loading......
for /f "tokens=1" %%a in ('tasklist /fi "pid eq %pid%" ^| findstr %pid%') do set imgname=%%a
title=Port Monitor - %imgname%
tasklist /fi "pid eq %pid%" | findstr "%pid%" 2>&1>nul || goto died
set "enter="
if "%quick_mode%"=="1" (color 0a &goto quick_loop) else (goto loop)

:loop
cls
tasklist /fi "pid eq %pid%"
echo.
netstat -ano | findstr /i "PID"
set /a count=0 &set /a slen=3 &for /l %%0 in (0, 1, !slen!) do set /a sortc[%%0]=0
for /l %%0 in (0, 1, 2) do set /a total[%%0][0]=0 &set /a est[%%0][0]=0 &set /a listen[%%0][0]=0
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /e %pid%') do (
for /f "tokens=5" %%b in ("%%a") do if %%b==%pid% set/a count+=1 &set output[!count!]=%%a)

if !count!==0 (echo. &echo ^(Empty^)) else (
for /l %%0 in (1, 1, !count!) do for /f "tokens=1-5" %%a in ("!output[%%0]!") do (

if "%show_detail%"=="1" (set "bool="
for /f "tokens=2,4 delims=:" %%p in ("%%b:%%c") do for /l %%1 in (0, 1, %port_cnt%) do (
if %%p==!port_list[%%1][0]! (set "bool=1") else (if %%q==!port_list[%%1][0]! set "bool=1")
if defined bool set "var1=%%0" &set "var2=%%1" & ^
set "varp=!port_list[%%1][0]!" &set "port_info=!port_list[%%1][1]!" & call :port_replace)
set "output[%%0]=!output[%%0]:%localhost%=localhost!")

if %%a==TCP (
set "LH="
set "b=%%b" &set "c=%%c"
for %%l in (%localhost% %nullhost% [::]) do ^
set "l=%%l" &if "!c:~0,4!"=="!l:~0,4!" (set "LH=1"
if %%d==LISTENING (set /a listen[0][0]+=1 &set /a listen[1][0]+=1 & ^
set /a sortc[0]+=1 &set "sort[0][!sortc[0]!]=!output[%%0]:%localhost%=localhost!") ^
else if %%d==ESTABLISHED (set /a est[0][0]+=1 &set /a est[1][0]+=1 & ^
set /a sortc[2]+=1 &set "sort[2][!sortc[2]!]=!output[%%0]:%localhost%=localhost!"))

if not defined LH ^
if %%d==ESTABLISHED (set /a est[0][0]+=1 &set /a est[2][0]+=1 & ^
set /a sortc[3]+=1 &set "sort[3][!sortc[3]!]=!output[%%0]!") ^
else if %%d NEQ LISTENING (set /a sortc[1]+=1 &set "sort[1][!sortc[1]!]=!output[%%0]!") ^
else if %list_w%==%pid% (set /a listen[2][0]+=1) else (set "kill_port=!output[%%0]!" &goto kill)))
for /l %%0 in (1, 1, !count!) do set "output[!count!]="

if "%color_text%"=="1" (
for /l %%0 in (0, 1, !slen!) do (if not !sortc[%%0]!==0 echo.
for /l %%1 in (1, 1, !sortc[%%0]!) do (
if %%0==0 echo   %ESC%[103;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==1 echo   %ESC%[46;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==2 echo   %ESC%[47;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==3 echo   %ESC%[44;1m!sort[%%0][%%1]!%ESC%[0m))) ^
else (set "state_space=                              "
for /l %%0 in (0, 1, !slen!) do if not !sortc[%%0]!==0 (
echo.
if %%0==1 echo   !state_space![HANDSHAKE] &echo.
if %%0==2 echo   !state_space![ESTABLISHED] &echo.
if %%0==3 if !sortc[2]!==0 echo   !state_space![ESTABLISHED] &echo.
for /l %%1 in (1, 1, !sortc[%%0]!) do echo   !sort[%%0][%%1]!)))

set /a total[0][0]=!count!
if %bln%==1 (for /l %%a in (0, 1, 2) do (set /a est[%%a][2]=est[%%a][0] &set /a total[%%a][2]=total[%%a][0]) &set bln=0)
for /l %%0 in (0, 1, 2) do (
if !est[%%0][0]! gtr !est[%%0][1]! (set "est[%%0][1]=!est[%%0][0]!") ^
else if !est[%%0][0]! lss !est[%%0][2]! (set "est[%%0][2]=!est[%%0][0]!")
if !total[%%0][0]! gtr !total[%%0][1]! (set "total[%%0][1]=!total[%%0][0]!") ^
else if !total[%%0][0]! lss !total[%%0][2]! (set "total[%%0][2]=!total[%%0][0]!")
if !listen[%%0][0]! gtr !listen[%%0][1]! (set "listen[%%0][1]=!listen[%%0][0]!") ^
else if !listen[%%0][0]! lss !listen[%%0][2]! (set "listen[%%0][2]=!listen[%%0][0]!"))

set "title=State Total Local_Host(max|min) Foreign_Host(max|min)"
set /a interval=8 &set Title_Instant_Print=false
set /a data_len=3
set "data[1]=LISTENING !listen[0][0]! !listen[1][0]!_(!listen[1][1]!|!listen[1][2]!) !listen[2][0]!_(!listen[2][1]!|!listen[2][2]!)"
set "data[2]=ESTABLISHED !est[0][0]! !est[1][0]!_(!est[1][1]!|!est[1][2]!) !est[2][0]!_(!est[2][1]!|!est[2][2]!)"
set "data[3]=Total %total[0][0]% %total[1][0]%_(%total[1][1]%|%total[1][2]%) %total[2][0]%_(%total[2][1]%|%total[2][2]%)"
call :table

if not !Title_Instant_Print!==true (
echo. &echo   !title_print:_= ! &echo.
for /l %%0 in (1, 1, %data_len%) do echo   !table[%%0]:_= ! &set "table[%%0]=")
set "title_print="

title=Port Monitor - %imgname%(%pid%) Total:%total[0][0]% [Est:%est[0][0]% (LH:%est[1][0]% FH:%est[2][0]%)]
REM timeout /T 3
echo.
choice /n /c pmnxc /t 3 /d c /m "P - Pause | M - Back to menu:"
if %errorlevel%==1 pause
if %errorlevel%==2 goto init
if %errorlevel%==3 start %~f0
if %errorlevel%==4 exit
tasklist /fi "pid eq %pid%" | findstr "%pid%" 2>&1>nul || goto died
goto loop

:table
for /l %%0 in (1, 1, !interval!) do set interval_= !interval_!
for %%a in (!title!) do set "title_print=!title_print!%%a!interval_!" &set "interval_=!interval_:~0,6!"
set "interval_="
for %%a in (!title!) do (set str=%%a &set /a str_cnt=0
for /l %%0 in (1, 1, 35) do if defined str (set str=!str:~1!
if defined str set /a str_cnt+=1)
set title_len=!title_len! !str_cnt!)
set title_len=!title_len:~1!
set /a len=0 &for %%a in (!title_len!) do set /a len+=1 &set /a title_len_[!len!]=%%a
set "title_len="
if !data_len! geq 50 set Title_Instant_Print=true
if !Title_Instant_Print!==true echo !title_print!

for /l %%t in (1, 1, !data_len!) do (
set /a count=0 &set /a interval=8

if defined data[%%t] (
for %%a in (!data[%%t]!) do (
set str=%%a &set /a str_cnt=0
for /l %%0 in (1, 1, 25) do if defined str (set str=!str:~1!
if defined str set /a str_cnt+=1)
set /a count+=1
set /a str_len[!count!]=!str_cnt! &set data_[!count!]=%%a)

for /l %%0 in (1, 1, !len!) do (
if %%0 gtr 1 set /a interval=6
set /a space_[%%0]=title_len_[%%0]-!str_len[%%0]!+!interval!
if not %%0==!len! for /l %%1 in (1, 1, !space_[%%0]!) do set space[%%0]= !space[%%0]!
set table[%%t]=!table[%%t]!!data_[%%0]!!space[%%0]!
for /l %%1 in (1, 1, !space_[%%0]!) do set "space[%%0]="
set /a space_[%%0]=0 &set "data_[%%0]=")

if !Title_Instant_Print!==true echo !table[%%t]!
) else (set data[%%T]=NULL))
exit /b

:quick_loop
cls
echo [Quick mode] Image Name: %imgname% ^| PID: %pid% &echo.
echo   Proto  Local Address          Foreign Address        State           PID
set /a count=0 &set /a slen=2 &for /l %%0 in (0, 1, !slen!) do set /a sortc[%%0]=0
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /e %pid%') do (
for /f "tokens=5" %%b in ("%%a") do if %%b==%pid% set/a count+=1 &set output[!count!]=%%a)
if !count!==0 (echo. &echo ^(Empty^)) else (
for /l %%0 in (1, 1, !count!) do for /f "tokens=4" %%a in ("!output[%%0]!") do (
if %%a==LISTENING (set /a sortc[0]+=1 &set "sort[0][!sortc[0]!]=!output[%%0]!") ^
else if %%a==ESTABLISHED (set /a sortc[2]+=1 &set "sort[2][!sortc[2]!]=!output[%%0]!") ^
else (set /a sortc[1]+=1 &set "sort[1][!sortc[1]!]=!output[%%0]!"))
set "state_space=                              "
for /l %%0 in (0, 1, !slen!) do if not !sortc[%%0]!==0 (
echo.
if %%0==1 echo   !state_space![HANDSHAKE] &echo.
if %%0==2 echo   !state_space![ESTABLISHED] &echo.
for /l %%1 in (1, 1, !sortc[%%0]!) do echo   !sort[%%0][%%1]!))
echo.
choice /n /c pmnxc /t 1 /d c /m "P - Pause | M - Back to menu:"
if %errorlevel%==1 pause
if %errorlevel%==2 goto init
if %errorlevel%==3 start %~f0
if %errorlevel%==4 exit
goto quick_loop

:port_replace
set "output[%var1%]=!output[%var1%]::%varp%=:%port_info%!"
exit /b

:alive
tasklist /fi "pid eq %pid%" | findstr "%pid%" 2>&1>nul || goto died
echo %imgname% is alive.
goto alive

REM /!\ #undone1
:kill
cls &color 4f
tasklist /fi "pid eq %pid%" &echo.
echo %kill_port% &echo. &goto kill_
:kill_
set /p "enter=The Port "LISTENING" had Connect to Foreign Host. Do you want to *KILL* this Process(%imgname%)?[y/n]:"
tasklist /fi "pid eq %pid%" | findstr "%pid%" 2>&1>nul || echo %imgname% is Closed. &&goto kill_close
if not %enter%==nul (
if %enter%==y taskkill /f /t /pid %pid% &pause &goto init
if %enter%==n color 0c &set list_w=%pid% &goto start)
set enter=nul &goto kill_
:kill_close
set /p enter=Do you wnat to Save report to log?[y/n]:
if not %enter%==nul (
if %enter%==y echo yo
if %enter%==n goto init)
set enter=nul &goto kill_close

:kill_Loop
taskkill /f /t /im %imgname%
set /a killc+=1
echo %killc%
if %killc%==80 (goto init)
if %killc% geq 50 (timeout /t 3)
goto kill_Loop

:died
cls
echo %imgname% is Closed.
pause
goto init

REM /!\ #undone2
:all
cls
set /a count=0 &set /a slen=2 &for /l %%0 in (0, 1, !slen!) do set /a sortc[%%0]=0
for /l %%0 in (0, 1, 2) do set /a total[%%0][0]=0 &set /a est[%%0][0]=0

for /f "tokens=*" %%a in ('netstat -ano') do set /a count+=1 &set output[!count!]=%%a

if !count!==0 (echo. &echo ^(Empty^)) else (
for /l %%0 in (1, 1, !count!) do (for /f "tokens=1-5" %%a in ("!output[%%0]!") do (for /f "delims=:" %%l in ("%%b") do (
if %%l==127.0.0.1 (set /a total[1][0]+=1) else (set /a total[2][0]+=1)
if not %%d==ESTABLISHED (set /a sortc[0]+=1 &set sort[0][!sortc[0]!]=!output[%%0]!) else (set /a est[0][0]+=1)
if %%d==ESTABLISHED if %%l==127.0.0.1 (set /a sortc[1]+=1 &set sort[1][!sortc[1]!]=!output[%%0]!
) else if not %%l==nul (set /a sortc[2]+=1 &set sort[2][!sortc[2]!]=!output[%%0]!))))
if %detail%==0 (
for /l %%0 in (0, 1, !slen!) do (if not !sortc[%%0]!==0 (echo. &if %%0==1 (echo ESTABLISHED: &echo.
) else if %%0==2 if !sortc[1]!==0 echo ESTABLISHED: &echo.) &for /l %%1 in (1, 1, !sortc[%%0]!) do (echo   !sort[%%0][%%1]!))
) else if %detail%==1 (
set /a count=0
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /e %pid%') do (
for /f "tokens=5" %%b in ("%%a") do (if %%b==%pid% (set/a count+=1 &set output!count!=%%a)))

for /l %%0 in (0, 1, !slen!) do (if not !sortc[%%0]!==0 (echo. &if %%0==1 (echo ESTABLISHED: &echo.
) else if %%0==2 if !sortc[1]!==0 echo ESTABLISHED: &echo.) &for /l %%1 in (1, 1, !sortc[%%0]!) do (
set temp=!sort[%%0][%%1]! &set temp=!temp:127.0.0.1=[localhost]! &set temp=!temp::443=:https!
for /f "tokens=5" %%a in ("!sort[%%0][%%1]!") do (
for /f "tokens=1" %%b in ('tasklist /fi "pid eq %%a" ^| findstr %%a') do (set temp=!temp:%%a=%%b!))
echo   !temp!))))

set /a total[0][0]=!count! &for /l %%0 in (1, 1, !slen!) do set est[%%0][0]=!sortc[%%0]!
if %bln%==1 (for /l %%a in (0, 1, 2) do (
set /a est[%%a][2]=est[%%a][0] &set /a total[%%a][2]=total[%%a][0]) &set bln=0)

for /l %%0 in (0, 1, 2) do (
if !est[%%0][0]! gtr !est[%%0][1]! (set /a est[%%0][1]=est[%%0][0])
if !est[%%0][0]! lss !est[%%0][2]! (set /a est[%%0][2]=est[%%0][0])
if !total[%%0][0]! gtr !total[%%0][1]! (set /a total[%%0][1]=total[%%0][0])
if !total[%%0][0]! lss !total[%%0][2]! (set /a total[%%0][2]=total[%%0][0]))

title=Port Monitor - netstat Total:%total[0][0]% Est:%est[0][0]% ^(LH:%est[1][0]% FH:%est[2][0]%^)
echo.
echo Total:%total[0][0]%^(%total[0][1]%^|%total[0][2]%^) localhost:%total[1][0]%^(%total[1][1]%^|%total[1][2]%^) foreignhost:%total[2][0]%^(%total[2][1]%^|%total[2][2]%^)
echo.
echo ^[ESTABLISHED:%est[0][0]%^(%est[0][1]%^|%est[0][2]%^) localhost:%est[1][0]%^(%est[1][1]%^|%est[1][2]%^) foreignhost:%est[2][0]%^(%est[2][1]%^|%est[2][2]%^)^]
timeout /t 3
goto all
echo.
set /p enter=Press 'Enter' to reload or Enter 'b' to Back to main menu:
if %enter%==b goto init
set enter=nul &goto all

REM /!\ #undone3
:watchdog
start %~f0
goto wg_loop
REM =====/!\=====
set "mypath=%~dp0" &set "label_name=wg_content"
set /a rl_cnt=0 &set "start="
if not exist "%mypath%watchdog.txt" (
for /f "tokens=*" %%a in (%~f0) do (
set "line=%%a" &if "!line:~0,1!"==":" set "start="
if "!line:~0,1!"==":" for %%b in (!line!) do if %%b==:!label_name! set "start=1"
if defined start echo %%a > D:\watchdog.txt

)
)
goto main
REM /!\ #undone3
:wg_loop
cls
set /a owlisten=0
set /a wglisten=0
set /a wgest=0
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /i "LISTEN" ^| findstr /v "127.0.0.1" ^| findstr /v "0.0.0.0:0"') do (
set /a wglisten+=1)
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /i "ESTABLISHED" ^| findstr /v "127.0.0.1" ^| findstr /v "0.0.0.0:0"') do (
set /a wgest+=1)
for /f %%a in ('netstat -ano ^| findstr /i "LISTEN" ^| findstr /b /v "127.0.0.1" ^| findstr /v "0.0.0.0:0" ^| findstr /v "::"') do (
set /a owlisten+=1)
if !owlisten! gtr 0 (goto kill)

echo LISTENING:
netstat -ano | findstr /i "LISTEN" | findstr /b /v "127.0.0.1" | findstr /v "0.0.0.0:0"
echo.
echo ESTABLISHED:
netstat -ano | findstr /i "ESTABLISHED" | findstr /v "127.0.0.1" | findstr /v "0.0.0.0:0"
echo.
route print -6 | findstr /i /v "Network Connection" | findstr /i /v "Loopback Adapter"
echo.
route print -4 | findstr /i /v "Network Connection" | findstr /i /v "Loopback Adapter"
echo.
echo LISTENING:%wglisten% ESTABLISHED:%wgest%
timeout /t 5
echo.
goto wg_loop

:init
cls
title=Port Monitor &color 0e &chcp 1252 >nul
set "enter=" &set pid=0 &set imgname=0
set /a total[3][3] &set /a est[3][3] &set /a listen[3][3]
set /a estc[3][3]
set bln=1 &set list_w=nul &set list_b=nul
for /l %%0 in (0, 1, 2) do for /l %%1 in (0, 1, 2) do (
set /a total[%%0][%%1]=0 &set /a est[%%0][%%1]=0
set /a listen[%%0][%%1]=0 &set /a hand[%%0][%%1]=0 &set /a estc[%%0][%%1]=0)
if not defined enter_mode set "enter_mode=img"
if not defined show_detail set show_detail=1
goto main

REM Cool Stuff win10colors.cmd by Michele Locati (github/mlocati). Respect!!!
:setESC
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set ESC=%%b
  exit /B 0
)
exit /B 0

:port_list
set "localhost=127.0.0.1" &set "nullhost=0.0.0.0"
REM ***** Can expansion *****
set "port_table[0][0]=80,443"
set "port_table[0][1]=http,https"

REM port_list[0][0]=80 port_list[0][1]=http ...
for /l %%0 in (0, 1, 0) do for /l %%1 in (0, 1, 1) do (
set /a cnt=-1 &for %%a in (!port_table[%%0][%%1]!) do set /a cnt+=1 &set "port_list[!cnt!][%%1]=%%a")
set /a port_cnt=-1 &set /a port_cnt=-1 &for %%a in (!port_table[0][0]!) do set /a port_cnt+=1
exit /b

:test
pause
for /l %%a in (0, 1, 2) do (
for/ l %%b in (0, 1, 2) do (
echo %total[%%a][%%b]%)

pause
exit

:eof
echo END &pause &exit
