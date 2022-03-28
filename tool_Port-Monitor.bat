@echo off &setlocal EnableDelayedExpansion
goto init_RunOnce

:settings
REM color_text only work on Windows 10
set show_details=1
set show_filter_intro=1
set color_text=1
set without_delay=0
set quick_mode=0
set stats_table_only=0
set popup_StatsTable=1
set enter_mode=img

REM dev.
set "debug_print_raw=0"
set "debug_running_time=0"
set "debug_starting_echo=0"
set "state_listen=LISTENING"
set "state_handshake=HANDSHAKE"
set "state_est=ESTABLISHED"
REM 127.0.0.1 CIDR /8
set "localhost=127.0.0.1"
set "nullhost=0.0.0.0"
set "localhost_IPv6=[::1]"
set "nullhost_IPv6=[::]"
echo [ok] settings &EXIT /B

:port_list
REM ***** Can be expansion *****
set /a port_table_index=1
set "port_table[0][0]=20,21,80,443"
set "port_table[0][1]=ftp,ftp,http,https"

set "port_table[1][0]=1080"
set "port_table[1][1]=socks"

REM port_list[0][0]=20 port_list[0][1]=ftp ... port_list[4][0]=1080 port_list[4][1]=socks
set /a port_len=-1 &for /l %%0 in (0, 1, %port_table_index%) do set /a tmp=!port_len! &for /l %%1 in (0, 1, 1) do ^
set /a port_len=!tmp! &for %%a in (!port_table[%%0][%%1]!) do set /a port_len+=1 &set "port_list[!port_len!][%%1]=%%a"
set "tmp=" &echo [ok] port_list &exit /b

:main
cls
echo =======================================
echo Commands ^& Functions:
echo /pid Search Process by PID
echo /img Search Process by Image name
echo /all Print all Port and Filter Function
echo =======================================
echo.

if defined enter (
if "%enter%"=="exit" exit
if "!enter:~0,1!"=="/" goto command
goto single_check) ^

else if "%enter_mode%"=="img" (set /p "enter=Please enter The Image name:") ^
else if "%enter_mode%"=="pid" (set /p "enter=Please enter The PID:") ^
else set "enter_mode=img"
goto main

:command
set "cmd_check=img pid all"
for %%a in (%cmd_check%) do if !enter:~1!==%%a goto %enter%
goto /help

REM Commands
:/help
echo [help]
echo. &echo Commands:
for %%a in (%cmd_check%) do echo /%%a
set "enter=" &pause &goto main
:/img
set "enter_mode=img" &set "enter=" &goto main
:/pid
set "enter_mode=pid" &set "enter=" &goto main
:/all
color 07
if "%stat_table_only%"=="1" call :cmd_settings "stats"
if "%popup_StatsTable%"=="1" call :sync_start "popup_stats" "netstat - Stats Table"
goto all
:/wg
goto watchdog

:single_check
if defined enter (if "%enter_mode%"=="img" (
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq %enter%" ^| findstr /b /i %enter%') do set "pid=%%a" &goto start
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq %enter%.exe" ^| findstr /b /i %enter%.exe') do set "pid=%%a" &goto start
echo Cannot find Process.) else if "%enter_mode%"=="pid" call :pid_check %enter% &if !errorlevel!==0 goto start)
set "enter=" &pause &goto main

:pid_check <PID>
set "check_pid=%~1" &if defined check_pid (
tasklist /fi "pid eq %~1" | findstr %~1 2>&1>nul
if !ERRORLEVEL!==0 set "pid=%~1" &exit /b 0) else exit /b 1
echo Cannot find Process. &exit /b 1

:stats_table <input> <bool_sort>
set "input_=%~1" &set "bool_=%~2"

if defined bool_ set /a sort_len=5 &for /l %%0 in (0, 1, !sort_len!) do set /a sort[%%0][0]=0

for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do for /l %%0 in (0, 1, 2) do ^
set /a %%a[%%0][0]=0

