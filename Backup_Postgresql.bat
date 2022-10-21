@echo off

rem =====================================================
REM Backup PostgreSQL Database with 7zip compression
rem =====================================================

set HOST=localhost
set PGHOME=D:\PROGRAM\pg\
set BACKUPDIR=D:\Backup_Postgresql
set DUMPDIR=%BACKUPDIR%\dump
rem ##### set PGBASEBACKUP=%BACKUPDIR%\pg_basebackup
set BASES=%BACKUPDIR%\bases.txt
set USER="postgres"
set ZIPDIRPROGRAM="C:\Program Files\7-Zip"
rem =====================================================
rem Senha configurada em %APPDATA%\postgresql\pgpass.conf, mas fixei abaixo para funcionar com outros usuários
set PGPASSFILE=C:\Users\administrator\AppData\Roaming\postgresql\pgpass.conf
rem =====================================================

echo ==========================================================
echo ======= %date% %time% Dump Iniciado 
echo ==========================================================

CD %DUMPDIR% || goto :error_cd_dumpdir
rem ##### CD %PGBASEBACKUP% || goto :error_cd_pgbasebackup

del %DUMPDIR%\*.dump %DUMPDIR%\*.dump.7z
rem ##### del %PGBASEBACKUP%\*.dump %PGBASEBACKUP%\*.dump.7z
dir %DUMPDIR%

echo ======= %date% %time% pg_dumpall
%PGHOME%\bin\pg_dumpall -U %USER% -h %HOST% -w -g >%DUMPDIR%\globalobjects.dump || goto :error_dumpall
%ZIPDIRPROGRAM%\7z a -bso0 -bsp0 %DUMPDIR%\globalobjects.dump.7z %DUMPDIR%\globalobjects.dump || goto :error_7z_globobj
del %DUMPDIR%\globalobjects.dump

%PGHOME%\bin\psql -U %USER% -h %HOST% -w -d template1 -q -t -c "select datname from pg_database where datname not in ('template0') order by datname;" >%BASES% || goto :error_getbases

for /F %%b in (%BASES%) do (
  setlocal EnableDelayedExpansion
  echo ======= !date! !time! Backup da base : '%%b'
  setlocal DisableDelayedExpansion
  %PGHOME%\bin\pg_dump -U %USER% -h %HOST% -w -s %%b > %DUMPDIR%\%%b.schema.dump || goto :error_pgdump_schema
  %ZIPDIRPROGRAM%\7z a -bso0 -bsp0 %DUMPDIR%\%%b.schema.dump.7z %DUMPDIR%\%%b.schema.dump || goto :error_7z_schema
  del %DUMPDIR%\%%b.schema.dump
  %PGHOME%\bin\pg_dump -U %USER% -h %HOST% -w %%b > %DUMPDIR%\%%b.data.dump || goto :error_pgdump_data
  %ZIPDIRPROGRAM%\7z a -bso0 -bsp0 %DUMPDIR%\%%b.data.dump.7z %DUMPDIR%\%%b.data.dump || goto :error_7z_data
  del %DUMPDIR%\%%b.data.dump
)
dir %DUMPDIR%

rem ##### %PGHOME%\bin\pg_basebackup -h %HOST% -D %PGBASEBACKUP%\ -Ft -z -Z 9 -v || exit 2

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

rem ##### :error_cd_pgbasebackup
rem ##### set nivelerro=%errorlevel%
rem ##### echo ==========================================================
rem ##### echo ======= %date% %time% ErrorLevel=%nivelerro% Erro 'CD %PGBASEBACKUP%'
rem ##### echo ==========================================================
rem ##### exit %nivelerro%

:error_dumpall
set nivelerro=%errorlevel%
echo ==========================================================
echo ======= %date% %time% ErrorLevel=%nivelerro% Erro pg_dumpall
echo ==========================================================
exit %nivelerro%

:error_getbases
set nivelerro=%errorlevel%
echo ==========================================================
echo ======= %date% %time% ErrorLevel=%nivelerro% Erro psql get_bases
echo ==========================================================
exit %nivelerro%

:error_pgdump_schema
set nivelerro=%errorlevel%
echo ==========================================================
echo ======= %date% %time% ErrorLevel=%nivelerro% Erro pgdump schema
echo ==========================================================
exit %nivelerro%

:error_pgdump_data
set nivelerro=%errorlevel%
echo ==========================================================
echo ======= %date% %time% ErrorLevel=%nivelerro% Erro pgdump data
echo ==========================================================
exit %nivelerro%

:error_7z_globobj
set nivelerro=%errorlevel%
echo ==========================================================
echo ======= %date% %time% ErrorLevel=%nivelerro% Erro 7z globalobjects
echo ==========================================================
exit %nivelerro%

:error_7z_schema
set nivelerro=%errorlevel%
echo ==========================================================
echo ======= %date% %time% ErrorLevel=%nivelerro% Erro 7z schema
echo ==========================================================
exit %nivelerro%

:error_7z_data
set nivelerro=%errorlevel%
echo ==========================================================
echo ======= %date% %time% ErrorLevel=%nivelerro% Erro 7z data
echo ==========================================================
exit %nivelerro%

rem ===================== EOF =====================
