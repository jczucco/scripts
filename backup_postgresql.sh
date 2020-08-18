#!/bin/bash
#
# Backup Banco Postgres - Baseado em http://wiki.bacula.org/doku.php?id=application_specific_backups:postgresql
#
# Testado em Debian/Ubuntu
#
# by Zucco 18/08/2020

HOST="127.0.0.1"
PGHOME="/usr"
PGCONF="/etc/postgresql/10/main"
BACKUPDIR="/BACKUP/postgresql"
DUMPDIR="${BACKUPDIR}/dump"
PGBASEBACKUP="${BACKUPDIR}/pg_basebackup"
PGARCHIVE="${BACKUPDIR}/archive"
USER="postgres"
# Criado arquivo ~/.pgpass no formato:
# hostname:port:database:username:password


echo
echo "$(date) INICIO Backup PostgreSQL"
echo
[ -d ${BACKUPDIR} ] || {
        echo "${BACKUPDIR} não existe!"
        exit 2
} && {

rm -f ${DUMPDIR}/*.dump.gz || exit 2
rm -f ${PGBASEBACKUP}/*.tar.gz || exit 2
${PGHOME}/bin/pg_dumpall -U ${USER} -h ${HOST} -w -g >${DUMPDIR}/globalobjects.dump || exit 2
for dbname in `${PGHOME}/bin/psql -U postgres -h ${HOST} -w -d template1 -q -t <<EOF
select datname from pg_database where not datname in ('bacula','template0') order by datname;
EOF
`
do
 echo "Executando Backup do Database $dbname"
 ${PGHOME}/bin/pg_dump -U ${USER} -h ${HOST} -w -s $dbname > ${DUMPDIR}/$dbname.schema.dump || exit 2
 ${PGHOME}/bin/pg_dump -U ${USER} -h ${HOST} -w $dbname > ${DUMPDIR}/$dbname.data.dump || exit 2
done


echo
echo "Compactando Base de Dados"
for ARQ in $(ls ${DUMPDIR}/*dump); do
        gzip ${ARQ} || exit 2
done


echo
echo "Fazendo o backup via pg_basebackup"
${PGHOME}/bin/pg_basebackup -U ${USER} -h ${HOST} -D ${PGBASEBACKUP}/ -F tar -z -Z 9 -v || exit 2

#echo
#echo "Removendo os archives antigos"
#LASTARCHIVE=`ls -t ${PGARCHIVE}/*.backup | head -n 1 |awk -F"/" '{print $NF}'`
#${PGHOME}/bin/pg_archivecleanup -d ${PGARCHIVE} ${LASTARCHIVE} || exit 2

echo
echo "Fazendo backup da configuração"
tar cvfz ${DUMPDIR}/conf.tar.gz ${PGCONF}/ || exit 2

chmod 400 ${DUMPDIR}/* || exit 2
chown root.root ${DUMPDIR}/* || exit 2

echo
#echo "Executa vaccumdb na base de dados"
#${PGHOME}/bin/vacuumdb -U ${USER} -h ${HOST} -z -v -a || exit 2

echo "$(date) FIM Backup PostgreSQL"
