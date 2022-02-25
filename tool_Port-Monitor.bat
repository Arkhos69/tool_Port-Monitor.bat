@echo off &setlocal EnableDelayedExpansion
call :setESC &call :port_list
call :settings &goto init_RunOnce

:settings
set show_details=1
set color_text=1
set quick_mode=0
set without_delay=0
set enter_mode=img
EXIT /B

:port_list
set "localhost=127.0.0.1" &set "nullhost=0.0.0.0"
REM ***** Can be expansion *****
set /a port_table_index=1
set "port_table[0][0]=20,21,80,443"
set "port_table[0][1]=ftp,ftp,http,https"

set "port_table[1][0]=1080"
set "port_table[1][1]=socks"

REM port_list[0][0]=20 port_list[0][1]=ftp ... port_list[4][0]=1080 port_list[4][1]=socks
set /a port_len=-1 &for /l %%0 in (0, 1, %port_table_index%) do set /a tmp=!port_len! &for /l %%1 in (0, 1, 1) do ^
set /a port_len=!tmp! &for %%a in (!port_table[%%0][%%1]!) do set /a port_len+=1 &set "port_list[!port_len!][%%1]=%%a"
set "tmp=" &exit /b

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
else set "enter_mode=img"
) else goto command
goto main

:command
set "cmd_all=img pid all"
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
if defined enter (if "%enter_mode%"=="img" (
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq %enter%" ^| findstr /b /i %enter%') do set pid=%%a &goto start
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq %enter%.exe" ^| findstr /b /i %enter%.exe') do set pid=%%a &goto start
echo Cannot find Process.) else if "%enter_mode%"=="pid" (call :pid_check %enter% &if !errorlevel!==0 goto start))
pause &set "enter=" &goto main

:start
cls &color 07
echo loading......
for /f "tokens=1" %%a in ('tasklist /fi "pid eq %pid%" ^| findstr %pid%') do set imgname=%%a
title=Port Monitor - %imgname%
set "enter=" &if %without_delay%==1 (set /a delay=0) else set /a delay=1
tasklist /fi "pid eq %pid%" | findstr "%pid%" 2>&1>nul || goto died
if "%quick_mode%"=="1" (color 0a &goto quick_loop) else (goto loop)

:loop
set /a output_cnt=0 &set /a sort_len=5 &for /l %%0 in (0, 1, !sort_len!) do set /a sort[%%0][0]=0
for /l %%0 in (0, 1, 2) do set /a cnt_total[%%0][0]=0 &set /a cnt_listen[%%0][0]=0 & ^
set /a cnt_handsh[%%0][0]=0 &set /a cnt_est[%%0][0]=0 &set /a cnt_udp[%%0][0]=0

for /f "tokens=*" %%a in ('tasklist /fi "pid eq %pid%"') do set "tasklist_cont=%%a"
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /e %pid%') do for /f "tokens=1" %%p in ("%%a") do ^
if %%p==TCP (for /f "tokens=5" %%t in ("%%a") do if %%t==%pid% set/a output_cnt+=1 &set output[!output_cnt!]=%%a) ^
else if %%p==UDP for /f "tokens=4" %%u in ("%%a") do if %%u==%pid% set/a output_cnt+=1 &set output[!output_cnt!]=%%a

