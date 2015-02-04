@echo off

set "PrjName=%~1"
goto :param1Check
:param1Prompt
SET /P PrjName="project name:"
:param1Check
if "%PrjName%"=="" goto :param1Prompt


python creator.py %PrjName%
pause