for %%$ in (%input_%) do if !%%$_len! GTR 0 (
for /l %%0 in (1, 1, !%%$_len!) do for /f "tokens=1-5" %%a in ("!%%$[%%0]!") do (

set /a index=0 &set /a index2=0 &set "sort_num="
set "cnt_table[1]=cnt_listen" &set "cnt_table[2]=cnt_est"

set "c=%%c" &set "b=%%b"
if defined fl_match (if %%a==TCP (set "c=!c:{=!" &set "c=!c:}=!") else set "b=!b:{=!" &set "b=!b:}=!")

if %%a==TCP (set /a cnt_total[0][0]+=1 &for %%i in (%state_listen% %state_est%) do set /a index+=1 & ^
if %%d==%%i (for %%l in (%localhost% %nullhost% %localhost_IPv6% %nullhost_IPv6%) do ^
set /a index2+=1 &set "l=%%l" &if "!c:~0,4!"=="!l:~0,4!" (
set /a cnt_total[1][0]+=1 &if !index!==1 (set "sort_num=0") else set "sort_num=2"
for %%x in (0 1) do for %%y in (!index!) do set /a !cnt_table[%%y]![%%x][0]+=1 &set /a index2=0) ^
else if !index2!==4 set /a cnt_total[2][0]+=1 &if !index!==1 (set "sort_num=-1") else set "sort_num=3" & ^
for %%x in (0 2) do for %%y in (!index!) do set /a !cnt_table[%%y]![%%x][0]+=1

set /a index=0) else if !index!==2 ^
set "sort_num=1" &set /a cnt_total[2][0]+=1 &for %%x in (0 2) do set /a cnt_handsh[%%x][0]+=1
) else if %%a==UDP set /a cnt_total[0][0]+=1 &set /a cnt_udp[0][0]+=1 & ^
for %%l in (%localhost% %nullhost% %localhost_IPv6% %nullhost_IPv6%) do ^
set /a index+=1 &set "l=%%l" &if "!b:~0,4!"=="!l:~0,4!" (set "sort_num=4"
set /a cnt_total[1][0]+=1 &set /a cnt_udp[1][0]+=1 &set /a index=0) ^
else if !index!==4 set "sort_num=5" &set /a cnt_total[2][0]+=1 &set /a cnt_udp[2][0]+=1

if defined sort_num if defined bool_ (if !sort_num!==-1 goto kill
for %%s in (!sort_num!) do set /a sort[%%s][0]+=1 & ^
set "sort[%%s][!sort[%%s][0]!]=!%%$[%%0]:%localhost%=localhost!" & ^
if "%show_details%"=="1" set "dbool=" & ^
for /f "tokens=2,4 delims=:" %%p in ("%%b:%%c") do for /l %%1 in (0, 1, %port_len%) do ^
if %%p==!port_list[%%1][0]! (set "dbool=1") else (if %%q==!port_list[%%1][0]! set "dbool=1") & ^
if defined dbool for %%i in (!port_list[%%1][0]!) do for %%j in (!port_list[%%1][1]!) do ^
for %%x in (!sort[%%s][0]!) do set "sort[%%s][%%x]=!sort[%%s][%%x]::%%i=:%%j!"))

if "%stats_bln%"=="1" (
for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do for /l %%0 in (0, 1, 2) do (
set /a %%a[%%0][2]=%%a[%%0][0] &set /a %%a_last[%%0]=%%a[%%0][0] & ^
set /a %%a[%%0][1]=%%a[%%0][0] &set /a %%a_last[%%0]=%%a[%%0][0]) &set "stats_bln=0")

if "%color_text%"=="1" (
for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do for /l %%0 in (0, 1, 2) do (
set "%%a[%%0][1]=!%%a[%%0][1]:+=!" &set "%%a[%%0][2]=!%%a[%%0][2]:-=!"
set "%%a[%%0][1]=!%%a[%%0][1]:;=!" &set "%%a[%%0][2]=!%%a[%%0][2]:;=!"
if !%%a[%%0][0]! GTR !%%a[%%0][1]! (set "%%a[%%0][1]=++!%%a[%%0][0]!;") ^
else if !%%a[%%0][0]! LSS !%%a[%%0][2]! set "%%a[%%0][2]=--!%%a[%%0][0]!;"
if !%%a[%%0][0]! GTR !%%a_last[%%0]! (set "%%a_last[%%0]=!%%a[%%0][0]!" &set "%%a[%%0][0]=+!%%a[%%0][0]!;") ^
else if !%%a[%%0][0]! LSS !%%a_last[%%0]! set "%%a_last[%%0]=!%%a[%%0][0]!" &set "%%a[%%0][0]=-!%%a[%%0][0]!;")) ^
else for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do for /l %%0 in (0, 1, 2) do (
if !%%a[%%0][0]! GTR !%%a[%%0][1]! (set "%%a[%%0][1]=!%%a[%%0][0]!") ^
else if !%%a[%%0][0]! LSS !%%a[%%0][2]! set "%%a[%%0][2]=!%%a[%%0][0]!")

set /a data_len=0 &set /a cnt=0
for %%a in (cnt_listen cnt_handsh cnt_est cnt_udp cnt_total) do ^
set /a cnt+=1 &set "tmp=!%%a[0][1]:;=!" &set /a tmp=!tmp:+=! & ^
if !tmp! GTR 0 (set /a data_len+=1 &for /f "tokens=1,2" %%b in ("!data_len! !cnt!") do (
set "tmp_=!%%a[0][0]!" &if "!%%a[0][1]:~0,1!"=="+" (set "tmp_=!%%a[0][1]!") ^
else if "!%%a[0][2]:~0,1!"=="-" set "tmp_=!%%a[0][2]!"

set "data[%%b]=!state_table[%%c]!,!tmp_!" & ^
set "data[%%b]=!data[%%b]!,!%%a[1][0]! (!%%a[1][1]!|!%%a[1][2]!),!%%a[2][0]! (!%%a[2][1]!|!%%a[2][2]!)"))

if !data_len! GTR 0 call :table)
exit /b

:table
if !data_len! geq 50 set Title_Instant_Print=true
if !Title_Instant_Print!==true echo !title_print!
if "%popup_StatsTable%"=="1" echo !title_print! >>%sync_data% &echo echo.>>%sync_data%

for /l %%t in (1, 1, !data_len!) do (
set /a sl_cnt=0 &set /a interval=8

if defined data[%%t] (
call :table_split "!data[%%t]!"

for /l %%0 in (1, 1, !len!) do (
if %%0 GTR 1 set /a interval=6
set /a space_[%%0]=!title_len[%%0]!-!data_str_cnt[%%0]!+!interval!
if not %%0==!len! for /l %%1 in (1, 1, !space_[%%0]!) do set space[%%0]= !space[%%0]!
set table[%%t]=!table[%%t]!!data_[%%0]!!space[%%0]!
for /l %%1 in (1, 1, !space_[%%0]!) do set "space[%%0]="
set /a space_[%%0]=0 &set "data_[%%0]=")

if "%popup_StatsTable%"=="1" echo !table[%%t]! >>%sync_data%

if !Title_Instant_Print!==true echo !table[%%t]!
) else (set data[%%T]=NULL))
exit /b

