VERSION=1.0.5

if [ $# -ne 1 ] ; then
	echo "xmenu v$VERSION"
	echo "copyright by calvin 2012"
	echo "USAGE : xmenu.sh menuconfig"
	echo "ChangeLog :"
	echo "v1.0.0   2012-02-07 calvin ����"
	echo "v1.0.1   2012-02-11 calvin ֧�������ļ�ǰ������Զ��廷����������"
	echo "v1.0.2   2012-02-13 calvin Ԥ���ļ��е��ַ��������У�����ÿ��ѡ�����ʾ�˵�"
	echo "                           ��Ҫ��ȡ�����ļ�����߲˵�ѡ��Ӧ�ٶ�"
	echo "v1.0.3   2012-02-14 calvin ���ӻ������� �˵���͸����ѡ��"
	echo "v1.0.4   2012-02-23 calvin ֧��Linux��AIX����ϵͳ"
	echo "                           ���˵�������������Ļ����ʱ�Զ����¹���"
	echo "v1.0.5   2012-02-28 calvin ֧���Զ������ն˴�С������������"
	echo "                           ��������˵�ʱ�����ַ�"
	exit 7
fi

# ������ϵͳ
check_os()
{
	case `uname -s` in
		Linux)
			export OSNAME="Linux"
			;;
		AIX)
			export OSNAME="AIX"
			;;
		*)
			echo "os not support"
			exit 77
			;;
	esac
}
check_os

# ���ü���
if [ x"$OSNAME" = x"Linux" ] ; then
	ENTERKEY=`echo -e "\015"`
	ESCKEY=`echo -e "\033"`
elif [ x"$OSNAME" = x"AIX" ] ; then
	ENTERKEY=`echo "\015"`
	ESCKEY=`echo "\033"`
fi
UPARROWKEY='A'
DOWNARROWKEY='B'

# ����ȱʡ����
XMENU_HEIGHT=`tput lines`
XMENU_WIDTH=`tput cols`

XMENU_TITLE=ͨ�ò˵�����̨
XMENU_SEPCHAR=":"
XMENU_MENUBOX_TOP=3
XMENU_MENUBOX_LEFT=2
XMENU_MENUBOX_HEIGHT=`expr $XMENU_HEIGHT - 7`
XMENU_MENUBOX_WIDTH=0
XMENU_ARMREST=1
XMENU_PENETRATEROLL_MENU=0

# ������ð���ɨ���뺯��
getche()
{
	SAVEDSTTY=`stty -g`
	stty raw
	stty -echo
	dd if=/dev/tty bs=1 count=1 2>/dev/null
	stty -raw
	stty echo
	stty $SAVEDSTTY
}

# ��֯�ú����
create_strbar()
{
	XMENU_SEPSTR=""
	XMENU_BLANKSTR=""
	s=0
	while [ $s -lt $XMENU_WIDTH ] ; do
		XMENU_SEPSTR="$XMENU_SEPSTR-"
		XMENU_BLANKSTR="$XMENU_BLANKSTR "
		s=`expr $s + 1`
	done
}

# ��ʾ������ͷ
echo_head()
{
	tput cup 0 0
	echo "XMENU v$VERSION"
	len=`echo $XMENU_TITLE | wc -c`
	NEWCOL=`expr $XMENU_WIDTH / 2 - $len / 2`
	tput cup 0 $NEWCOL
	echo $XMENU_TITLE
	tput cup 0 `expr $XMENU_WIDTH - 10`
	/bin/date +"%Y-%m-%d"
	
	tput cup 1 0
	echo $XMENU_SEPSTR
}

# ��ʾ�������
echo_foot()
{
	tput cup `expr $XMENU_HEIGHT - 3` 0
	echo $XMENU_SEPSTR
	
	tput cup `expr $XMENU_HEIGHT - 2` 0
	echo "q/Q:����/�˳� ����:ѡ��˵��� ENTER:ִ�в˵��� r:ˢ��"
	tput cup `expr $XMENU_HEIGHT - 2` `expr $XMENU_WIDTH - 24`
	echo "copyright by calvin 2012"
}

# �����ն�ģʽΪxmenuģʽ
xmenumode()
{
	stty -echo
if [ x"$OSNAME" = x"Linux" ] ; then
	echo -e "\033[?25l"
elif [ x"$OSNAME" = x"AIX" ] ; then
	echo "\033[?25l"
fi
}

# �����ն�ģʽΪshellģʽ
shellmode()
{
	stty echo
if [ x"$OSNAME" = x"Linux" ] ; then
	echo -e "\033[?25h"
elif [ x"$OSNAME" = x"AIX" ] ; then
	echo "\033[?25h"
fi
}

# ���˵������ļ�
# ���Զ���������õ��������������˵������õ��˵����������������
readfile()
{
	idx=0
	config_head_flag=1
	while read L ; do
		echo $L | grep "^#" 2>/dev/null 1>&2
		if [ $? -eq 0 ] ; then
			continue
		fi
		
		if [ $config_head_flag -eq 1 ] ; then
			if [ x"$L" = x"" ] ; then
				config_head_flag=0
				echo_head
				continue
			else
				$L
				continue
			fi
		elif [ $config_head_flag -eq 0 ] ; then
			if [ x"$L" = x"" ] ; then
				continue
			fi
		fi
		
		text[$idx]=`echo $L | awk -F"$XMENU_SEPCHAR" '{ print $1 }'`

		cmd[$idx]=`echo $L | awk -F"$XMENU_SEPCHAR" '{ print $2 }'`
		
		idx=`expr $idx + 1`
	done < $1
	textlines=$idx
	
	echo_foot
}

