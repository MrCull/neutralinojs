@echo off

echo Looking for vswhere.exe...
set "vswhere=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%vswhere%" set "vswhere=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%vswhere%" (
	echo ERR: Failed to find vswhere.exe
	exit 1
)
echo Found %vswhere%

echo Looking for VC...
for /f "usebackq tokens=*" %%i in (`"%vswhere%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
  set vc_dir=%%i
)
if not exist "%vc_dir%\Common7\Tools\vsdevcmd.bat" (
	echo ERR: Failed to find VC tools x86/x64
	exit 1
)
echo Found %vc_dir%

set ARCH=%1

REM Trigger x64 build by default
if "%ARCH%" == "" (
    set ARCH=x64
)

set NEU_BIN=bin\neutralino-win_%ARCH%.exe

if %ARCH% == ia32 (
  set FLAGS=-arch=i386
)
if %ARCH% == x64 (
  set FLAGS=-arch=x64
) 
if not %ARCH% == ia32 if not %ARCH% == x64 (
    echo Unsupported instruction set architecture: %ARCH%
    exit 1
)

call "%vc_dir%\Common7\Tools\vsdevcmd.bat" %FLAGS% -host_arch=x64

if exist %NEU_BIN% (
    del /f %NEU_BIN%
)

echo Compiling Neutralinojs %ARCH%...

cl /std:c++17 ^
/I . ^
/I platform/windows/webview2 ^
/EHsc ^
/Os ^
main.cpp ^
settings.cpp ^
resources.cpp ^
server/neuserver.cpp ^
server/router.cpp ^
auth/authbasic.cpp ^
auth/permission.cpp ^
server/ping.cpp ^
helpers.cpp ^
lib/easylogging/easylogging++.cc ^
lib/boxer/boxer_win.cpp ^
api/computer/computer.cpp ^
api/filesystem/filesystem.cpp ^
api/os/os.cpp ^
api/storage/storage.cpp ^
api/debug/debug.cpp ^
api/app/app.cpp ^
api/window/window.cpp ^
api/events/events.cpp ^
/DELPP_NO_DEFAULT_LOG_FILE ^
/link platform/windows/webview2/WebView2Loader.dll.lib /OUT:%NEU_BIN%

if exist %NEU_BIN% (
    echo OK: Neutralino binary is compiled into %NEU_BIN%
) else (
    echo ERR: Neutralino binary is not compiled
)
