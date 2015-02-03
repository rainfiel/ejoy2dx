@echo off

if defined VS120COMNTOOLS (
    call "%VS120COMNTOOLS%\vsvars32.bat"
) else if defined VS110COMNTOOLS (
    call "%VS110COMNTOOLS%\vsvars32.bat"
) else if defined VS100COMNTOOLS (
    call "%VS100COMNTOOLS%\vsvars32.bat"
) else (
    echo ERROR: Cannot found Visual Studio Toolset.
    echo Are you sure Visual Studio 2010 or later is installed?
    exit /B 1
)

if {%1}=={} (
	set configuration="Debug"
) else (
	set configuration=%1
)

msbuild "%~dp0/build/ejoy2d.sln" /m /v:m /t:rebuild /clp:ShowEventId /p:Configuration="%configuration%",Platform="Win32"
%~dp0/output/debug/ej2dx.exe %~dp0\..\..\ flappybird.lua