@echo off


rem change dir to this batch file location
%~d0
cd %~p0

rem set local variables

rem top directory of data
set TOP=_prev

rem working directory
set WKD=%TOP%\tmp

rem template of commit comment file
set TEMPL=%WKD%\commit_msg.teml

rem commit comment for user edit (including messege for user)
set TEXT=%WKD%\commit_msg.txt

rem latest commit comment
set LATEST=%TOP%\latest.log

rem accumulated commit comments (all log)
set LOG=%TOP%\commit.log

rem exclude file 
set EXCLUDE=%TOP%\exclude.lst

rem destination of backup
set DEST=%TOP%\data

rem create data directory 
if not exist %TOP%\nul   mkdir %TOP%
if not exist %DEST%\nul  mkdir %DEST%
if not exist %WKD%\nul   mkdir %WKD%


rem finish preparation 


rem switch by first argument.

rem default is creating subcommand batch
if "%1"=="" goto :create_bat
if "%1"=="init" goto :create_bat


rem commit 
if "%1"=="commit" goto :commit

if "%1"=="exclude" goto :exclude

echo Error:: unknown command: %1
echo available commands are
echo;
echo   commit         : backup files with commit message.
echo                    backup will be create in %DEST%
echo;
echo   exclude        : edit exclude list file.
echo;
echo   exclude file(s): add given files into exclude file with relative path.
echo;

pause 
goto :eof

rem ************************************************************************************************
:create_bat

echo %0 commit> commit.bat
echo %0 exclude %%*> exclude.bat 

rem create initial exclude filelist if not present
if not exist %EXCLUDE% echo ./_prev>>%EXCLUDE%

findstr ./commit.bat %EXCLUDE% >nul
if errorlevel 1 echo ./commit.bat>> %EXCLUDE%
findstr ./exclude.bat %EXCLUDE% >nul
if errorlevel 1 echo ./exclude.bat>> %EXCLUDE%

echo Setup finished.
goto :fin

rem ************************************************************************************************
:exclude

rem save wokring dir
set PWD=%~dp0

rem if target file is not specified, edit exclude file directory
if "%~2"=="" goto :edit_exclude

rem if target files were specified, add them into exclude file.

:nextfile

rem target file is the first argument.
shift

rem reset working variables
set WK=%PWD%
set TGT=%~1

if not "%TGT:~1,1%"==":" goto :relative

rem remove pwd prefix
:loop
set WK=%WK:~1%
set TGT=%TGT:~1%
if not "%WK%"=="" goto :loop

rem check target is remain or not.
if "%TGT%"==""  goto :next_check

:relative

rem save relative path into exclude file with / instead of \ 
@echo on
echo ./%TGT:\=/%>> %EXCLUDE%
@echo off

:next_check
rem repeat while target files remain.
if not "%2"=="" goto :repeat

pause

rem finish
goto :eof

:edit_exclude
if not exist %EXCLUDE% echo: > %EXCLUDE%
start %EXCLUDE%
goto :eof


rem ************************************************************************************************
:commit

rem if exist %TEMPL% goto setup
rem create template if not exist
echo;> %TEMPL%
echo #Enter commit coment above.>>%TEMPL%
echo #If you want cancel commiting, Exit without change and save.>> %TEMPL%
echo #lines start with # mean comment line. they will be removed from commit log.>> %TEMPL%

:setup
rem copy tamplate to text for user editing.
copy %TEMPL% %TEXT% > nul

rem run text editor for commit comment
start /wait %TEXT%

rem check execute or cancel.
fc %TEMPL% %TEXT% >nul
if ERRORLEVEL 1 goto :exec_commit

rem cancel if text was not changed.

rem show message
echo commit was canceled.

del %TEXT% > nul


rem finished.
goto fin

:exec_commit
rem show message
echo commiting ...

rem create(overwrite) latest log
echo commted on %DATE% %TIME%> %LATEST%
findstr /V /B # %TEXT% >> %LATEST%

rem Append to LOG
echo ---------------------------------->> %LOG%
type %LATEST% >> %LOG%

del %TEXT% >nul

rem if exclude file does not exist, create it with nessesary setting.
if not exist %EXCLUDE% echo ./_prev>>%EXCLUDE%

rem start backup
@echo on
rdiff-backup --print-statistics --include ./%EXCLUDE% --exclude-globbing-filelist ./%EXCLUDE:\=/%  ./ ./%DEST%
@echo off

rem show message.
echo done.

:fin
rem terminating
pause
