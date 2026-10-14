@echo off

call %~dp0Remote-IP-Check.config.bat

set LAST_IP=%1
set THIS_IP=%2

set SUBJECT=Remote-IP-Check: IP changed to %THIS_IP%
set MAILTXT=%DATE% %TIME%: IP changed from %LAST_IP% to %THIS_IP%

echo sending mail [%SUBJECT%] to %TO% ...
echo.
%~dp0cmail.exe -starttls -host:%SMTPUSR%:%SMTPPWD%@%SMTPSVR%:%SMTPPRT% -from:%FROM% -to:%TO% -bcc:%BCC% "-subject:%SUBJECT%" "-body:%MAILTXT%"
echo mail sent ...