menu_configfile=$1
if [ ! -f $menu_configfile ] ; then
	echo "�ļ�[$menu_configfile]������"
	exit 1
fi

create_strbar

xmenumode

clear
readfile $menu_configfile # echo_head��echo_foot��readfile������������

# �˵�ѡ����ѭ��
selidx=0 # ��ǰѡ���Ĳ˵��������б��е�����
topidx=0 # ��ǰҳ��ʾ�����˵����ڲ˵������б��е�����
menuroll_flag=1 # ��������Ƿ񴥷��˲˵��б����
while [ 1 ] ; do
	# ��ʾ�˵��б�
	yy=0
	idx=$topidx
	while [ $yy -lt $XMENU_MENUBOX_HEIGHT ] ; do
		yy=`expr $yy + 1`
		
		# ���㵱ǰ�˵�������
		y=`expr $XMENU_MENUBOX_TOP - 1 + $yy`
		x=`expr $XMENU_MENUBOX_LEFT - $XMENU_ARMREST`
		
		# ����˵��б�����ˣ������������Ļ��Ϊ����������ַ�
		if [ $menuroll_flag -eq 1 ] ; then
			tput cup $y 0
			echo $XMENU_BLANKSTR
		fi
		
		# ��ʾ�˵���
		tput cup $y $x
		if [ $selidx -eq $idx ] ; then tput rev ; fi
if [ x"$OSNAME" = x"Linux" ] ; then
		printf "%*s%*s%*s" $XMENU_ARMREST "" $XMENU_MENUBOX_WIDTH "${text[$idx]}" $XMENU_ARMREST ""
elif [ x"$OSNAME" = x"AIX" ] ; then
		s=0 ; while [ $s -lt $XMENU_ARMREST ] ; do printf " " ; s=`expr $s + 1` ; done
		printf "%s" ${text[$idx]}
		s=0 ; while [ $s -lt $XMENU_ARMREST ] ; do printf " " ; s=`expr $s + 1` ; done
fi
		if [ $selidx -eq $idx ] ; then tput sgr0 ; fi
		
		# ��Ļ��������һ
		idx=`expr $idx + 1`
		if [ $idx -ge $textlines ] ; then
			break;
		fi
	done
	rows=$idx
	
	if [ $menuroll_flag -eq 1 ] ; then
		menuroll_flag=0
	fi
	
	# �������ڵ�ǰѡ���˵������
	y=`expr 3 + $selidx`
	tput cup $y 9
	
	# �������
	IN=`getche`
	case $IN in
		'q')
			# ��λ��꣬����shell�ն�ģʽ���˳���ǰ�ű�
			tput cup `expr $XMENU_HEIGHT - 1` 0
			shellmode
			exit 0
			;;
		'Q')
			# �˳���ǰ�ű�������ֵ99�������ϲ�ű�����ͣ���������ϲ㷵��
			tput cup `expr $XMENU_HEIGHT - 1` 0
			shellmode
			exit 99
			;;
		$ESCKEY)
			# ���ϼ���������
			IN=`getche`
			IN=`getche`
			case $IN in
				$UPARROWKEY)
					# �������Ϲ���
					if [ $selidx -gt $topidx ] ; then
						selidx=`expr $selidx - 1`
					elif [ $selidx -gt 0 ] ; then
						topidx=`expr $topidx - 1`
						selidx=`expr $selidx - 1`
						menuroll_flag=1
					elif [ $XMENU_PENETRATEROLL_MENU -eq 1 ] ; then
						topidx=`expr $textlines - $rows`
						selidx=`expr $rows`
						menuroll_flag=1
					fi
					;;
				$DOWNARROWKEY)
					# �������¹���
					if [ $selidx -lt `expr $rows - 1` ] ; then
						selidx=`expr $selidx + 1`
					elif [ $selidx -lt `expr $textlines - 1` ] ; then
						topidx=`expr $topidx + 1`
						selidx=`expr $selidx + 1`
						menuroll_flag=1
					elif [ $XMENU_PENETRATEROLL_MENU -eq 1 ] ; then
						topidx=0
						selidx=0
						menuroll_flag=1
					fi
					;;
				*)
					;;
			esac
			;;
		$ENTERKEY)
			# ִ�е�ǰѡ���˵����Ӧ������
			shellmode
			tput cup `expr $XMENU_HEIGHT - 1` 0
			sh -c "${cmd[$selidx]}"
			if [ $? -eq 99 ] ; then exit 99 ; fi
			cmd1=`echo ${cmd[$selidx]} | awk '{print $1}'`
			if [ x"$cmd1" != x"xmenu.sh" ] ; then
				printf "�����������"
				getche
			fi
			
			clear
			xmenumode
			echo_head
			echo_foot
			
			;;
		'r')
			# ˢ����Ļ
			clear
			echo_head
			echo_foot
			;;
		*)
			;;
	esac
done

