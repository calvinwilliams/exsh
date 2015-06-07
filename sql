# SQL Shell Tool
# copyright by calvin 2003,2010

if [ $# -eq 0 ] ; then
	echo "sql [.act] sql-statement"
	exit 7;
fi

infile=/tmp/sql.in.$$

> $infile

if [ $# -eq 2 ] ; then
	sed -e '/^end/,$d' $1 | sed "/^$/d" | awk '{printf "COLUMN %s HEADING %s\n",$1,$NF}' > $infile
	shift
fi

if [ x"$DBTYPE" = x"ORACLE" ] ; then
	echo "set pagesize 64" >> $infile
	echo "set linesize 2048" >> $infile
elif [ x"$DBTYPE" = x"PGSQL" ] ; then
	echo "set client_encoding to 'gb18030';" >> $infile
fi

echo "$1;" >> $infile

cat $infile | sqlpipe

rm $infile
