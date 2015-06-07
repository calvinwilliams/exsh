cd $HOME
ls | grep -v -E "(exinc|include|msg|print|log|test|tmp|$USER.tar.gz)" | xargs tar --exclude=.svn -h -cvzf $USER-bin.tar.gz .profile