:table_split <string_data>
set "sp_str=%~1" &set "split_char=,"
set /a str_len=0 &set /a sp_ary_len=0
set "sp_start=" &set "sp_wait="
:table_split_loop
for %%i in (30 20 50 80 100) do for /l %%0 in (0, 1, %%i) do ^
if defined sp_str (set "sp_cut="
set "sp_=!sp_str:~0,1!" &set "sp_str=!sp_str:~1!"

if "%color_text%"=="1" (

if defined sp_wait (if not "!sp_!"=="!sp_wait!" set "sp_start=!sp_wait!" &set "sp_wait=")

if "!sp__!"==";" set "sp_start="
if defined sp_start (if "!sp_!"==";" (

if "!sp_start!"=="+" (set "sp_get=!sp_get!%ESC%[31m!sp_get2!%ESC%[0m") ^
else if "!sp_start!"=="-" set "sp_get=!sp_get!%ESC%[32m!sp_get2!%ESC%[0m"
if "!sp_start!"=="++" (set "sp_get=!sp_get!%ESC%[41;30m!sp_get2!%ESC%[0m") ^
else if "!sp_start!"=="--" set "sp_get=!sp_get!%ESC%[42;30m!sp_get2!%ESC%[0m"
set "sp_get2=") ^

else set "sp_get2=!sp_get2!!sp_!" &set /a str_len+=1) else (
if defined sp_wait (if "!sp_!"=="!sp_wait!" set "sp_start=!sp_wait!!sp_wait!"
set "sp_wait=") else for %%a in (+ -) do if "!sp_!"=="%%a" set "sp_wait=%%a")
set "sp__=!sp_!")

if "!sp_!"=="%split_char%" (set "sp_cut=1") ^
else if not defined sp_start if not defined sp_wait set "sp_get=!sp_get!!sp_!" &set /a str_len+=1
if not defined sp_str set "sp_cut=1"

if defined sp_cut if defined sp_get set /a sp_ary_len+=1 & ^
set "data_[!sp_ary_len!]=!sp_get!" &set "data_str_cnt[!sp_ary_len!]=!str_len!" & ^
set "sp_get=" &set /a str_len=0

) else exit /b
goto table_split_loop

:table_title
set "title_print=" &set /a len=0
set "title=State Total Local_Host(max|min) Foreign_Host(max|min)"
set /a interval=8 &set Title_Instant_Print=false
for /l %%0 in (1, 1, !interval!) do set "interval_= !interval_!"
for %%a in (!title!) do set "title_print=!title_print!%%a!interval_!" &set "interval_=!interval_:~0,6!"
for %%a in (!title!) do (set "str=%%a" &set /a str_cnt=0
for /l %%0 in (0, 1, 25) do if defined str set "str=!str:~1!" &set /a str_cnt+=1
set /a len+=1 &set /a title_len[!len!]=!str_cnt!)
set "title_print=!title_print:~0,-6!"
set "title_len=" &set "interval_=" &set "title_print=!title_print:_= !"
echo [ok] table_title &exit /b

:filter_echo
set "filter_echo=" &for %%a in (%fl_search_check%) do set "search_echo[%%a]="

for %%a in (TCP UDP listen est handsh) do if defined filter_%%a set "filter_echo=!filter_echo!, %%a"
echo Filter:[!filter_echo:~2!]

for %%a in (%fl_search_check%) do if defined filter_%%a ^
for %%b in (!filter_%%a!) do if "%%a"=="ip" (set "b=%%b"
set "b=!b:_=*!" &set "search_echo[%%a]=!search_echo[%%a]!, !b!") ^
else set "search_echo[%%a]=!search_echo[%%a]!, %%b"

for %%a in (%fl_search_check%) do if defined search_echo[%%a] echo Search %%a:[!search_echo[%%a]:~2!]

exit /b

:filter_get
for /l %%0 in (1, 1, !fi_return_len!) do set "fi_return[!fi_return_len!]="
set /a fi_return_len=0

for /l %%0 in (1, 1, !output_len!) do for /f "tokens=1-5" %%a in ("!output[%%0]!") do (
set "raw=!output[%%0]!"

set "get=" &set "fl_match=" &set /a index=0
for %%t in (pid port ip) do (set /a index+=1

if defined filter_%%t set "fl_match=1" &for %%f in (!filter_%%t!) do (

if !index!==1 (if %%a==TCP (if %%e==%%f set "get=1" &set "raw=!raw:  %%e=  {%%e}!") ^
else if %%a==UDP (if %%d==%%f set "get=1" &set "raw=!raw:  %%d=  {%%d}!"))

if !index!==2 set "b=%%b" &set "c=%%c" & ^
if "!b:~0,1!"=="[" (for /f "tokens=2 delims=]" %%i in ("!b::=!") do if %%i==%%f set "get=1" &set "raw=!raw::%%i =:{%%i} !") ^
else if "!c:~0,1!"=="[" (
for /f "tokens=2 delims=]" %%i in ("!c::=!") do if %%i==%%f set "get=1" &set "raw=!raw::%%i =:{%%i} !") ^
else for /f "tokens=2,4 delims=:" %%i in ("%%b:%%c") do ^
if %%i==%%f (set "get=1" &set "raw=!raw::%%i =:{%%i} !") else if "%%j"=="%%f" set "get=1" &set "raw=!raw::%%j =:{%%j} !"

if !index!==3 set "b=%%b" &set "c=%%c" & ^
if "!b:~0,1!"=="[" (for /f "tokens=1 delims=]" %%i in ("%%b") do if %%i]==%%f set "get=1" &set "raw=!raw:%%i]={%%i]}!") ^
else (set "f=%%f" &if not "0!f:_=!"=="0!f!" (for %%x in (b c) do for /f "delims=:" %%y in ("!%%x!") do ^
for /f "tokens=1-8 delims=." %%i in ("%%y.%%f") do (set /a checkvar=0
if "%%i"=="%%m" (set /a checkvar+=1) else if "%%m"=="_" set /a checkvar+=1
if "%%j"=="%%n" (set /a checkvar+=1) else if "%%n"=="_" set /a checkvar+=1
if "%%k"=="%%o" (set /a checkvar+=1) else if "%%o"=="_" set /a checkvar+=1
if "%%l"=="%%p" (set /a checkvar+=1) else if "%%p"=="_" set /a checkvar+=1
if !checkvar!==4 set "get=1" &set "raw=!raw: %%y= {%%y}!")
) else for /f "tokens=1,3 delims=:" %%i in ("%%b:%%c") do ^
if %%i==%%f (set "get=1" &set "raw=!raw:%%i={%%i}!") else if %%j==%%f set "get=1" &set "raw=!raw:%%j={%%j}!")))