if !output_cnt! GTR 0 (
for /l %%0 in (1, 1, !output_cnt!) do for /f "tokens=1-5" %%a in ("!output[%%0]!") do (

if "%show_details%"=="1" (set "bool="
for /f "tokens=2,4 delims=:" %%p in ("%%b:%%c") do for /l %%1 in (0, 1, %port_len%) do ^
if %%p==!port_list[%%1][0]! (set "bool=1") else (if %%q==!port_list[%%1][0]! set "bool=1") & ^
if defined bool for %%i in (!port_list[%%1][0]!) do for %%j in (!port_list[%%1][1]!) do ^
set "output[%%0]=!output[%%0]::%%i=:%%j!")

if %%a==TCP (set /a cnt_total[0][0]+=1 &set /a cnt=0 &set "c=%%c"
for %%l in (%localhost% %nullhost% [::1] [::]) do set /a cnt+=1 &set "l=%%l" & ^
if "!c:~0,4!"=="!l:~0,4!" (set /a cnt_total[1][0]+=1 &set /a cnt=0
if %%d==LISTENING (set /a cnt_listen[0][0]+=1 &set /a cnt_listen[1][0]+=1 & ^
set /a sort[0][0]+=1 &set "sort[0][!sort[0][0]!]=!output[%%0]:%localhost%=localhost!") ^
else if %%d==ESTABLISHED (set /a cnt_est[0][0]+=1 &set /a cnt_est[1][0]+=1 & ^
set /a sort[2][0]+=1 &set "sort[2][!sort[2][0]!]=!output[%%0]:%localhost%=localhost!")) ^
else if !cnt!==4 (set /a cnt_total[2][0]+=1
if %%d==ESTABLISHED (set /a cnt_est[0][0]+=1 &set /a cnt_est[2][0]+=1 & ^
set /a sort[3][0]+=1 &set "sort[3][!sort[3][0]!]=!output[%%0]!") ^
else if %%d NEQ LISTENING (set /a cnt_handsh[0][0]+=1 &set /a cnt_handsh[2][0]+=1
set /a sort[1][0]+=1 &set "sort[1][!sort[1][0]!]=!output[%%0]!") ^
else if "%list_w%"=="%pid%" (set /a cnt_listen[2][0]+=1) else set "kill_port=!output[%%0]!" &goto kill)) ^
else if %%a==UDP (set /a cnt_total[0][0]+=1 &set /a cnt_udp[0][0]+=1
set /a cnt=0 &set "b=%%b" &for %%l in (%localhost% %nullhost% [::1] [::]) do set /a cnt+=1 &set "l=%%l" & ^
if "!b:~0,4!"=="!l:~0,4!" (set /a cnt_total[1][0]+=1 &set /a cnt_udp[1][0]+=1 &set /a cnt=0
set /a sort[4][0]+=1 &set "sort[4][!sort[4][0]!]=!output[%%0]:%localhost%=localhost!") else if !cnt!==4 (
set /a cnt_total[2][0]+=1 &set /a cnt_udp[2][0]+=1 &set /a sort[5][0]+=1 &set "sort[5][!sort[5][0]!]=!output[%%0]!")))

set "title=State Total Local_Host(max|min) Foreign_Host(max|min)"
set /a interval=8 &set Title_Instant_Print=false)

if %bln%==1 (for /l %%0 in (0, 1, 2) do (
for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do ^
set /a %%a[%%0][2]=%%a[%%0][0] &set /a %%a_last[%%0]=%%a[%%0][0]) &set bln=0)

title=Port Monitor - %imgname%(%pid%) Total:!cnt_total[0][0]! [Est:!cnt_est[0][0]! (LH:!cnt_est[1][0]! FH:!cnt_est[2][0]!)]

if "%color_text%"=="1" (
for /l %%0 in (0, 1, 2) do for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do (
set "%%a[%%0][1]=!%%a[%%0][1]:+=!" &set "%%a[%%0][2]=!%%a[%%0][2]:-=!"
set "%%a[%%0][1]=!%%a[%%0][1]:;=!" &set "%%a[%%0][2]=!%%a[%%0][2]:;=!"
if !%%a[%%0][0]! gtr !%%a[%%0][1]! (set "%%a[%%0][1]=+!%%a[%%0][0]!;") ^
else if !%%a[%%0][0]! lss !%%a[%%0][2]! set "%%a[%%0][2]=-!%%a[%%0][0]!;"
if !%%a[%%0][0]! gtr !%%a_last[%%0]! (set "%%a_last[%%0]=!%%a[%%0][0]!" &set "%%a[%%0][0]=+!%%a[%%0][0]!;") ^
else if !%%a[%%0][0]! lss !%%a_last[%%0]! set "%%a_last[%%0]=!%%a[%%0][0]!" &set "%%a[%%0][0]=-!%%a[%%0][0]!;")) ^
else for /l %%0 in (0, 1, 2) do for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do (
if !%%a[%%0][0]! gtr !%%a[%%0][1]! (set "%%a[%%0][1]=!%%a[%%0][0]!") ^
else if !%%a[%%0][0]! lss !%%a[%%0][2]! set "%%a[%%0][2]=!%%a[%%0][0]!")

