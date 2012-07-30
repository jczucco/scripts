#!/bin/bash
#
# Backup Banco Postgres - Baseado em http://wiki.bacula.org/doku.php?id=application_specific_backups:postgresql
# by Zucco 05/08/2010

HOST=localhost
#PGHOME=/var/lib/pgsql
PGHOME="/usr"
PGCONF=/var/lib/pgsql/data
DUMPDIR=/storage/backup/postgresql
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
${PGHOME}/bin/pg_dumpall -U ${USER} -h ${HOST} -w -g >${DUMPDIR}/globalobjects.dump || exit 2
for dbname in `${PGHOME}/bin/psql -U postgres -h ${HOST} -w -d template1 -q -t <<EOF
select datname from pg_database where not datname in ('bacula','template0') order by datname;
EOF
`
do
 echo "Executando Backup do Database $dbname"
 ${PGHOME}/bin/pg_dump -U ${USER} -h ${HOST} -w -s $dbname > ${DUMPDIR}/$dbname.schema.dump || exit 2
 #${PGHOME}/bin/pg_dump -U ${USER} -h ${HOST} -w -a $dbname > ${DUMPDIR}/$dbname.data.dump
 ${PGHOME}/bin/pg_dump -U ${USER} -h ${HOST} -w $dbname > ${DUMPDIR}/$dbname.data.dump || exit 2
done


echo
echo "Compactando Base de Dados"
for ARQ in $(ls ${DUMPDIR}/*dump); do
        gzip ${ARQ} || exit 2
done

echo
echo "Fazendo backup da configuração"
tar cvfz ${DUMPDIR}/conf.tar.gz ${PGCONF}/*.conf ${PGCONF}/*.opts || exit 2

chmod 400 ${DUMPDIR}/* || exit 2
chown root.root ${DUMPDIR}/* || exit 2

echo "$(date) FIM Backup PostgreSQL"

}

