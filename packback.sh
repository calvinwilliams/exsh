cd $HOME
OS=`uname`
if [ -f ChangeLog ] ; then
	VERSION=`head -4 ChangeLog | tail -1 | awk '{print $1}'`
	TAR_FILENAME="${USER}-${OS}-${VERSION}-ful.tar.gz"
else
	TAR_FILENAME="${USER}-${OS}-ful.tar.gz"
fi
tar cvzf ${TAR_FILENAME} * .*profile .bashrc .viminfo --exclude=dbdata --exclude=hotmocha --exclude=.svn --exclude=.git --exclude=jdk --exclude=log --exclude=tmp --exclude=www/modules/shixin/download --exclude=expack --exclude=file

