#################################################
# for basic

export OSNAME=`uname -a|awk '{print $1}'`
export HOSTNAME=`hostname`
export USERNAME=$LOGNAME
export PS1='[$USERNAME@$HOSTNAME $PWD] '

set -o vi

LC_ALL=en_US;export LC_ALL
LANG=en_US;export LANG

alias l='ls -l'
alias ll='ls -lF'
alias lf='ls -F'
alias lrt='ls -lrt'

alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

export PATH=$PATH:/usr/local/bin
export PATH=$PATH:$HOME/shbin:$HOME/bin:$HOME/exsh:$HOME/exbin

if [ x"$OSNAME" = x"Linux" ] ; then
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib:/usr/lib:/usr/local/lib:$HOME/exlib:$HOME/lib
elif [ x"$OSNAME" = x"AIX" ] ; then
	export LIBPATH=$LIBPATH:/usr/local/lib
	export LIBPATH=$LIBPATH:/lib:/usr/lib:/usr/local/lib:$HOME/exlib:$HOME/lib
	export OBJECT_MODE=64
fi

ulimit -c unlimited

#################################################
# for mktpl

export MKTPLDIR=$HOME/mktpl
export MKTPLOS=`uname -a | awk '{print $1}'`
export PATH=$PATH:$HOME/mktpl

################################################
# for svn
export SVN_EDITOR=vi

################################################
# for PostgreSQL
export DBTYPE=PGSQL
export DBHOST=localhost
export DBPORT=18432
export DBNAME=calvin
export DBUSER=calvin
export DBPASS=calvin

export PGHOME=/home/idd/dbdata
export PGDATA=$PGHOME
export PGHOST=$DBHOST
export PGPORT=$DBPORT
export PGDATABASE=$DBNAME

export PGPASSWORD=$DBPASS

export PATH=/root/local/postgresql/bin:$PATH

################################################
# for dc4c
export DC4C_RSERVERS_IP_PORT=0:12001

################################################
# for nmq
export NMQDATA=$HOME/nmqdata

################################################
# for VMQ
export VMQ_HOME=$HOME/vmq

