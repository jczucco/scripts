#!/bin/bash
#
# Backup Banco Postgresql - Baseado em http://wiki.bacula.org/doku.php?id=application_specific_backups:postgresql
# by Zucco 05/08/2010

HOST="127.0.0.1"
PGPORT="5432"
PGHOME="/usr"
PGCONF="/etc/postgresql/14/main"
BACKUPDIR="/BACKUP"
DUMPDIR="${BACKUPDIR}/dump"
PGBASEBACKUP="${BACKUPDIR}/pg_basebackup"
PGARCHIVE="${BACKUPDIR}/archive"
USER="postgres"

# Criado arquivo ~/.pgpass no formato:
# hostname:port:database:username:password 
# ajustar permissão: chmod 0600 ~/.pgpass
#
# pode ser necessário trocar a senha do usuário postgres:
# # su - postgres
# $ psql
# postgres=# ALTER USER postgres PASSWORD 'XXXXXX';
# postgres=# \q
 

echo
echo "$(date) INICIO Backup PostgreSQL"
echo
[ -d ${BACKUPDIR} ] || {
        echo "${BACKUPDIR} não existe!"
        exit 2
} && {

rm -f ${DUMPDIR}/*.dump.gz || exit 2
rm -rf ${PGBASEBACKUP}/* || exit 2
#${PGHOME}/bin/pg_dumpall -U ${USER} -h ${HOST} -p ${PGPORT} -w -g >${DUMPDIR}/globalobjects.dump || exit 2
${PGHOME}/bin/pg_dumpall -U ${USER} -h ${HOST} -p ${PGPORT} -w -g | gzip >${DUMPDIR}/globalobjects.dump.gz
ESTADOCOMANDOS="${PIPESTATUS[@]}"
[ "$ESTADOCOMANDOS" = "0 0" ] || exit 2
for dbname in `${PGHOME}/bin/psql -U postgres -h ${HOST} -p ${PGPORT} -w -d template1 -q -t <<EOF
select datname from pg_database where not datname in ('bacula','template0') order by datname;
EOF
`
do
 echo "Executando Backup do Database $dbname"
 #${PGHOME}/bin/pg_dump -U ${USER} -h ${HOST} -p ${PGPORT} -w -s $dbname > ${DUMPDIR}/$dbname.schema.dump || exit 2
 ${PGHOME}/bin/pg_dump -U ${USER} -h ${HOST} -p ${PGPORT} -w -s $dbname | gzip > ${DUMPDIR}/$dbname.schema.dump.gz
 ESTADOCOMANDOS="${PIPESTATUS[@]}"
 [ "$ESTADOCOMANDOS" = "0 0" ] || exit 2
 #${PGHOME}/bin/pg_dump -U ${USER} -h ${HOST} -p ${PGPORT} -w $dbname > ${DUMPDIR}/$dbname.data.dump || exit 2
 ${PGHOME}/bin/pg_dump -U ${USER} -h ${HOST} -p ${PGPORT} -w $dbname | gzip > ${DUMPDIR}/$dbname.data.dump.gz
 ESTADOCOMANDOS="${PIPESTATUS[@]}"
 [ "$ESTADOCOMANDOS" = "0 0" ] || exit 2
done


#echo
#echo "Compactando Base de Dados"
#for ARQ in $(ls ${DUMPDIR}/*dump); do
#        gzip ${ARQ} || exit 2
#done


echo
echo "Fazenendo o backup via pg_basebackup"
${PGHOME}/bin/pg_basebackup -U ${USER} -h ${HOST} -p ${PGPORT} -D ${PGBASEBACKUP}/ -v -X stream || exit 2

echo
echo "Removendo os archives antigos"
LASTARCHIVE=`ls -t ${PGARCHIVE}/*.backup | head -n 1 |awk -F"/" '{print $NF}'`
${PGHOME}/bin/pg_archivecleanup -d ${PGARCHIVE} ${LASTARCHIVE} || exit 2

 
echo
echo "Fazendo backup da configuração"
tar cvfz ${DUMPDIR}/conf.tar.gz ${PGCONF}/ || exit 2

chmod 400 ${DUMPDIR}/* || exit 2
chown root.root ${DUMPDIR}/* || exit 2

echo 
echo "Executa vaccumdb na base de dados"
${PGHOME}/bin/vacuumdb -U ${USER} -h ${HOST} -p ${PGPORT} -z -v -a || exit 2

echo "$(date) FIM Backup PostgreSQL"

}