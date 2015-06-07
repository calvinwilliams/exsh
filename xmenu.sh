VERSION=1.0.5

if [ $# -ne 1 ] ; then
	echo "xmenu v$VERSION"
	echo "copyright by calvin 2012"
	echo "USAGE : xmenu.sh menuconfig"
	echo "ChangeLog :"
	echo "v1.0.0   2012-02-07 calvin 创建"
	echo "v1.0.1   2012-02-11 calvin 支持配置文件前面加入自定义环境变量配置"
	echo "v1.0.2   2012-02-13 calvin 预读文件行到字符串数组中，避免每次选择后显示菜单"
	echo "                           都要读取配置文件，提高菜单选择反应速度"
	echo "v1.0.3   2012-02-14 calvin 增加环境变量 菜单穿透滚动选项"
	echo "v1.0.4   2012-02-23 calvin 支持Linux和AIX操作系统"
	echo "                           当菜单项数量大于屏幕行数时自动上下滚动"
	echo "v1.0.5   2012-02-28 calvin 支持自动根据终端大小，调整主界面"
	echo "                           解决滚动菜单时遗留字符"
	exit 7
fi

# 检查操作系统
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

# 设置键宏
if [ x"$OSNAME" = x"Linux" ] ; then
	ENTERKEY=`echo -e "\015"`
	ESCKEY=`echo -e "\033"`
elif [ x"$OSNAME" = x"AIX" ] ; then
	ENTERKEY=`echo "\015"`
	ESCKEY=`echo "\033"`
fi
UPARROWKEY='A'
DOWNARROWKEY='B'

# 设置缺省参数
XMENU_HEIGHT=`tput lines`
XMENU_WIDTH=`tput cols`

XMENU_TITLE=通用菜单控制台
XMENU_SEPCHAR=":"
XMENU_MENUBOX_TOP=3
XMENU_MENUBOX_LEFT=2
XMENU_MENUBOX_HEIGHT=`expr $XMENU_HEIGHT - 7`
XMENU_MENUBOX_WIDTH=0
XMENU_ARMREST=1
XMENU_PENETRATEROLL_MENU=0

# 立即获得按键扫描码函数
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

# 组织好横杠栏
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

# 显示主界面头
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

# 显示主界面脚
echo_foot()
{
	tput cup `expr $XMENU_HEIGHT - 3` 0
	echo $XMENU_SEPSTR
	
	tput cup `expr $XMENU_HEIGHT - 2` 0
	echo "q/Q:返回/退出 ↑↓:选择菜单项 ENTER:执行菜单项 r:刷新"
	tput cup `expr $XMENU_HEIGHT - 2` `expr $XMENU_WIDTH - 24`
	echo "copyright by calvin 2012"
}

# 设置终端模式为xmenu模式
xmenumode()
{
	stty -echo
if [ x"$OSNAME" = x"Linux" ] ; then
	echo -e "\033[?25l"
elif [ x"$OSNAME" = x"AIX" ] ; then
	echo "\033[?25l"
fi
}

# 设置终端模式为shell模式
shellmode()
{
	stty echo
if [ x"$OSNAME" = x"Linux" ] ; then
	echo -e "\033[?25h"
elif [ x"$OSNAME" = x"AIX" ] ; then
	echo "\033[?25h"
fi
}

# 读菜单配置文件
# 读自定义参数设置到环境变量，读菜单项配置到菜单项数组和命令数组
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
	echo "文件[$menu_configfile]不存在"
	exit 1
fi

create_strbar

xmenumode

clear
readfile $menu_configfile # echo_head和echo_foot在readfile函数里做掉了

# 菜单选择主循环
selidx=0 # 当前选定的菜单项在总列表中的索引
topidx=0 # 当前页显示首条菜单项在菜单项总列表中的索引
menuroll_flag=1 # 最近操作是否触发了菜单列表滚动
while [ 1 ] ; do
	# 显示菜单列表
	yy=0
	idx=$topidx
	while [ $yy -lt $XMENU_MENUBOX_HEIGHT ] ; do
		yy=`expr $yy + 1`
		
		# 计算当前菜单行坐标
		y=`expr $XMENU_MENUBOX_TOP - 1 + $yy`
		x=`expr $XMENU_MENUBOX_LEFT - $XMENU_ARMREST`
		
		# 如果菜单列表滚动了，先清除整行屏幕，为了清除遗留字符
		if [ $menuroll_flag -eq 1 ] ; then
			tput cup $y 0
			echo $XMENU_BLANKSTR
		fi
		
		# 显示菜单行
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
		
		# 屏幕索引自增一
		idx=`expr $idx + 1`
		if [ $idx -ge $textlines ] ; then
			break;
		fi
	done
	rows=$idx
	
	if [ $menuroll_flag -eq 1 ] ; then
		menuroll_flag=0
	fi
	
	# 定义光标在当前选定菜单行左边
	y=`expr 3 + $selidx`
	tput cup $y 9
	
	# 捕获键控
	IN=`getche`
	case $IN in
		'q')
			# 定位光标，设置shell终端模式，退出当前脚本
			tput cup `expr $XMENU_HEIGHT - 1` 0
			shellmode
			exit 0
			;;
		'Q')
			# 退出当前脚本，返回值99，告诉上层脚本是无停留继续往上层返回
			tput cup `expr $XMENU_HEIGHT - 1` 0
			shellmode
			exit 99
			;;
		$ESCKEY)
			# 马上继续捕获监控
			IN=`getche`
			IN=`getche`
			case $IN in
				$UPARROWKEY)
					# 按了向上光标键
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
					# 按了向下光标键
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
			# 执行当前选定菜单项对应的命令
			shellmode
			tput cup `expr $XMENU_HEIGHT - 1` 0
			sh -c "${cmd[$selidx]}"
			if [ $? -eq 99 ] ; then exit 99 ; fi
			cmd1=`echo ${cmd[$selidx]} | awk '{print $1}'`
			if [ x"$cmd1" != x"xmenu.sh" ] ; then
				printf "按任意键返回"
				getche
			fi
			
			clear
			xmenumode
			echo_head
			echo_foot
			
			;;
		'r')
			# 刷新屏幕
			clear
			echo_head
			echo_foot
			;;
		*)
			;;
	esac
done