set /a data_len=0 &set /a cnt=0
for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do set /a cnt+=1 &set /a tmp=!%%a[0][1]:;=! & ^
if !tmp! GTR 0 (set /a data_len+=1 &for /f "tokens=1,2" %%b in ("!data_len! !cnt!") do ^
set "data[%%b]=!state_table[%%c]!,!%%a[0][0]!" & ^
set "data[%%b]=!data[%%b]!,!%%a[1][0]! (!%%a[1][1]!|!%%a[1][2]!),!%%a[2][0]! (!%%a[2][1]!|!%%a[2][2]!)")

if !data_len! GTR 0 call :table

cls &echo.
echo Image Name                     PID Session Name        Session#    Mem Usage
echo ========================= ======== ================ =========== ============
echo %tasklist_cont%
echo. &echo   %netstat_title_%

if !output_cnt! GTR 0 (
if "%color_text%"=="1" (
for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (echo.
for /l %%1 in (1, 1, !sort[%%0][0]!) do (
if %%0==0 echo   %ESC%[103;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==1 echo   %ESC%[46;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==2 echo   %ESC%[47;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==3 echo   %ESC%[44;1m!sort[%%0][%%1]!%ESC%[0m
if %%0==4 echo   !sort[%%0][%%1]!
if %%0==5 echo   !sort[%%0][%%1]!))) ^
else (for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (echo.
if %%0==1 echo   %state_space%[HANDSHAKE] &echo.
if %%0==2 echo   %state_space%[ESTABLISHED] &echo.
if %%0==3 if !sort[2][0]!==0 echo   %state_space%[ESTABLISHED] &echo.
if %%0==4 echo   %state_space%[UDP] &echo.
if %%0==5 if !sort[4][0]!==0 echo   %state_space%[UDP] &echo.
for /l %%1 in (1, 1, !sort[%%0][0]!) do echo   !sort[%%0][%%1]!))
for /l %%0 in (1, 1, !output_cnt!) do set "output[!output_cnt!]="

) else echo. &echo ^(Empty^)

if !data_len! GTR 0 (echo. &echo   !title_print:_= ! &echo.
for /l %%0 in (1, 1, !data_len!) do echo   !table[%%0]:_= ! &set "table[%%0]="
set "title_print=")

echo. &if "%without_delay%"=="1" (echo [Without-Delay Mode]) ^
else (choice /n /c hpmndkxr /t %delay% /d r /m "[H - Help] [P - Pause] [M - Back to Menu]:"
if !ERRORLEVEL!==1 (echo.
echo [H - Help]
echo [D - Start Without-Delay mode]
echo [M - Back to Menu]
echo [N - Open a new cmd window]
echo [P - Pause]
echo [R - Reload]
echo [K - Kill Process]
echo [X - Exit]
pause)
if !ERRORLEVEL!==2 pause
if !ERRORLEVEL!==3 goto init
if !ERRORLEVEL!==4 start %~f0
if !ERRORLEVEL!==5 set "without_delay=1" &set /a delay=0
if !ERRORLEVEL!==6 taskkill /f /t /pid %pid%
if !ERRORLEVEL!==7 exit)
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
set /a sl_cnt=0 &set /a interval=8

if defined data[%%t] (
call :table_split "!data[%%t]!"

for /l %%0 in (1, 1, !len!) do (
if %%0 gtr 1 set /a interval=6
set /a space_[%%0]=title_len_[%%0]-!data_str_cnt[%%0]!+!interval!
if not %%0==!len! for /l %%1 in (1, 1, !space_[%%0]!) do set space[%%0]= !space[%%0]!
set table[%%t]=!table[%%t]!!data_[%%0]!!space[%%0]!
for /l %%1 in (1, 1, !space_[%%0]!) do set "space[%%0]="
set /a space_[%%0]=0 &set "data_[%%0]=")

if !Title_Instant_Print!==true echo !table[%%t]!
) else (set data[%%T]=NULL))
exit /b

:table_split <string_data>
set "sp_str=%~1" &set "split_char=,"
set /a str_len=0 &set /a sp_ary_len=0 &set "sp_start="

for %%i in (10 20 40 80 100 200 350 500) do for /l %%0 in (0, 1, %%i) do ^
if defined sp_str (set "sp_cut="
set "sp_=!sp_str:~0,1!" &set "sp_str=!sp_str:~1!"

if "%color_text%"=="1" (
if "!sp__!"==";" set "sp_start="
if defined sp_start (if "!sp_!"==";" (

if "!sp_start!"=="+" (set "sp_tmp=!sp_tmp!%ESC%[31m!sp_tmp2!%ESC%[0m") ^
else if "!sp_start!"=="-" set "sp_tmp=!sp_tmp!%ESC%[32m!sp_tmp2!%ESC%[0m"
if "!sp_start!"=="++" (set "sp_tmp=!sp_tmp!%ESC%[41;30m!sp_tmp2!%ESC%[0m") ^
else if "!sp_start!"=="--" set "sp_tmp=!sp_tmp!%ESC%[42;30m!sp_tmp2!%ESC%[0m"
set "sp_tmp2=") ^

else set "sp_tmp2=!sp_tmp2!!sp_!" &set /a str_len+=1) else (
if "!sp_!"=="+" (if "!sp__!"=="%split_char%" (set "sp_start=+") else set "sp_start=++")
if "!sp_!"=="-" (if "!sp__!"=="%split_char%" (set "sp_start=-") else set "sp_start=--"))
set "sp__=!sp_!")

if "!sp_!"=="%split_char%" (set "sp_cut=1") ^
else if not defined sp_start set "sp_tmp=!sp_tmp!!sp_!" &set /a str_len+=1
if not defined sp_str set "sp_cut=1"

if defined sp_cut if defined sp_tmp set /a sp_ary_len+=1 & ^
set "data_[!sp_ary_len!]=!sp_tmp!" &set "data_str_cnt[!sp_ary_len!]=!str_len!" & ^
set "sp_tmp=" &set /a str_len=0

) else exit /b

:str_len <string_str>
set "str=%~1" &set /a str_len=0
for %%i in (10 20 40 80 100 200) do for /l %%0 in (0, 1, %%i) do ^
if defined str (set /a str_len+=1 &set "str=!str:~1!") else exit /b

:quick_loop
set /a output_cnt=0 &set /a sort_len=2 &for /l %%0 in (0, 1, !sort_len!) do set /a sort[%%0][0]=0
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /e %pid%') do (
for /f "tokens=5" %%b in ("%%a") do if %%b==%pid% set/a output_cnt+=1 &set output[!output_cnt!]=%%a)
if !output_cnt!==0 (echo. &echo ^(Empty^)) else (
for /l %%0 in (1, 1, !output_cnt!) do for /f "tokens=4" %%a in ("!output[%%0]!") do (
if %%a==LISTENING (set /a sort[0][0]+=1 &set "sort[0][!sort[0][0]!]=!output[%%0]!") ^
else if %%a==ESTABLISHED (set /a sort[2][0]+=1 &set "sort[2][!sort[2][0]!]=!output[%%0]!") ^
else (set /a sort[1][0]+=1 &set "sort[1][!sort[1][0]!]=!output[%%0]!"))
cls &echo [Quick mode] Image Name: %imgname% ^| PID: %pid% &echo.
echo   Proto  Local Address          Foreign Address        State           PID
for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (
echo.
if %%0==1 echo   !state_space![HANDSHAKE] &echo.
if %%0==2 echo   !state_space![ESTABLISHED] &echo.
for /l %%1 in (1, 1, !sort[%%0][0]!) do echo   !sort[%%0][%%1]!))
echo.
if "%without_delay%"=="1" (echo [Without-Delay Mode]
for /f "tokens=*" %%a in ('tasklist /fi "pid eq %pid%"') do set "tasklist_cont=%%a") ^
else (choice /n /c pmndxc /t %delay% /d c /m "[P - Pause] [M - Back to Menu]:"
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

set /a output_cnt=0 &set /a sort_len=5 &for /l %%0 in (0, 1, !sort_len!) do set /a sort[%%0][0]=0

for /l %%0 in (0, 1, 2) do set /a cnt_total[%%0][0]=0 &set /a cnt_listen[%%0][0]=0 & ^
set /a cnt_handsh[%%0][0]=0 &set /a cnt_est[%%0][0]=0 &set /a cnt_udp[%%0][0]=0

for /f "tokens=*" %%n in ('netstat -ano') do for /f "tokens=1,4,5" %%a in ("%%n") do (
set "pid_bln=" &if defined filter_PID (if %%a==TCP (if %%c==%pid% set "pid_bln=1") ^
else if %%a==UDP (if %%b==%pid% set "pid_bln=1")) else set "pid_bln=1"

if defined pid_bln (if %%a==TCP if defined filter_TCP (
if %%b==LISTENING (if defined filter_listen set /a output_cnt+=1 &set output[!output_cnt!]=%%n) ^
else if %%b==ESTABLISHED (if defined filter_est set /a output_cnt+=1 &set output[!output_cnt!]=%%n) ^
else if defined filter_handsh set /a output_cnt+=1 &set output[!output_cnt!]=%%n)
if %%a==UDP if defined filter_UDP set /a output_cnt+=1 &set output[!output_cnt!]=%%n))

if !output_cnt! GTR 0 (
for /l %%0 in (1, 1, !output_cnt!) do for /f "tokens=1-5" %%a in ("!output[%%0]!") do (

if "%show_details%"=="1" (set "bool="
for /f "tokens=2,4 delims=:" %%p in ("%%b:%%c") do for /l %%1 in (0, 1, %port_len%) do ^
if %%p==!port_list[%%1][0]! (set "bool=1") else (if %%q==!port_list[%%1][0]! set "bool=1") & ^
if defined bool for %%i in (!port_list[%%1][0]!) do for %%j in (!port_list[%%1][1]!) do ^
set "output[%%0]=!output[%%0]::%%i=:%%j!")

if %%a==TCP (set /a cnt_total[0][0]+=1 &set /a cnt=0 &set "c=%%c"
for %%l in (%localhost% %nullhost% [::1] [::]) do set /a cnt+=1 &set "l=%%l" & ^
if "!c:~0,4!"=="!l:~0,4!" (set /a cnt_total[1][0]+=1 &set /a cnt=0
if %%d==LISTENING (set /a cnt_listen[0][0]+=1 &set /a cnt_listen[1][0]+=1 & ^
set /a sort[0][0]+=1 &set "sort[0][!sort[0][0]!]=!output[%%0]:%localhost%=localhost!") ^
else if %%d==ESTABLISHED (set /a cnt_est[0][0]+=1 &set /a cnt_est[1][0]+=1 & ^
set /a sort[2][0]+=1 &set "sort[2][!sort[2][0]!]=!output[%%0]:%localhost%=localhost!")) ^
else if !cnt!==4 (set /a cnt_total[2][0]+=1
if %%d==ESTABLISHED (set /a cnt_est[0][0]+=1 &set /a cnt_est[2][0]+=1 & ^
set /a sort[3][0]+=1 &set "sort[3][!sort[3][0]!]=!output[%%0]!") ^
else if %%d NEQ LISTENING (set /a cnt_handsh[0][0]+=1 &set /a cnt_handsh[2][0]+=1
set /a sort[1][0]+=1 &set "sort[1][!sort[1][0]!]=!output[%%0]!") ^
else if "%list_w%"=="%pid%" (set /a cnt_listen[2][0]+=1) else set "kill_port=!output[%%0]!" &goto kill)) ^
else if %%a==UDP (set /a cnt_total[0][0]+=1 &set /a cnt_udp[0][0]+=1
set /a cnt=0 &set "b=%%b" &for %%l in (%localhost% %nullhost% [::1] [::]) do set /a cnt+=1 &set "l=%%l" & ^
if "!b:~0,4!"=="!l:~0,4!" (set /a cnt_total[1][0]+=1 &set /a cnt_udp[1][0]+=1 &set /a cnt=0
set /a sort[4][0]+=1 &set "sort[4][!sort[4][0]!]=!output[%%0]:%localhost%=localhost!") else if !cnt!==4 (
set /a cnt_total[2][0]+=1 &set /a cnt_udp[2][0]+=1 &set /a sort[5][0]+=1 &set "sort[5][!sort[5][0]!]=!output[%%0]!")))

set "title=State Total Local_Host(max|min) Foreign_Host(max|min)"
set /a interval=8 &set Title_Instant_Print=false)

if %bln%==1 (for /l %%0 in (0, 1, 2) do (
for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do ^
set /a %%a[%%0][2]=%%a[%%0][0] &set /a %%a_last[%%0]=%%a[%%0][0]) &set bln=0)

title=Port Monitor - netstat Total:!cnt_total[0][0]! [Est:!cnt_est[0][0]! (LH:!cnt_est[1][0]! FH:!cnt_est[2][0]!)]

if "%color_text%"=="1" (
for /l %%0 in (0, 1, 2) do for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do (
set "%%a[%%0][1]=!%%a[%%0][1]:+=!" &set "%%a[%%0][2]=!%%a[%%0][2]:-=!"
set "%%a[%%0][1]=!%%a[%%0][1]:;=!" &set "%%a[%%0][2]=!%%a[%%0][2]:;=!"
if !%%a[%%0][0]! gtr !%%a[%%0][1]! (set "%%a[%%0][1]=+!%%a[%%0][0]!;") ^
else if !%%a[%%0][0]! lss !%%a[%%0][2]! set "%%a[%%0][2]=-!%%a[%%0][0]!;"
if !%%a[%%0][0]! gtr !%%a_last[%%0]! (set "%%a_last[%%0]=!%%a[%%0][0]!" &set "%%a[%%0][0]=+!%%a[%%0][0]!;") ^
else if !%%a[%%0][0]! lss !%%a_last[%%0]! set "%%a_last[%%0]=!%%a[%%0][0]!" &set "%%a[%%0][0]=-!%%a[%%0][0]!;")) ^
else for /l %%0 in (0, 1, 2) do for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do (
if !%%a[%%0][0]! gtr !%%a[%%0][1]! (set "%%a[%%0][1]=!%%a[%%0][0]!") ^
else if !%%a[%%0][0]! lss !%%a[%%0][2]! set "%%a[%%0][2]=!%%a[%%0][0]!")

set /a data_len=0 &set /a cnt=0
for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do set /a cnt+=1 &set /a tmp=!%%a[0][1]:;=! & ^
if !tmp! GTR 0 (set /a data_len+=1 &for /f "tokens=1,2" %%b in ("!data_len! !cnt!") do ^
set "data[%%b]=!state_table[%%c]!,!%%a[0][0]!" & ^
set "data[%%b]=!data[%%b]!,!%%a[1][0]! (!%%a[1][1]!|!%%a[1][2]!),!%%a[2][0]! (!%%a[2][1]!|!%%a[2][2]!)")

if !data_len! GTR 0 call :table

if !output_cnt! GTR 0 (
if "%color_text%"=="1" (
for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (echo.
if %%0==0 echo   !state_space!%ESC%[103;30m[LISTENING]%ESC%[0m &echo.
if %%0==1 echo   !state_space!%ESC%[46;30m[HANDSHAKE]%ESC%[0m &echo.
if %%0==2 echo   !state_space!%ESC%[47;30m[ESTABLISHED]%ESC%[0m &echo.
if %%0==3 echo   !state_space!%ESC%[44;1m[ESTABLISHED]%ESC%[0m &echo.
if %%0==4 echo   !state_space!%ESC%[102;30m[UDP]%ESC%[0m &echo.
for /l %%1 in (1, 1, !sort[%%0][0]!) do echo   !sort[%%0][%%1]!)) ^
else (for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (echo.
if %%0==1 echo   %state_space%[HANDSHAKE] &echo.
if %%0==2 echo   %state_space%[ESTABLISHED] &echo.
if %%0==3 if !sort[2][0]!==0 echo   %state_space%[ESTABLISHED] &echo.
if %%0==4 echo   %state_space%[UDP] &echo.
if %%0==5 if !sort[4][0]!==0 echo   %state_space%[UDP] &echo.
for /l %%1 in (1, 1, !sort[%%0][0]!) do echo   !sort[%%0][%%1]!))
for /l %%0 in (1, 1, !output_cnt!) do set "output[!output_cnt!]="

) else echo. &echo ^(Empty^)

if !data_len! GTR 0 (echo. &echo   !title_print:_= ! &echo.
for /l %%0 in (1, 1, !data_len!) do echo   !table[%%0]:_= ! &set "table[%%0]="
set "title_print=")

call :all_opt

if defined filter_PID tasklist /fi "pid eq %pid%" | findstr "%pid%" 2>&1>nul || goto died
goto all

:all_opt
echo. &set "all_reload="
choice /n /c hmfnkxr /m "[H - Help] [M - Back to Menu] [R - Reload] [F - Set Filter]:"
if %ERRORLEVEL%==1 (echo.
echo [H - Help]
echo [M - Back to Menu]
echo [R - Reload]
echo [F - Set Filter]
echo [N - Open a new cmd window with Single Monitor mode]
echo [K - Kill Process]
echo [X - Exit])
if %ERRORLEVEL%==2 goto init
if %ERRORLEVEL%==3 (set "filter="
echo.
echo ===================================================================================
echo Set Filter:
echo Proto: [TCP, UDP]
echo State: [listen, est, handsh]
echo Choose PID: /pid ["pid"] Clear: -PID
echo Clear Filter: /cls
echo -----------------------------------------------------------------------------------
echo Prefix the command with '+' or '-' to specify whether the type should be displayed.
echo e.g. -UDP
echo e.g. -UDP -listen +est
echo e.g. -TCP +UDP /pid 123
echo ===================================================================================
echo. &set /p "filter=Set Filter:"

set "filter_cmd=TCP UDP listen est handsh PID" &set "next=" &set "get="
if defined filter (for %%a in (!filter!) do (set "tmp=%%a" &set "tmp_=!tmp:~0,1!"

if defined next (
if "!next!"=="pid" call :pid_check !tmp! &if !ERRORLEVEL!==0 set "filter_PID=1"
set "next=")

if "!tmp!"=="+PID" set "tmp=/pid" &set "tmp_=!tmp:~0,1!"
if "!tmp_!"=="/" (if !tmp:~1!==pid (set "next=pid") else set "get=!tmp:~1!") else (for %%b in (!filter_cmd!) do ^
if "!tmp:~1!"=="%%b" (if "!tmp_!"=="+" (set "filter_%%b=1") else if "!tmp_!"=="-" (set "filter_%%b=") ^
else if "!tmp_!"=="$" set "filter_%%b=1" &for %%i in (!filter_cmd!) do if not %%i==%%b set "filter_%%i="))

if defined get (
if "!get!"=="cls" set "filter_listen=1" &set "filter_est=1" &set "filter_handsh=1" & ^
set "filter_TCP=1" &set "filter_UDP=1" &set "filter_PID="
set "get="))
set "tmp=" &set "tmp_=" &set "all_reload=1"))
if %ERRORLEVEL%==4 echo. &set /p "pid_=[New Monitor] Please enter The PID:" & ^
call :pid_check !pid_! &if !ERRORLEVEL!==0 set "pass=start" &start %~f0

if %ERRORLEVEL%==5 echo. &set /p "pid_=[Kill Process] Please enter The PID:" & ^
call :pid_check !pid_! &if !ERRORLEVEL!==0 taskkill /f /t /pid !pid!
set "pid_="

IF %ERRORLEVEL%==6 exit
if %ERRORLEVEL%==7 set "all_reload=1"

if defined all_reload exit /b
goto all_opt

:pid_check <PID>
set "check_pid=%~1" &if defined check_pid (
tasklist /fi "pid eq %~1" | findstr %~1 2>&1>nul
if !ERRORLEVEL!==0 set "pid=%~1" &exit /b 0) else exit /b 1
echo Cannot find Process. &exit /b 1

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
REM start %~f0
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
for /l %%0 in (0, 1, 2) do for /l %%1 in (0, 1, 2) do ^
set /a cnt_listen[%%0][%%1]=0 &set /a cnt_handsh[%%0][%%1]=0 & ^
set /a cnt_est[%%0][%%1]=0 &set /a cnt_udp[%%0][%%1]=0 &set /a cnt_total[%%0][%%1]=0
set "filter_PID=" &set "pass=" &set "all_reload="
goto main

:init_RunOnce
cls &echo Loading......
title=Port Monitor &color 0e &chcp 1252 >nul
set bln=1 &set "list_w=" &set "list_b="
for /l %%0 in (0, 1, 2) do for /l %%1 in (0, 1, 2) do ^
set /a cnt_listen[%%0][%%1]=0 &set /a cnt_handsh[%%0][%%1]=0 & ^
set /a cnt_est[%%0][%%1]=0 &set /a cnt_udp[%%0][%%1]=0 &set /a cnt_total[%%0][%%1]=0
set /a init_cnt=0 &for %%a in (1 1 0 img 1) do set /a init_cnt+=1 &set "default[!init_cnt!]=%%a"
set /a init_cnt=0 &for %%a in (show_details color_text quick_mode enter_mode without_delay) do ^
set /a init_cnt+=1 &if not defined %%a for %%i in (!init_cnt!) do set "%%a=!default[%%i]!"
set "filter_listen=1" &set "filter_est=1" &set "filter_handsh=1"
set "filter_TCP=1" &set "filter_UDP=1" &set "filter_PID="
set "state_space=                              "
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /i "PID"') do set "netstat_title_=%%a"
set /a cnt=0 &for %%a in (LISTENING HANDSHAKE ESTABLISHED UDP Total) do set /a cnt+=1 &set "state_table[!cnt!]=%%a"
set /a cnt=0 &for %%a in (103x30m 47x30m 44x1m 102x30m 0x0m) do ^
set /a cnt+=1 &for %%b in (!cnt!) do set "color_table[%%b]=%%a" &set "color_table[%%b]=!color_table[%%b]:x=;!"
set /a cnt=0 &for %%a in (93m 36m 34m 92m 0m) do ^
set /a cnt+=1 &for %%b in (!cnt!) do set "color_table2[%%b]=%%a"
set /a cnt=0
if defined pass (set "pass_%pass%=1" &goto %pass%) else set pid=0 &goto main
goto main

REM Cool Stuff win10colors.cmd by Michele Locati (github/mlocati). Respect!!!
:setESC
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set ESC=%%b
  exit /B 0
)
exit /B 0

:eof
echo oops &pause
