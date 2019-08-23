#!/bin/sh
# Sleep for 30 seconds before running sqlcmd with inputfile setup.sql
# This SQL file will restore AdventureWorks2017 demo database at [AdventureWorks]
# along with a trigger to prevent demo user from changing their own password
# and sets some pretty restrictive permissions to sandbox the environment
# The delay before running sqlcmd in background is needed becasuse it is the only way to
# perform the necessary transact-SQL statements AFTER the sqlservr starts.

echo  "\n\n###### SETTING UP SQL SCRIPT ######\n"

echo :setvar TMP_DIR $TMP_DIR >> $TMP_DIR/setup.sql
echo :setvar MSSQL_PID $MSSQL_PID > $TMP_DIR/setup.sql
echo :setvar SA_PASSWORD $SA_PASSWORD > $TMP_DIR/setup.sql
echo :setvar SANDBOX_DB $SANDBOX_DB >> $TMP_DIR/setup.sql
echo :setvar SANDBOX_USERNAME $SANDBOX_USERNAME >> $TMP_DIR/setup.sql
echo :setvar SANDBOX_PASSWORD $SANDBOX_PASSWORD >> $TMP_DIR/setup.sql
echo :setvar SQL_DATA_DIR $SQL_DATA_DIR >> $TMP_DIR/setup.sql
echo :setvar DEMO_BACKUP_NAME $DEMO_BACKUP_NAME >> $TMP_DIR/setup.sql
echo :setvar DEMO_BACKUP_FILENAME $TMP_DIR/$DEMO_BACKUP_NAME\.bak >> $TMP_DIR/setup.sql
echo :setvar DEMO_BACKUP_NAME_MDF_PATH $SQL_DATA_DIR/$DEMO_BACKUP_NAME\.mdf >> $TMP_DIR/setup.sql
echo :setvar DEMO_BACKUP_NAME_LOG $DEMO_BACKUP_NAME\_log >> $TMP_DIR/setup.sql
echo :setvar DEMO_BACKUP_NAME_LOG_PATH $SQL_DATA_DIR/$DEMO_BACKUP_NAME\.ldf >> $TMP_DIR/setup.sql
cat /var/setup.sql >> $TMP_DIR/setup.sql

echo  "\n###### DONE SETTING UP SQL SCRIPT ######\n"

echo  "\n###### STARTING SQL SERVER ######\n"
MSSQL_PID=$MSSQL_PID /opt/mssql/bin/sqlservr --accept-eula 2>&1 &

sleep $DELAY_IN_SECONDS_BEFORE_SETUPSQL
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $SA_PASSWORD -i $TMP_DIR/setup.sql
if [ $? -ne 0 ]; then
    echo "\nThere was a problem executing the SQL script";
    exit 1;
fi
echo "\n###### DONE EXECUTING SQL SETUP ######\n"

# /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $SA_PASSWORD -i $TMP_DIR/setup.sql


