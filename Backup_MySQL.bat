@echo off
set MUSER=root
set MPASS="XXXXXX"
set BACKUPDIR=C:\BACKUP\MYSQL
set DUMPDIR=%BACKUPDIR%\DUMP
set MYSQLDUMP=C:\wamp64\bin\mysql\mysql5.7.36\bin\mysqldump.exe
set ZIPDIRPROGRAM="C:\Program Files\7-Zip"

echo ==========================================================
echo ======= %date% %time% Dump Iniciado 
echo ==========================================================

CD %DUMPDIR% || goto :error_cd_dumpdir

del %DUMPDIR%\*.dump %DUMPDIR%\*.dump.7z
dir %DUMPDIR%

echo ======= %date% %time% Inicio mysqldump
%MYSQLDUMP% -u %MUSER% -p"%MPASS%" -A > mysql.dump || goto :error_dumpal
%ZIPDIRPROGRAM%\7z a -bso0 -bsp0 %DUMPDIR%\mysql.dump.7z || goto :error_7z_dumpall
del %DUMPDIR%\mysql.dump
dir %DUMPDIR%

:ok
echo ==========================================================
echo ======= %date% %time% Dump Finalizado
echo ==========================================================
exit


:error_cd_dumpdir
set nivelerro=%errorlevel%
echo ==========================================================
echo ======= %date% %time% ErrorLevel=%nivelerro% Erro 'CD %DUMPDIR%'
echo ==========================================================
exit %nivelerro%

:error_dumpall
set nivelerro=%errorlevel%
echo ==========================================================
echo ======= %date% %time% ErrorLevel=%nivelerro% Erro dumpall
echo ==========================================================
exit %nivelerro%

:error_7z_dumpall
set nivelerro=%errorlevel%
echo ==========================================================
echo ======= %date% %time% ErrorLevel=%nivelerro% Erro 7z dumpall
echo ==========================================================
exit %nivelerro%