if not defined fl_match set "get=1"
if defined get (if "%debug_print_raw%"=="1" echo !raw!
if %%a==TCP if defined filter_TCP (
if %%d==%state_listen% (if defined filter_listen set /a fi_return_len+=1 &set fi_return[!fi_return_len!]=!raw!) ^
else if %%d==%state_est% (if defined filter_est set /a fi_return_len+=1 &set fi_return[!fi_return_len!]=!raw!) ^
else if defined filter_handsh set /a fi_return_len+=1 &set fi_return[!fi_return_len!]=!raw!)
if %%a==UDP if defined filter_UDP set /a fi_return_len+=1 &set fi_return[!fi_return_len!]=!raw!))
if "%debug_print_raw%"=="1" pause
exit /b

:filter_settings
set "filter_check=TCP UDP listen est handsh"
set "fl_search_check=pid port ip"
set "fl_start_check=pid port ip cls"
set "fl_prefix=+ - / @"
echo [ok] filter_settings &exit /b

:filter_set
echo.
if "%show_filter_intro%"=="1" (
echo ===================================================================================
echo Set Filter:
echo Proto: [TCP, UDP]
echo State: [listen, est, handsh]
echo -----------------------------------------------------------------------------------
echo Search type: include
echo Search PID: /pid "pid" ^(e.g. /pid 0 4 123 321 ...^)
echo Search Port: /port "port" ^(e.g. /port 9051 443 80 ...^)
echo Search IP Address: /ip "ip" ^(e.g. /ip 127.0.0.1 172.217.160.78 ...^)
echo Clear: /cls command ^(e.g. /cls pid port ...^)
echo -----------------------------------------------------------------------------------
echo Clear All Filter: /cls
echo -----------------------------------------------------------------------------------
echo Prefix the command with '+' or '-' to specify whether the type should be displayed.
echo e.g. @handsh
echo e.g. -UDP
echo e.g. -UDP -listen +est
echo e.g. -TCP +UDP /pid 123
echo e.g. /pid 4232 4 812 /ip 172.217.160.78 127.0.0.1 /port 443 80 -listen
echo e.g. /ip 127.*.*.* 192.168.*.*
echo ===================================================================================
echo.)
set "filter=" &set /p "filter=Set Filter:"

if defined filter (set "fl_start="

call :str_replace "filter" "filter" "*" "_"

for %%a in (!filter!) do (set "cont=%%a" &set "cont_=!cont:~0,1!"

for %%n in (%fl_prefix%) do if !cont_!==%%n set "fl_start="

if defined fl_start (
for %%i in (pid port ip) do if "!fl_start!"=="%%i" (if defined filter_%%i (
if "0!filter_%%i:%%a=!"=="0!filter_%%i!" set "filter_%%i=!filter_%%i! %%a") ^
else set "filter_%%i=!filter_%%i! %%a")
if "!fl_start!"=="cls" set "fl_wait=" &for %%i in (%fl_search_check%) do if %%a==%%i set "filter_%%a=")

if "!fl_wait!"=="cls" set "filter_listen=1" &set "filter_est=1" &set "filter_handsh=1" & ^
set "filter_TCP=1" &set "filter_UDP=1" &set "filter_pid=" &set "filter_port=" &set "filter_ip=" & ^
set "fl_wait=" &set "filter_switch="

if not defined fl_start (
if "%%a"=="/cls" set "fl_wait=cls"
if "!cont_!"=="/" (for %%b in (%fl_start_check%) do if "!cont:~1!"=="%%b" set "fl_start=%%b"
if not defined fl_start set "get=!cont:~1!") else (

set /a cnt=0 &for %%b in (!filter_check!) do set /a cnt+=1 & ^
if "!cont:~1!"=="%%b" (if "!cont_!"=="+" (set "filter_%%b=1") else if "!cont_!"=="-" (set "filter_%%b=") ^
else if "!cont_!"=="@" (if !cnt! LEQ 2 (
if %%b==TCP for %%i in (!filter_check!) do (set "filter_%%i=1") &set "filter_UDP=" &set "filter_pid="
if %%b==UDP for %%i in (!filter_check!) do (set "filter_%%i=") &set "filter_UDP=1") ^
else if !cnt! GEQ 4 for %%i in (!filter_check!) do (set "filter_%%i=") &set "filter_TCP=1" &set "filter_%%b=1")))
))

if "!fl_wait!"=="cls" set "filter_listen=1" &set "filter_est=1" &set "filter_handsh=1" & ^
set "filter_TCP=1" &set "filter_UDP=1" &set "filter_pid=" &set "filter_port=" &set "filter_ip=" & ^
set "filter_switch="

set "filter_switch="
for %%a in (%filter_check%) do if not defined filter_%%a set "filter_switch=1"
for %%a in (%fl_start_check%) do if defined filter_%%a set "filter_switch=1"

set "cont=" &set "cont_=" &set "next=" &set "get=" &set "fl_wait=")
exit /b

