#!/bin/bash

################################################################################
# source common lib
################################################################################
source $DIRECTORY/lib/common_func_lib.sh

################################################################################
# function: mysql_json_insert_maker
################################################################################
function mysql_json_insert_maker ()
{
   typeset -r COLLECTION_NAME="$1"
   typeset -r NO_OF_ROWS="$2"
   typeset -r JSON_FILENAME="$3"

   process_log "preparing mysql INSERTs."
   rm -rf ${JSON_FILENAME}
   NO_OF_LOOPS=$((${NO_OF_ROWS}/11 + 1 ))
   for ((i=0;i<${NO_OF_LOOPS};i++))
   do
       json_seed_data $i | \
        sed "s/^/INSERT INTO ${COLLECTION_NAME} (${MYSQLFIELD}) VALUES('/"| \
        sed "s/$/');/" >>${JSON_FILENAME}
   done
}

################################################################################
# run_mysql_sql_file: send SQL from a file to database
################################################################################
function run_mysql_sql_file ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQLFILE="$6"

   ${MYSQL} -h ${F_MYSQLHOST} -u ${F_MYSQLUSER} \
                  ${F_MYSQLDBNAME} < ${F_SQLFILE} >/dev/null \
                  2>>/dev/null
}

################################################################################
# run_mysql_sql: send SQL to database
################################################################################
function run_mysql_sql ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQL="$6"

   ${MYSQL} -h ${F_MYSQLHOST} -u ${F_MYSQLUSER} \
                      ${F_MYSQLDBNAME} --execute="${F_SQL}"
}

################################################################################
# function: remove_mysql_db (remove mysql database)
################################################################################
function remove_mysql_db ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQL="DROP DATABASE IF EXISTS ${F_MYSQLDBNAME};"

   process_log "droping mysql database ${F_MYSQLDBNAME} if exists."
   ${MYSQL} -h ${F_MYSQLHOST} -u ${F_MYSQLUSER} \
                     --execute="${F_SQL}"
}

################################################################################
# function: create_mysql_db (create mysql database)
################################################################################
function create_mysql_db ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQL="CREATE DATABASE ${F_MYSQLDBNAME};"

   process_log "creating mysql database ${F_MYSQLDBNAME}."
   ${MYSQL} -h ${F_MYSQLHOST} -u ${F_MYSQLUSER} \
                     --execute="${F_SQL}"
}

################################################################################
# function: mysql_relation_size (calculate mysql relation size)
################################################################################
function mysql_relation_size ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_COLLECTION="$6"
   typeset -r F_SQL="SELECT (data_length + index_length) as json_table_size
                     FROM information_schema.TABLES 
                     WHERE table_schema = '${F_MYSQLDBNAME}'
                     AND table_name = '${F_COLLECTION}';"

   process_log "calculating mysql collection size."
   collectionsize=$(run_mysql_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL}" | tail -1)
   echo ${collectionsize}
}

################################################################################
# function: check if database exists
################################################################################
function if_mysql_dbexists ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQL="SELECT COUNT(1)
                     FROM information_schema.tables 
                     WHERE table_schema = '${F_MYSQLDBNAME}';"

   output=$(run_mysql_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
                    "${F_MYSQLPASSWORD}" \
                    "${F_SQL}")
   echo ${output}
}

