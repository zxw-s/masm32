@echo off
ml /c /coff miniGUI32.asm
if errorlevel 1 goto err
link /subsystem:windows miniGUI32.obj user32.lib kernel32.lib
echo build ok: miniGUI32.exe
goto end
:err
echo compile error!
:end
pause