:str_replace <return> <str> <from> <to>
set "rp_get=" &set "return_=%~1" &set "str_=!%~2!" &set "form_=%~3" &set "to_=%~4"
for %%a in (str_ form_ return_) do if not defined %%a exit /b 1
:str_replace_loop
for %%i in (20 30 50 100) do for /l %%0 in (0, 1, %%i) do ^
if defined str_ (set "sp_=!str_:~0,1!" &set "str_=!str_:~1!"
if "!sp_!"=="!form_!" (if defined to_ set "rp_get=!rp_get!!to_!") else set "rp_get=!rp_get!!sp_!"
) else set "%~1=!rp_get!" &exit /b 0
goto str_replace_loop

:sync_catch
title=%sub_win_title%
cls &set "pass=" &set /a rate=0
:sync_catch_loop
if exist %sync_switch% (cls
for /f "tokens=*" %%a in ('type %sync_data%') do if "%%a"=="echo." (echo.) else echo %%a
del %sync_data% &del %sync_switch%)

set /a rate+=1
if !rate!==240 title=%sub_win_title% [Receiving]
if !rate!==480 title=%sub_win_title% &set /a rate=0
if not exist %sync_running% exit
goto sync_catch_loop

:sync_sent_data <data>
set "data_=%~1"
echo %data_% >>%sync_data%
exit /b

:sync_sent_switch <state>
set "state_=%~1"
if "%state_%"=="open" (if not exist %sync_switch% echo %state_% >%sync_switch%)
if "%state_%"=="close" del %sync_switch%
exit /b

:sync_start <type> <title>
set "type_=%~1" &set "title_=%~2"

if "%type_%"=="popup_stats" set "win_set=popup_stats"

if defined title_ (set "sub_win_title=%win_title% %title_%") ^
else set "sub_win_title=%win_title%"

echo running>%sync_running%
set "pass=sync_catch"
call :sync_add "sub"
set "win_set=" &set "pass="
exit /b

:sync_add <sync_type>
set "type_=%~1"

if "%type_%"=="main" (
for /f %%a in ('type sync_id_total.sync') do set /a sync_id_total=%%a
set /a sync_id_total+=1 &echo !sync_id_total!>sync_id_total.sync)

set "tmp=%sync_type%" &set "sync_type=%type_%"
start %~f0
set "sync_type=%tmp%" &set "tmp="
set "win_set=" &set "pass="
exit /b

:sync_kill
if exist %sync_running% del %sync_running%
exit /b

:start
cls &color 07
echo loading......
set "enter="
for /f "tokens=1" %%a in ('tasklist /fi "pid eq %pid%" ^| findstr %pid%') do set imgname=%%a
title=%win_title% - %imgname%
if %without_delay%==1 (set /a delay=0) else set /a delay=1
tasklist /fi "pid eq %pid%" | findstr "%pid%" 2>&1>nul || goto died

if "%quick_mode%"=="1" color 0a &goto single_quick
if "%stats_table_only%"=="1" call :cmd_settings "stats"
if "%popup_StatsTable%"=="1" call :sync_start "popup_stats" "Stats - %imgname%(%pid%)"
goto single

:single
set /a output_len=0

for /f "tokens=*" %%a in ('tasklist /fi "pid eq %pid%"') do ^
for /f "tokens=5" %%i in ("%%a") do set "tasklist_cont=%%a" &set "memusage=%%i"
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /e %pid%') do for /f "tokens=1" %%p in ("%%a") do ^
if %%p==TCP (for /f "tokens=5" %%t in ("%%a") do if %%t==%pid% set/a output_len+=1 &set output[!output_len!]=%%a) ^
else if %%p==UDP for /f "tokens=4" %%u in ("%%a") do if %%u==%pid% set/a output_len+=1 &set output[!output_len!]=%%a

if "%popup_StatsTable%"=="1" ^
echo [Image Name:%imgname% ^| PID:%pid%] [Mem Usage:%memusage%]>%sync_data% &echo echo.>>%sync_data%

for /l %%0 in (1, 1, !data_len!) do set "table[%%0]="
if "%stats_table_only%"=="1" (call :stats_table "output") else call :stats_table "output" "sort"

title=%win_title% - %imgname%(%pid%) Total:!cnt_total[0][0]! [Est:!cnt_est[0][0]! ^(LH:!cnt_est[1][0]! FH:!cnt_est[2][0]!^)]

cls

if "%stats_table_only%"=="1" (echo [Image Name:%imgname% ^| PID:%pid%]) ^

