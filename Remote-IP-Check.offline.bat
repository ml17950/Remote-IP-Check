@echo off

call %~dp0Remote-IP-Check.config.bat

set HOST=%1

set SUBJECT=Remote-IP-Check: Host %HOST% offline
set MAILTXT=%DATE% %TIME%: Ping to host %HOST% failed

echo sending mail [%SUBJECT%] to %TO% ...
echo.
%~dp0cmail.exe -starttls -host:%SMTPUSR%:%SMTPPWD%@%SMTPSVR%:%SMTPPRT% -from:%FROM% -to:%TO% -bcc:%BCC% "-subject:%SUBJECT%" "-body:%MAILTXT%"
echo mail sent ...
