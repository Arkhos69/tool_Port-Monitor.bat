@echo off &setlocal EnableDelayedExpansion
call :setESC &call :port_list
call :setting &goto init_first

:setting
set show_detail=1
set color_text=1
set quick_mode=0
set without_delay=0
set enter_mode=img
exit /B

:main
cls
echo =======================================
echo Commands ^& Functions:
echo /pid Search Process by PID
echo /img Search Process by Image name
echo /all Print all Port and Filter Function
echo =======================================
echo.
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
color 07 &goto all
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
title=Port Monitor - %imgname%
for /f "tokens=1" %%a in ('tasklist /fi "pid eq %pid%" ^| findstr %pid%') do set imgname=%%a
for /f "tokens=*" %%a in ('tasklist /fi "pid eq %pid%"') do set "tasklist_cont=%%a"
tasklist /fi "pid eq %pid%" | findstr "%pid%" 2>&1>nul || goto died
set "enter=" &if %without_delay%==1 (set /a delay=0) else set /a delay=1
if "%quick_mode%"=="1" (color 0a &goto quick_loop) else (goto loop)

:loop
set /a count=0 &set /a slen=3 &for /l %%0 in (0, 1, !slen!) do set /a sortc[%%0]=0
for /l %%0 in (0, 1, 2) do set /a total[%%0][0]=0 &set /a est[%%0][0]=0 &set /a listen[%%0][0]=0
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /e %pid%') do (
for /f "tokens=5" %%b in ("%%a") do if %%b==%pid% set/a count+=1 &set output[!count!]=%%a)
if !count!==0 (echo. &echo ^(Empty^)) else (
for /l %%0 in (1, 1, !count!) do for /f "tokens=1-5" %%a in ("!output[%%0]!") do (

if "%show_detail%"=="1" (set "bool="
for /f "tokens=2,4 delims=:" %%p in ("%%b:%%c") do for /l %%1 in (0, 1, %port_cnt%) do ^
if %%p==!port_list[%%1][0]! (set "bool=1") else (if %%q==!port_list[%%1][0]! set "bool=1") & ^
if defined bool for %%i in (!port_list[%%1][0]!) do for %%j in (!port_list[%%1][1]!) do ^
set "output[%%0]=!output[%%0]::%%i=:%%j!")

if %%a==TCP (set /a total[0][0]+=1 &set /a cnt=0 &set "c=%%c"
for %%l in (%localhost% %nullhost% [::]) do set /a cnt+=1 &set "l=%%l" & ^
if "!c:~0,4!"=="!l:~0,4!" (set /a total[1][0]+=1 &set /a cnt=0
if %%d==LISTENING (set /a listen[0][0]+=1 &set /a listen[1][0]+=1 & ^
set /a sortc[0]+=1 &set "sort[0][!sortc[0]!]=!output[%%0]:%localhost%=localhost!") ^
else if %%d==ESTABLISHED (set /a est[0][0]+=1 &set /a est[1][0]+=1 & ^
set /a sortc[2]+=1 &set "sort[2][!sortc[2]!]=!output[%%0]:%localhost%=localhost!")) ^
else if !cnt!==3 (set /a total[2][0]+=1
if %%d==ESTABLISHED (set /a est[0][0]+=1 &set /a est[2][0]+=1 & ^
set /a sortc[3]+=1 &set "sort[3][!sortc[3]!]=!output[%%0]!") ^
else if %%d NEQ LISTENING (set /a sortc[1]+=1 &set "sort[1][!sortc[1]!]=!output[%%0]!") ^
else if "%list_w%"=="%pid%" (set /a listen[2][0]+=1) else set "kill_port=!output[%%0]!" &goto kill)))

cls &echo.
echo Image Name                     PID Session Name        Session#    Mem Usage
echo ========================= ======== ================ =========== ============
echo %tasklist_cont%
echo. &echo   %netstat_title_%

if "%color_text%"=="1" (
for /l %%0 in (0, 1, !slen!) do if not !sortc[%%0]!==0 (echo.
for /l %%1 in (1, 1, !sortc[%%0]!) do (
if %%0==0 echo   %ESC%[103;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==1 echo   %ESC%[46;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==2 echo   %ESC%[47;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==3 echo   %ESC%[44;1m!sort[%%0][%%1]!%ESC%[0m))) ^
else (set "state_space=                              "
for /l %%0 in (0, 1, !slen!) do if not !sortc[%%0]!==0 (echo.
if %%0==1 echo   !state_space![HANDSHAKE] &echo.
if %%0==2 echo   !state_space![ESTABLISHED] &echo.
if %%0==3 if !sortc[2]!==0 echo   !state_space![ESTABLISHED] &echo.
for /l %%1 in (1, 1, !sortc[%%0]!) do echo   !sort[%%0][%%1]!))
for /l %%0 in (1, 1, !count!) do set "output[!count!]=")

if %bln%==1 (for /l %%a in (0, 1, 2) do (set /a est[%%a][2]=est[%%a][0] &set /a total[%%a][2]=total[%%a][0]) &set bln=0)
for /l %%0 in (0, 1, 2) do for %%a in (listen est total) do ^
if !%%a[%%0][0]! gtr !%%a[%%0][1]! (set "%%a[%%0][1]=!%%a[%%0][0]!") ^
else if !%%a[%%0][0]! lss !%%a[%%0][2]! set "%%a[%%0][2]=!%%a[%%0][0]!"

set "title=State Total Local_Host(max|min) Foreign_Host(max|min)"
set /a interval=8 &set Title_Instant_Print=false
set /a data_len=3
set "data[1]=LISTENING !listen[0][0]! !listen[1][0]!_(!listen[1][1]!|!listen[1][2]!) !listen[2][0]!_(!listen[2][1]!|!listen[2][2]!)"
set "data[2]=ESTABLISHED !est[0][0]! !est[1][0]!_(!est[1][1]!|!est[1][2]!) !est[2][0]!_(!est[2][1]!|!est[2][2]!)"
set "data[3]=Total %total[0][0]% %total[1][0]%_(%total[1][1]%|%total[1][2]%) %total[2][0]%_(%total[2][1]%|%total[2][2]%)"
call :table

title=Port Monitor - %imgname%(%pid%) Total:%total[0][0]% [Est:%est[0][0]% (LH:%est[1][0]% FH:%est[2][0]%)]
echo.
if "%without_delay%"=="1" (
echo [Without-Delay Mode]
for /f "tokens=*" %%a in ('tasklist /fi "pid eq %pid%"') do set "tasklist_cont=%%a") ^
else (
choice /n /c pmndxc /t %delay% /d c /m "[P - Pause] [M - Back to Menu]:"
if %errorlevel%==1 pause
if %errorlevel%==2 goto init
if %errorlevel%==3 start %~f0
if %errorlevel%==4 set /a delay=0
if %errorlevel%==5 exit)
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

if not !Title_Instant_Print!==true (
echo. &echo   !title_print:_= ! &echo.
for /l %%0 in (1, 1, %data_len%) do echo   !table[%%0]:_= ! &set "table[%%0]=")
set "title_print="
exit /b

:quick_loop
set /a count=0 &set /a slen=2 &for /l %%0 in (0, 1, !slen!) do set /a sortc[%%0]=0
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /e %pid%') do (
for /f "tokens=5" %%b in ("%%a") do if %%b==%pid% set/a count+=1 &set output[!count!]=%%a)
if !count!==0 (echo. &echo ^(Empty^)) else (
for /l %%0 in (1, 1, !count!) do for /f "tokens=4" %%a in ("!output[%%0]!") do (
if %%a==LISTENING (set /a sortc[0]+=1 &set "sort[0][!sortc[0]!]=!output[%%0]!") ^
else if %%a==ESTABLISHED (set /a sortc[2]+=1 &set "sort[2][!sortc[2]!]=!output[%%0]!") ^
else (set /a sortc[1]+=1 &set "sort[1][!sortc[1]!]=!output[%%0]!"))
cls &echo [Quick mode] Image Name: %imgname% ^| PID: %pid% &echo.
echo   Proto  Local Address          Foreign Address        State           PID
set "state_space=                              "
for /l %%0 in (0, 1, !slen!) do if not !sortc[%%0]!==0 (
echo.
if %%0==1 echo   !state_space![HANDSHAKE] &echo.
if %%0==2 echo   !state_space![ESTABLISHED] &echo.
for /l %%1 in (1, 1, !sortc[%%0]!) do echo   !sort[%%0][%%1]!))
echo.
if "%without_delay%"=="1" (
echo [Without-Delay Mode]
for /f "tokens=*" %%a in ('tasklist /fi "pid eq %pid%"') do set "tasklist_cont=%%a") ^
else (
choice /n /c pmndxc /t %delay% /d c /m "[P - Pause] [M - Back to Menu]:"
if %errorlevel%==1 pause
if %errorlevel%==2 goto init
if %errorlevel%==3 start %~f0
if %errorlevel%==4 set /a delay=0
if %errorlevel%==5 exit)
goto quick_loop

:all
cls
set "filter_echo="
for %%a in (TCP UDP listen est handsh) do if defined filter_%%a set "filter_echo=!filter_echo!, %%a"
if defined filter_PID set "filter_echo=!filter_echo! | PID: %pid%"
set "filter_echo=!filter_echo:~2!" &echo Filter:[!filter_echo!]

set /a count=0 &set /a slen=4 &for /l %%0 in (0, 1, !slen!) do set /a sortc[%%0]=0
for /l %%0 in (0, 1, 2) do ^
set /a total[%%0][0]=0 &set /a est[%%0][0]=0 &set /a listen[%%0][0]=0

if defined filter_PID (for /f "tokens=*" %%a in ('netstat -ano ^| findstr /e %pid%') do ^
for /f "tokens=5" %%b in ("%%a") do if %%b==%pid% set/a count+=1 &set output[!count!]=%%a) ^
else for /f "tokens=*" %%a in ('netstat -ano') do set /a count+=1 &set output[!count!]=%%a

if !count!==0 (echo. &echo ^(Empty^)) else (
for /l %%0 in (1, 1, !count!) do for /f "tokens=1-5" %%a in ("!output[%%0]!") do (

if "%show_detail%"=="1" (set "bool="
for /f "tokens=2,4 delims=:" %%p in ("%%b:%%c") do for /l %%1 in (0, 1, %port_cnt%) do ^
if %%p==!port_list[%%1][0]! (set "bool=1") else (if %%q==!port_list[%%1][0]! set "bool=1") & ^
if defined bool for %%i in (!port_list[%%1][0]!) do for %%j in (!port_list[%%1][1]!) do ^
set "output[%%0]=!output[%%0]::%%i=:%%j!")

if %%a==TCP if defined filter_TCP (set /a cnt=0 &set "c=%%c"
for %%l in (%localhost% %nullhost% [::]) do set /a cnt+=1 &set "l=%%l" & ^
if "!c:~0,4!"=="!l:~0,4!" (set /a cnt=0
if %%d==LISTENING (if defined filter_listen set /a total[0][0]+=1 &set /a total[1][0]+=1 & ^
set /a listen[0][0]+=1 &set /a listen[1][0]+=1 & ^
set /a sortc[0]+=1 &set "sort[0][!sortc[0]!]=!output[%%0]:%localhost%=localhost!") ^
else if %%d==ESTABLISHED (
if defined filter_est set /a total[0][0]+=1 &set /a total[1][0]+=1 &set /a est[0][0]+=1 &set /a est[1][0]+=1 & ^
set /a sortc[2]+=1 &set "sort[2][!sortc[2]!]=!output[%%0]:%localhost%=localhost!")) ^
else if !cnt!==3 (
if %%d==ESTABLISHED (if defined filter_est set /a total[0][0]+=1 &set /a total[2][0]+=1 & ^
set /a est[0][0]+=1 &set /a est[2][0]+=1 &set /a sortc[3]+=1 &set "sort[3][!sortc[3]!]=!output[%%0]!") ^
else if %%d NEQ LISTENING (if defined filter_handsh set /a total[0][0]+=1 &set /a total[2][0]+=1 & ^
set /a sortc[1]+=1 &set "sort[1][!sortc[1]!]=!output[%%0]!") ^
else if "%list_w%"=="%pid%" (set /a listen[2][0]+=1) else set "kill_port=!output[%%0]!" &goto kill))

if %%a==UDP if defined filter_UDP (set /a total[0][0]+=1
set /a sortc[4]+=1 &set "sort[4][!sortc[4]!]=!output[%%0]:%localhost%=localhost!"))

if "%color_text%"=="1" (
for /l %%0 in (0, 1, !slen!) do if not !sortc[%%0]!==0 (echo.
if %%0==0 echo   !state_space!%ESC%[103;30m[LISTENING]%ESC%[0m &echo.
if %%0==1 echo   !state_space!%ESC%[46;30m[HANDSHAKE]%ESC%[0m &echo.
if %%0==2 echo   !state_space!%ESC%[47;30m[ESTABLISHED]%ESC%[0m &echo.
if %%0==3 echo   !state_space!%ESC%[44;1m[ESTABLISHED]%ESC%[0m &echo.
if %%0==4 echo   !state_space!%ESC%[102;30m[UDP]%ESC%[0m &echo.
for /l %%1 in (1, 1, !sortc[%%0]!) do echo   !sort[%%0][%%1]!)) ^
else (
for /l %%0 in (0, 1, !slen!) do if not !sortc[%%0]!==0 (echo.
if %%0==1 echo   !state_space![HANDSHAKE] &echo.
if %%0==2 echo   !state_space![ESTABLISHED] &echo.
if %%0==3 if !sortc[2]!==0 echo   !state_space![ESTABLISHED] &echo.
if %%0==4 echo   !state_space![UDP] &echo.
for /l %%1 in (1, 1, !sortc[%%0]!) do echo   !sort[%%0][%%1]!))
for /l %%0 in (1, 1, !count!) do set "output[!count!]=")

if %bln%==1 (for /l %%a in (0, 1, 2) do (
set /a est[%%a][2]=est[%%a][0] &set /a total[%%a][2]=total[%%a][0]) &set bln=0)

for /l %%0 in (0, 1, 2) do for %%a in (listen est total) do ^
if !%%a[%%0][0]! gtr !%%a[%%0][1]! (set "%%a[%%0][1]=!%%a[%%0][0]!") ^
else if !%%a[%%0][0]! lss !%%a[%%0][2]! set "%%a[%%0][2]=!%%a[%%0][0]!"

set "title=State Total Local_Host(max|min) Foreign_Host(max|min)"
set /a interval=8 &set Title_Instant_Print=false
set /a data_len=3
set "data[1]=LISTENING !listen[0][0]! !listen[1][0]!_(!listen[1][1]!|!listen[1][2]!) !listen[2][0]!_(!listen[2][1]!|!listen[2][2]!)"
set "data[2]=ESTABLISHED !est[0][0]! !est[1][0]!_(!est[1][1]!|!est[1][2]!) !est[2][0]!_(!est[2][1]!|!est[2][2]!)"
set "data[3]=Total %total[0][0]% %total[1][0]%_(%total[1][1]%|%total[1][2]%) %total[2][0]%_(%total[2][1]%|%total[2][2]%)"
call :table

title=Port Monitor - netstat Total:%total[0][0]% Est:%est[0][0]% ^(LH:%est[1][0]% FH:%est[2][0]%^)

echo.
choice /n /c mfr /m "[M - Back to Menu] [R - Reload] [F - Set Filter]:"
if %errorlevel%==1 goto init
if %errorlevel%==2 (
echo.
echo ===================================================================================
echo Set Filter:
echo Proto: [TCP, UDP]
echo State: [listen, est, handsh]
echo Choose PID: /pid ["pid"]
echo Clear Filter: /cls
echo -----------------------------------------------------------------------------------
echo Prefix the command with '+' or '-' to specify whether the type should be displayed.
echo e.g. -UDP
echo e.g. -UDP -listen +est
echo e.g. -TCP +UDP /pid 123
echo ===================================================================================
echo. &set /p "filter=Set Filter:"

set "filter_cmd=TCP UDP listen est handsh" &set "next=" &set "get="
if defined filter (for %%a in (!filter!) do (set "tmp=%%a" &set "tmp_=!tmp:~0,1!"

if defined next (
if "!next!"=="pid" tasklist /fi "pid eq !tmp!" | findstr !tmp! 2>&1>nul & ^
if !errorlevel!==0 (set "pid=!tmp!" &set "filter_PID=1") else echo Cannot find Process. &pause
set "next=")

if "!tmp_!"=="/" (if !tmp:~1!==pid (set "next=pid") else set "get=!tmp:~1!") else (for %%b in (!filter_cmd!) do ^
if "!tmp:~1!"=="%%b" (if "!tmp_!"=="+" (set "filter_%%b=1") else if "!tmp_!"=="-" (set "filter_%%b=") ^
else if "!tmp_!"=="$" set "filter_%%b=1" &for %%i in (!filter_cmd!) do if not %%i==%%b set "filter_%%i="))

if defined get (
if "!get!"=="cls" set "filter_listen=1" &set "filter_est=1" &set "filter_handsh=1" & ^
set "filter_TCP=1" &set "filter_UDP=1" &set "filter_PID="
set "get="))))

if defined filter_PID tasklist /fi "pid eq %pid%" | findstr "%pid%" 2>&1>nul || goto died
goto all

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
set bln=1 &set "list_w=" &set "list_b="
for /l %%0 in (0, 1, 2) do for /l %%1 in (0, 1, 2) do (
set /a total[%%0][%%1]=0 &set /a est[%%0][%%1]=0
set /a listen[%%0][%%1]=0 &set /a hand[%%0][%%1]=0 &set /a estc[%%0][%%1]=0)
set "filter_PID="
goto main

:init_first
cls &echo Loading......
title=Port Monitor &color 0e &chcp 1252 >nul
set "enter=" &set pid=0 &set imgname=0
set /a total[3][3] &set /a est[3][3] &set /a listen[3][3] &set /a estc[3][3]
set bln=1 &set "list_w=" &set "list_b="
for /l %%0 in (0, 1, 2) do for /l %%1 in (0, 1, 2) do (
set /a total[%%0][%%1]=0 &set /a est[%%0][%%1]=0
set /a listen[%%0][%%1]=0 &set /a hand[%%0][%%1]=0 &set /a estc[%%0][%%1]=0)
set /a init_cnt=0
for %%a in (1 1 0 img 1) do set /a init_cnt+=1 &set "default[!init_cnt!]=%%a"
set /a init_cnt=0
for %%a in (show_detail color_text quick_mode enter_mode without_delay) do ^
set /a init_cnt+=1 &if not defined %%a for %%i in (!init_cnt!) do set "%%a=!default[%%i]!"
set "state_space=                              "
set "filter_listen=1" &set "filter_est=1" &set "filter_handsh=1"
set "filter_TCP=1" &set "filter_UDP=1" &set "filter_PID="
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /i "PID"') do set "netstat_title_=%%a"
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

:eof
echo oops &pause &exit