else (echo.
echo Image Name                     PID Session Name        Session#    Mem Usage
echo ========================= ======== ================ =========== ============
echo %tasklist_cont%
echo. &echo   %netstat_title_%

if !output_len! GTR 0 (if "%color_text%"=="1" (
for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (echo.
for /l %%1 in (1, 1, !sort[%%0][0]!) do (
if %%0==0 echo   %ESC%[103;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==1 echo   %ESC%[46;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==2 echo   %ESC%[47;30m!sort[%%0][%%1]!%ESC%[0m
if %%0==3 echo   %ESC%[44;1m!sort[%%0][%%1]!%ESC%[0m
if %%0==4 echo   !sort[%%0][%%1]!
if %%0==5 echo   !sort[%%0][%%1]!))) ^
else (for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (echo.
if %%0==0 echo   %state_space%[%state_listen%] &echo.
if %%0==1 echo   %state_space%[%state_handshake%] &echo.
if %%0==2 echo   %state_space%[%state_est%] &echo.
if %%0==3 if !sort[2][0]!==0 echo   %state_space%[%state_est%] &echo.
if %%0==4 echo   %state_space%[UDP] &echo.
if %%0==5 if !sort[4][0]!==0 echo   %state_space%[UDP] &echo.
for /l %%1 in (1, 1, !sort[%%0][0]!) do echo   !sort[%%0][%%1]!))
for /l %%0 in (1, 1, !output_len!) do set "output[!output_len!]="
) else echo. &echo ^(Empty^))

if !data_len! GTR 0 (if "%popup_StatsTable%"=="1" (
if exist %sync_data% call :sync_sent_switch "open") ^

else echo. &echo   !title_print! &echo. & ^
for /l %%0 in (1, 1, !data_len!) do echo   !table[%%0]!)

:single_opt
echo. &if "%without_delay%"=="1" (echo [Without-Delay Mode]) ^
else (choice /n /c hpmndkx1r /t %delay% /d r /m "[H - Help] [P - Pause] [M - Back to Menu]:"
if !ERRORLEVEL!==1 (echo.
echo [H - Help]
echo [D - Start Without-Delay mode]
echo [M - Back to Menu]
echo [N - Open a new cmd window]
echo [P - Pause]
echo [R - Reload]
echo [K - Kill Process]
echo [X - Exit]
echo [1 - Pop-up Stats table]
pause)
if !ERRORLEVEL!==2 pause
if !ERRORLEVEL!==3 if "%popup_StatsTable%"=="1" (goto init_reset) else goto init
if !ERRORLEVEL!==4 call :sync_add "main"
if !ERRORLEVEL!==5 set "without_delay=1" &set /a delay=0
if !ERRORLEVEL!==6 taskkill /f /t /pid %pid%
if !ERRORLEVEL!==7 call :sync_kill &exit
if !ERRORLEVEL!==8 (set "popup_StatsTable=1"
if exist %sync_running% del %sync_running%
call :sync_start "popup_stats" "Stats - %imgname%(%pid%)"))

tasklist /fi "pid eq %pid%" | findstr "%pid%" 2>&1>nul || goto died
goto single

:all
cls
if "%debug_running_time%"=="1" echo %time%

call :filter_echo

if not defined filter_switch (set "output_switch=output" &set /a output_len=0
for /f "tokens=*" %%a in ('netstat -ano') do set /a output_len+=1 &set output[!output_len!]=%%a
) else set "output_switch=fi_return" &call :filter_get

if "%popup_StatsTable%"=="1" echo [netstat]>%sync_data% &echo echo.>>%sync_data%

for /l %%0 in (1, 1, !data_len!) do set "table[%%0]="
call :stats_table "%output_switch%" "sort"

title=%win_title% - netstat Total:!cnt_total[0][0]! [Est:!cnt_est[0][0]! ^(LH:!cnt_est[1][0]! FH:!cnt_est[2][0]!^)]

for %%$ in (!output_switch!) do if !%%$_len! GTR 0 (

if "%color_text%"=="1" (
for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (echo.
if %%0==0 echo   !state_space!%ESC%[103;30m[%state_listen%]%ESC%[0m &echo.
if %%0==1 echo   !state_space!%ESC%[46;30m[%state_handshake%]%ESC%[0m &echo.
if %%0==2 echo   !state_space!%ESC%[47;30m[%state_est%]%ESC%[0m &echo.
if %%0==3 echo   !state_space!%ESC%[44;1m[%state_est%]%ESC%[0m &echo.
if %%0==4 echo   !state_space!%ESC%[102;30m[UDP]%ESC%[0m &echo.

for /l %%1 in (1, 1, !sort[%%0][0]!) do (
if defined fl_match ^
set "sort[%%0][%%1]=!sort[%%0][%%1]:{=%ESC%[47;30m!" & ^
set "sort[%%0][%%1]=!sort[%%0][%%1]:}=%ESC%[0m!"
echo   !sort[%%0][%%1]! &set "sort[%%0][%%1]="))) ^

else (for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (echo.
if %%0==0 echo   %state_space%[%state_listen%] &echo.
if %%0==1 echo   %state_space%[%state_handshake%] &echo.
if %%0==2 echo   %state_space%[%state_est%] &echo.
if %%0==3 if !sort[2][0]!==0 echo   %state_space%[%state_est%] &echo.
if %%0==4 echo   %state_space%[UDP] &echo.
if %%0==5 if !sort[4][0]!==0 echo   %state_space%[UDP] &echo.
for /l %%1 in (1, 1, !sort[%%0][0]!) do echo   !sort[%%0][%%1]! &set "sort[%%0][%%1]="))

) else echo. &echo ^(Empty^)

if !data_len! GTR 0 (if "%popup_StatsTable%"=="1" (
if exist %sync_data% call :sync_sent_switch "open") ^

else echo. &echo   !title_print! &echo. & ^
for /l %%0 in (1, 1, !data_len!) do echo   !table[%%0]!)

if "%debug_running_time%"=="1" echo %time%

call :all_opt
for /l %%0 in (1, 1, !output_len!) do set "output[!output_len!]="
goto all

:all_opt
echo. &set "all_reload="
choice /n /c hmfnkx1r /m "[H - Help] [M - Back to Menu] [R - Reload] [F - Set Filter]:"
if %ERRORLEVEL%==1 (echo.
echo [H - Help]
echo [M - Back to Menu]
echo [R - Reload]
echo [F - Set Filter]
echo [N - Open a new cmd window with Single Monitor mode]
echo [K - Kill Process]
echo [X - Exit]
echo [1 - Pop-up Stats table])
if %ERRORLEVEL%==2 if "%popup_StatsTable%"=="1" (goto init_reset) else goto init
if %ERRORLEVEL%==3 call :filter_set & ^
if defined filter (
echo ===================================================================================
call :filter_echo &call :search)

if %ERRORLEVEL%==4 echo. &set /p "pid_=[New Monitor] Please enter The PID:" & ^
call :pid_check !pid_! &if !ERRORLEVEL!==0 set "pass=start" &call :sync_add "main"

if %ERRORLEVEL%==5 echo. &set /p "pid_=[Kill Process] Please enter The PID:" & ^
call :pid_check !pid_! &if !ERRORLEVEL!==0 taskkill /f /t /pid !pid!
set "pid_="

IF %ERRORLEVEL%==6 call :sync_kill &exit
if %ERRORLEVEL%==7 (set "popup_StatsTable=1"
if exist %sync_running% del %sync_running%
call :sync_start "popup_stats" "netstat - Stats Table"
echo [netstat]>%sync_data% &echo echo.>>%sync_data%
echo !title_print!>>%sync_data% &echo echo.>>%sync_data%
for /l %%0 in (1, 1, !data_len!) do echo !table[%%0]!>>%sync_data%
if exist %sync_data% call :sync_sent_switch "open")

if %ERRORLEVEL%==8 set "all_reload=1"

if defined all_reload exit /b
goto all_opt

:search
if not defined filter_switch (set "output_switch=output"
) else set "output_switch=fi_return" &call :filter_get

if "%popup_StatsTable%"=="1" echo [netstat]>%sync_data% &echo echo.>>%sync_data%

for /l %%0 in (1, 1, !data_len!) do set "table[%%0]="
call :stats_table "%output_switch%" "sort"

title=%win_title% - netstat Total:!cnt_total[0][0]! [Est:!cnt_est[0][0]! ^(LH:!cnt_est[1][0]! FH:!cnt_est[2][0]!^)]

for %%$ in (!output_switch!) do if !%%$_len! GTR 0 (

if "%color_text%"=="1" (
for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (echo.
if %%0==0 echo   !state_space!%ESC%[103;30m[%state_listen%]%ESC%[0m &echo.
if %%0==1 echo   !state_space!%ESC%[46;30m[%state_handshake%]%ESC%[0m &echo.
if %%0==2 echo   !state_space!%ESC%[47;30m[%state_est%]%ESC%[0m &echo.
if %%0==3 echo   !state_space!%ESC%[44;1m[%state_est%]%ESC%[0m &echo.
if %%0==4 echo   !state_space!%ESC%[102;30m[UDP]%ESC%[0m &echo.

for /l %%1 in (1, 1, !sort[%%0][0]!) do (
if defined fl_match if "%color_text%"=="1" ^
set "sort[%%0][%%1]=!sort[%%0][%%1]:{=%ESC%[47;30m!" & ^
set "sort[%%0][%%1]=!sort[%%0][%%1]:}=%ESC%[0m!"
echo   !sort[%%0][%%1]! &set "sort[%%0][%%1]="))) ^

else (for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (echo.
if %%0==0 echo   %state_space%[%state_listen%] &echo.
if %%0==1 echo   %state_space%[%state_handshake%] &echo.
if %%0==2 echo   %state_space%[%state_est%] &echo.
if %%0==3 if !sort[2][0]!==0 echo   %state_space%[%state_est%] &echo.
if %%0==4 echo   %state_space%[UDP] &echo.
if %%0==5 if !sort[4][0]!==0 echo   %state_space%[UDP] &echo.
for /l %%1 in (1, 1, !sort[%%0][0]!) do echo   !sort[%%0][%%1]! &set "sort[%%0][%%1]="))

) else echo. &echo ^(Empty^)

if !data_len! GTR 0 (if "%popup_StatsTable%"=="1" (
if exist %sync_data% call :sync_sent_switch "open") ^

else echo. &echo   !title_print! &echo. & ^
for /l %%0 in (1, 1, !data_len!) do echo   !table[%%0]!)
exit /b

:single_quick
set /a output_cnt=0 &set /a sort_len=2 &for /l %%0 in (0, 1, !sort_len!) do set /a sort[%%0][0]=0
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /e %pid%') do (
for /f "tokens=5" %%b in ("%%a") do if %%b==%pid% set/a output_cnt+=1 &set output[!output_cnt!]=%%a)
if !output_cnt!==0 (echo. &echo ^(Empty^)) else (
for /l %%0 in (1, 1, !output_cnt!) do for /f "tokens=4" %%a in ("!output[%%0]!") do (
if %%a==%state_listen% (set /a sort[0][0]+=1 &set "sort[0][!sort[0][0]!]=!output[%%0]!") ^
else if %%a==%state_est% (set /a sort[2][0]+=1 &set "sort[2][!sort[2][0]!]=!output[%%0]!") ^
else (set /a sort[1][0]+=1 &set "sort[1][!sort[1][0]!]=!output[%%0]!"))
cls &echo [Quick mode] Image Name: %imgname% ^| PID: %pid% &echo.
echo   Proto  Local Address          Foreign Address        State           PID
for /l %%0 in (0, 1, !sort_len!) do if not !sort[%%0][0]!==0 (
echo.
if %%0==1 echo   !state_space![%state_handshake%] &echo.
if %%0==2 echo   !state_space![%state_est%] &echo.
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
goto single_quick

:died
cls &echo %imgname% is Closed.
if "%popup_StatsTable%"=="1" call :sync_kill
pause
if "%stats_table_only%"=="1" goto init_reset
goto init

:init_reset
set "enter=" &set "pid=0" &set "imgname=0"
set "list_w=" &set "list_b="
set "filter_PID=" &set "all_reload="
set "win_set=" &set "pass="
call :sync_kill
call :init_filter &call :init_stats
set "reset=1" &start %~f0 &exit

:init
cls &title=%win_title% &color 0e &chcp 1252 >nul
set "enter=" &set "pid=0" &set "imgname=0"
set "list_w=" &set "list_b="
set "filter_PID=" &set "all_reload="
set "win_set=" &set "pass="
call :init_filter &call :init_stats
goto main

:init_RunOnce
color 0e &chcp 1252 >nul
echo loading......

if defined reset set "reset=" &title=%win_title% &goto main

if not defined sync_id (
if exist *.sync del *.sync &echo 0>sync_id_total.sync
set /a sync_id_total=0 &set /a sync_id=0 &set "sync_type=main"
set "win_title=Port Monitor" &title=!win_title!
call :setESC &call :settings &call :run_cmd
call :port_list &call :filter_settings &call :table_title
call :init_filter &call :default_check &call :set_static_var &call :init_stats) ^
else (for /l %%0 in (1, 1, !data_len!) do set "table[%%0]="
if "%sync_type%"=="main" for /f %%a in ('type sync_id_total.sync') do set /a sync_id=%%a
set "win_title=Port Monitor [!sync_id!]" &title=!win_title!
call :init_filter &call :init_stats)
set "sync_data=%sync_id%_data.sync" &set "sync_switch=%sync_id%_switch.sync"
set "sync_running=%sync_id%_running.sync"

if defined win_set set "win_set=" &call :cmd_settings "%win_set%"

if "%debug_starting_echo%"=="1" pause
if defined pass (set "pass_%pass%=1" &goto %pass%) else set pid=0
goto main

:cmd_settings <switch>
set "switch_=%~1"
if not defined switch_ exit /b 1
set "case=if "%switch_%"==" &set "break=exit /b 0"

%case%"popup_stats" (color 07 &chcp 1252 >nul
mode con:cols=75 lines=10 &%break%)

%case%"stats" mode con:cols=75 lines=10 &%break%
exit /b 0

:run_cmd
set "size_stats=mode con:cols=75 lines=12"
echo [ok] run_cmd &exit /b
:set_static_var
set "state_space=                              "
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /i "PID"') do set "netstat_title_=%%a"
set /a cnt=0 &for %%a in (%state_listen% %state_handshake% %state_est% UDP Total) do ^
set /a cnt+=1 &set "state_table[!cnt!]=%%a"
set /a cnt=0 &for %%a in (103x30m 47x30m 44x1m 102x30m 0x0m) do ^
set /a cnt+=1 &for %%b in (!cnt!) do set "color_table[%%b]=%%a" &set "color_table[%%b]=!color_table[%%b]:x=;!"
set /a cnt=0 &for %%a in (93m 36m 34m 92m 0m) do ^
set /a cnt+=1 &for %%b in (!cnt!) do set "color_table2[%%b]=%%a"
set /a cnt=0
echo [ok] set_static_var &exit /b
:default_check
set "list_w=" &set "list_b="
set /a cnt=0 &for %%a in (1 1 1 0 0 0 img) do set /a cnt+=1 &set "default[!cnt!]=%%a"
set /a cnt=0
for %%a in (show_details show_filter_intro color_text without_delay quick_mode stat_table_only enter_mode) do ^
set /a cnt+=1 &if not defined %%a for %%i in (!cnt!) do set "%%a=!default[%%i]!"
set /a cnt=0
echo [ok] default_check &exit /b
:init_filter
set "filter_listen=1" &set "filter_est=1" &set "filter_handsh=1"
set "filter_TCP=1" &set "filter_UDP=1" &set "filter_PID=" &set "filter_switch="
set "filter_listen=1" &set "filter_est=1" &set "filter_handsh=1" & ^
set "filter_TCP=1" &set "filter_UDP=1" &set "filter_pid=" &set "filter_port=" &set "filter_ip="
echo [ok] init_filter &exit /b
:init_stats
set "stats_bln=1"
for /l %%0 in (0, 1, 2) do for /l %%1 in (0, 1, 2) do ^
set /a cnt_listen[%%0][%%1]=0 &set /a cnt_handsh[%%0][%%1]=0 & ^
set /a cnt_est[%%0][%%1]=0 &set /a cnt_udp[%%0][%%1]=0 &set /a cnt_total[%%0][%%1]=0
echo [ok] init_stats &exit /b

REM Cool Stuff win10colors.cmd by Michele Locati (github/mlocati). Respect!!!
:setESC
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set ESC=%%b
  exit /B 0
)
exit /B 0

:eof
echo oops &pause
