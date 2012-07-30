#!/bin/bash
MUSER=root
MPASS=xxxxxx
BACKUPDIR=/storage/backup/mysql

echo "$(date) Executando Backup MySQL"
[ -d ${BACKUPDIR} ] && {
        cd ${BACKUPDIR}
        find ${BACKUPDIR} -name *.gz -exec rm {} \;
        # verifica os bancos de dados
        mysql -u ${MUSER} -p${MPASS} -se "show databases"| grep -v "DATADIR.link" | while read DB; do
                echo "Executando backup de ${DB}"
                mkdir -p ${BACKUPDIR}/${DB}

                # separa cada tabela do banco de dados
                mysql -u ${MUSER} -p${MPASS} -se "show tables" ${DB}|while read TABLE;do
                        mysqldump -u ${MUSER} -p${MPASS} ${DB} ${TABLE}|gzip > ${BACKUPDIR}/${DB}/${TABLE}.sql.gz || exit 2
                done
        done
} || {
        echo "${BACKUPDIR} nao existe!"
        exit 2
}

echo "$(date) Fim Backup Mysql"