################################################################################
# function: mk_mysql_json_collection create json table in MySQL
################################################################################
function mk_mysql_json_collection ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_TABLE="$6"
   typeset -r F_FIELD="$7"
   typeset -r F_SQL1="DROP TABLE IF EXISTS ${F_TABLE};"
   typeset -r F_SQL2="CREATE TABLE ${F_TABLE} 
                      (\`id\` int(11) unsigned NOT NULL AUTO_INCREMENT, 
                       \`${F_FIELD}\` text, 
                       PRIMARY KEY (\`id\`) 
                      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;"

  process_log "creating ${F_TABLE} table in mysql."
  run_mysql_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
          "${F_MYSQLPASSWORD}" "${F_SQL1}" 
  run_mysql_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
          "${F_MYSQLPASSWORD}" "${F_SQL2}"

}

################################################################################
# function: mysql_create_index create json table in PG
################################################################################
function mysql_create_index_collection ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_TABLE="$6"
   typeset -r F_FIELD="$7"
   typeset -r F_SQL="ALTER TABLE ${F_TABLE} ADD INDEX (${F_FIELD});"

   process_log "creating index on mysql table."
   run_mysql_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL}" \
            >/dev/null

}

################################################################################
# function: delete_mysql_json_data delete json data in mysql
################################################################################
function delete_mysql_json_data ()
{

   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_COLLECTION="$6"

   process_log "droping json data in mysql."
   run_mysql_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" \
           "TRUNCATE TABLE ${F_COLLECTION};" >/dev/null
}

################################################################################
# function: mysql_copy_benchmark
################################################################################
function mysql_copy_benchmark ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_COLLECTION="$6"
   typeset -r F_JSONFILE="$7"

   DBEXISTS=$(if_mysql_dbexists "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" \
                          "${F_MYSQLUSER}" "${F_MYSQLPASSWORD}")
   process_log "loading data in mysql using ${F_JSONFILE}."
   start_time=$(get_timestamp_nano)
   ${MYSQLIMPORT} -h ${F_MYSQLHOST} -u ${F_MYSQLUSER} \
                  ${F_MYSQLDBNAME} < ${F_JSONFILE} >/dev/null \
                  2>>/dev/null
   end_time=$(get_timestamp_nano)
   total_time="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   echo "${total_time}"

}


################################################################################
# function: benchmark mysql inserts
################################################################################
function mysql_inserts_benchmark ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_COLLECTION="$6"
   typeset -r F_INSERTS="$7"

   process_log "inserting data in mysql using ${F_INSERTS}."
   start_time=$(get_timestamp_nano)
   run_mysql_sql_file "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
                "${F_MYSQLPASSWORD}" "${F_INSERTS}"
   end_time=$(get_timestamp_nano)
   total_time="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   echo "${total_time}"
}

################################################################################
# function: benchmark mysql select
################################################################################
function mysql_select_benchmark ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_COLLECTION="$6"
   typeset -r F_FIELD="$7"
   typeset -r F_SELECT1="SELECT data
                         FROM ${F_COLLECTION}
                         WHERE ${F_FIELD} LIKE '%ACME%';"
   typeset -r F_SELECT2="SELECT data
                         FROM ${F_COLLECTION}
                           WHERE  ${F_FIELD} LIKE '%Phone Service Basic Plan%';"
   typeset -r F_SELECT3="SELECT data
                         FROM ${F_COLLECTION}
                          WHERE  ${F_FIELD} LIKE '%AC3 Case Red%';"
   typeset -r F_SELECT4="SELECT data
                          FROM ${F_COLLECTION}
                            WHERE  ${F_FIELD} LIKE '%service%';"
   local START end_time

   process_log "testing FIRST SELECT in mysql."
   start_time=$(get_timestamp_nano)
   run_mysql_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" \
           "${F_SELECT1}" >/dev/null || exit_on_error "failed to execute SELECT 1."
   end_time=$(get_timestamp_nano)
   total_time1="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   process_log "testing SECOND SELECT in mysql."
   start_time=$(get_timestamp_nano)
   run_mysql_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" \
           "${F_SELECT2}" >/dev/null || exit_on_error "failed to execute SELECT 2."
   end_time=$(get_timestamp_nano)
   total_time2="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   process_log "testing THIRD SELECT in mysql."
   start_time=$(get_timestamp_nano)
   run_mysql_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" \
           "${F_SELECT3}" >/dev/null || exit_on_error "failed to execute SELECT 3."
   end_time=$(get_timestamp_nano)
   total_time3="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   process_log "testing FOURTH SELECT in mysql."
   start_time=$(get_timestamp_nano)
   run_mysql_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_MYSQLDBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" \
           "${F_SELECT4}" >/dev/null || exit_on_error "failed to execute SELECT 4."
   end_time=$(get_timestamp_nano)
   total_time4="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   AVG=$(( ($total_time1 + $total_time2 + $total_time3 + $total_time4 )/4 ))

   echo "${AVG}"
}

################################################################################
# function: analyze_mysql_collections
################################################################################
function analyze_mysql_collections ()
{
   typeset -r F_PGHOST="$1"
   typeset -r F_PGPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_PGUSER="$4"
   typeset -r F_PGPASSWORD="$5"
   typeset -r F_TABLE="$6"
   typeset -r F_SQL="VACUUM FREEZE ANALYZE ${F_TABLE};"

   process_log "performing analyze in postgreSQL."
   run_mysql_sql "${F_PGHOST}" "${F_PGPORT}" "${F_DBNAME}" "${F_PGUSER}" \
           "${F_PGPASSWORD}" "${F_SQL}" \
            >/dev/null 2>/dev/null
}

################################################################################
# function: mysql_version
################################################################################
function mysql_version ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_MYSQLDBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQL="select VERSION();"

   version=$(${MYSQL} -h ${F_MYSQLHOST} -u ${F_MYSQLUSER} \
                     --execute="${F_SQL}" | tail -1)

    echo "${version}"
}
