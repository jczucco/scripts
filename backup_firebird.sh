#!/bin/bash
USER=sysdba
PASS="xxxxx"
HOST=localhost
FBHOME="/opt/firebird"
DATADIR="/storage/firebird"
BACKUPDIR="/storage/backup/firebird"

echo "$(date) Inicio Backup Firebird"
[ -d ${BACKUPDIR} ] && {

	# limpa diretorio de backup        
	echo "Limpando diretorio de backup ${BACKUPDIR}"
	rm -f ${BACKUPDIR}/*.gz

        # backup das bases de dados
	cd ${DATADIR}
	ls *.FDB *.GDB *.fdb *.gdb 2>/dev/null |while read DB; do	
                echo "Executando backup de ${DATADIR}/${DB}"
                /usr/bin/gbak -t -user ${USER} -password "${PASS}" ${HOST}:${DATADIR}/${DB} ${BACKUPDIR}/${DB} || exit 2
		echo "Compactando ${BACKUPDIR}/${DB}"
		gzip ${BACKUPDIR}/${DB}		
        done

        echo "Executando backup de ${FBHOME}/security2.fdb"
        /usr/bin/gbak -t -user ${USER} -password "${PASS}" -se ${HOST}:service_mgr ${FBHOME}/security2.fdb ${BACKUPDIR}/security2.fbk || exit 2
	echo "Compactando ${BACKUPDIR}/security2.fdb"
	gzip ${BACKUPDIR}/security2.fdb			
echo "FIM   $(date)"
} || {
        echo "${BACKUPDIR} não existe!"
        exit 2
}
echo "$(date) Fim Backup Firebird"
