#!/bin/bash
# **************************************************************************************
# *                                                                                    *
# *  Application VM installation script.                                               *
# *  Written by : Gerben Kranenborg                                                    *
# *  Date : August 14, 2017                                                            *
# *                                                                                    *
# **************************************************************************************

if [ "$1" = "silent" ]
then
	SILENT=true
else
	SILENT=false
fi

Init()
{
# **************************************************************************************
# *                                                                                    *
# * This function will initialize this script, by setting variables etc.               *
# *                                                                                    *
# **************************************************************************************
	VERSION="11.0"
	INSTALL_FILE_DIR=`pwd`
	if [ ! -d software ]
	then
		Screen_output 0 " The installation files cannot be found in the current directory. Please restart the installation in the correct directory !!"
		Abort_install
	else
		INSTALL_LOG_DIR="$INSTALL_FILE_DIR/logs"
		INSTALL_LOG_FILE="$INSTALL_LOG_DIR/install-log"
		ERROR="$INSTALL_LOG_DIR/install-error.log"
		SILENT_FILE="$INSTALL_FILE_DIR/app-install.silent"
		INIT_FILE="$INSTALL_LOG_DIR/init.config"
		export PGPASSWORD=Fujitsu1
		if [ ! -d $INSTALL_LOG_DIR ]
		then
			mkdir $INSTALL_LOG_DIR
			touch $ERROR
			date >> $INSTALL_LOG_FILE
		fi
	fi
	if [ -f $INIT_FILE ]
	then
		if grep "APPLICATION" $INIT_FILE >/dev/null 2>>$ERROR
		then
			APPLICATION=`grep APPLICATION $INIT_FILE | cut -f2 -d"="`
		fi
	else
		if [ -f software/I-BPM11.*-EnterpriseEdition-CD_IMAGE.zip ]
		then
			if [ -f software/flowable-6.1.2.zip ]
			then
				if [ "$SILENT" = "true" ]
				then
					if [ -f $SILENT_FILE ]
					then
						APPLICATION=`grep "APPLICATION:" $SILENT_FILE | cut -f2 -d":"`
						echo "APPLICATION=$APPLICATION" >>$INIT_FILE
					else
						Screen_output 0 " The file $SILENT_FILE cannot be found  !!"
						Abort_install
					fi
				else
					Screen_output 1 "Which application do you want to install, Interstage BPM or Flowable (IBPM / FLOWABLE) ? [IBPM] : "
					if [ "$INPUT" = "" -o "$INPUT" = "IBPM" ]
					then
						APPLICATION="IBPM"
						echo "APPLICATION=$APPLICATION" >>$INIT_FILE
					else
						APPLICATION="FLOWABLE"
						echo "APPLICATION=$APPLICATION" >>$INIT_FILE
					fi
				fi
			else
				APPLICATION="IBPM"
				echo "APPLICATION=$APPLICATION" >>$INIT_FILE
			fi
		else
			if [ -f software/flowable-6.1.2.zip ]
			then
				APPLICATION="FLOWABLE"
				echo "APPLICATION=$APPLICATION" >>$INIT_FILE
			else
				Screen_output 0 "The proper primary software installation files cannot be found !! "
				Abort_install
			fi
		fi
	fi
	if [ ! -f logs/welcome.log ]
	then
		if [ "$APPLICATION" = "IBPM" ]
		then
			BANNER="Interstage BPM / Alfresco"
		else
			BANNER="Flowable BPM"
		fi
		clear
		echo
		echo -e -n "The installation of \033[33;7m$BANNER\033[0m will be started. Is this correct (y/n) : [y] ? "
		read INPUT
		if [ "$INPUT" = "n" ]
		then
			if [ "$APPLICATION" = "IBPM" ]
			then
				APPLICATION="FLOWABLE"
				echo ""
				echo " Changing the application to Flowable BPM....."
				sed -i -e 's/APPLICATION:IBPM/APPLICATION:FLOWABLE/g' $SILENT_FILE
				sed -i -e 's/IBPM/FLOWABLE/g' $INIT_FILE
				sleep 3
			else
				APPLICATION="IBPM"
				echo ""
				echo " Changing the application to Interstage BPM ....."
				sed -i -e 's/APPLICATION:FLOWABLE/APPLICATION:IBPM/g' $SILENT_FILE
				sed -i -e 's/FLOWABLE/IBPM/g' $INIT_FILE
				sleep 3
			fi
		fi
	fi
}

Screen_output()
{
# **************************************************************************************
# *                                                                                    *
# * This function will post a remark or question to the user. If the first argument is *
# * a '0', it will be considered a remark, if it is a '1', it will be a question.      *
# * The second argument is the test for the remark / question. The variable $INPUT     *
# * will be returned in case of a question to the calling function.                    *
# *                                                                                    *
# **************************************************************************************
	if [ $1 = 0 ]
	then
		clear
		echo ""
		echo " *************************************************************************************************************************************"
	fi
	echo ""
	if [ $1 = 1 ]
	then
		echo -n " $2"
		read INPUT
	else
		echo " $2"
	fi
	if [ $1 = 0 ]
	then
		echo ""
		echo " *************************************************************************************************************************************"
		echo ""
	fi
}

Continue()
{
# **************************************************************************************
# *                                                                                    *
# * This function will ask the user if they want to continue running the installation  *
# * or abort.                                                                          *
# *                                                                                    *
# **************************************************************************************
	Screen_output 1 "Do you want to continue (y/n) ? [y] : "
	if [ "$INPUT" = "" -o "$INPUT" = "y" ]
	then
		return
	else
		Abort_install
	fi
}

Install_user_check()
{
# **************************************************************************************
# *                                                                                    *
# *  This function checks to make sure the root user is performing the installation.   *
# *                                                                                    *
# **************************************************************************************
	if [ $(id -u) != "0" ]
	then
		Screen_output 0 "You must run this installation script as user root. Please login again as user root and restart the installation !!"
		Abort_install
	fi
}

Welcome()
{
# **************************************************************************************
# *                                                                                    *
# *  This function shows the welcome screen at the (re)start of each installation.     *
# *                                                                                    *
# **************************************************************************************
	clear
	echo ""
	echo " Welcome to the Application VM installation script. (v.$VERSION)"
	echo ""
	echo " This script will configure the O.S. and install several other (optional) components"
	echo ""
	if [ "$SILENT" = "true" ]
	then
		echo " *********************************************************************************************"
		echo ""
		echo " This installation has been started as a SILENT installation."
		echo " The installation script will not prompt you for any input, until the end of the installation,"
		echo " or if an error occurs during the installation process."
		echo ""
		echo " WARNING : Shortly after the start of the installation, the VM / server will reboot."
		echo " Once this is done, log in again as root and go to $INSTALL_FILE_DIR and"
		echo " re-start the installation by typing   ./app-install.sh silent"
		echo ""
		echo " *********************************************************************************************"
		Continue
		if [ "$APPLICATION" = "IBPM" ]
		then
			BANNER="Interstage"
		else
			BANNER="Flowable"
		fi
		clear
		echo " *********************************************************************************************"
		echo ""
		echo -e " The installation of \033[33;7m$BANNER BPM\033[0m has been started."
		echo ""
		echo " *********************************************************************************************"
		echo ""
	fi
	if [ "$SILENT" = "false" ]
	then
		Screen_output 1 "Where do you want to install the BPM software ? [/opt] : "
		if [ "$INPUT" = "" -o "$INPUT" = "/opt" ]
		then
			INSTALL_DIR="/opt"
		else
			INSTALL_DIR=$INPUT
		fi
		if [ ! -d $INSTALL_DIR ]
		then
			mkdir -p $INSTALL_DIR >/dev/null
		fi
	fi
	echo "INSTALL_DIR=$INSTALL_DIR" >> $INIT_FILE
	echo "INSTALL_FILE_DIR=$INSTALL_FILE_DIR" >> $INIT_FILE
	touch $INSTALL_LOG_DIR/welcome.log
}

Check_install_files()
{
# **************************************************************************************
# *                                                                                    *
# * This function will check for the existance of all required installation files.     *
# * If any of them cannot be found, the installation will be aborted.                  *
# *                                                                                    *
# **************************************************************************************
	echo "*** Checking install files ***" >>$ERROR
	if [ -f $INSTALL_FILE_DIR/software/jdk-7u*-linux-x64.rpm ]
	then
		JDK7_INSTALL_FILE=`ls $INSTALL_FILE_DIR/software/jdk-7u*-linux-x64.rpm`
	else
		Missing_file JDK1.7
	fi
	if [ -f $INSTALL_FILE_DIR/options/posthoc.war ]
	then
		if [ -f $INSTALL_FILE_DIR/options/kMail.war ]
		then
			if [ "$SILENT" = "false" ]
			then
				Screen_output 1 "Which Mail client do you want to use, PostHoc or kMail (p/k) ? [p] : "
				if [ "$INPUT" = "" -o "$INPUT" = "p" ]
				then
					INSTALLMAIL="posthoc"
				else
					INSTALLMAIL="kmail"
				fi
			else
				if grep "INSTALLMAIL:" $SILENT_FILE >/dev/null 2>>$ERROR
				then
					INSTALLMAIL=`grep INSTALLMAIL: $SILENT_FILE|grep -v Specify|cut -f2 -d":"` >/dev/null 2>>$ERROR
				else
					Screen_output 0 "No default Mail client selection can be found in the silent file."
					Continue
				fi
			fi
		else
			INSTALLMAIL="posthoc"
		fi
	else
		if [ -f $INSTALL_FILE_DIR/options/kMail.war ]
		then
			INSTALLMAIL="kmail"
		else
			INSTALL_FILE="PostHoc or kMail"
			Missing_file
		fi
	fi
	if [ "$APPLICATION" = "IBPM" ]
	then
		KE_VERSION=`grep KEVERSION: $SILENT_FILE|cut -f2 -d":"`
		if [ "$KE_VERSION" = "latest" ]
		then
			KEVERSION="5.5.2"
		else
			KEVERSION="5.1.1"
		fi
	else
		KEVERSION="5.5.2"
	fi
	if [ -f $INSTALL_FILE_DIR/software/elasticsearch-$KEVERSION.rpm ]
	then
		ELASTICFILE=`ls $INSTALL_FILE_DIR/software/elasticsearch-$KEVERSION.rpm`
		ESVERSION=`ls $ELASTICFILE|cut -f2 -d"-"|cut -f1 -d"."`
		ELASTIC_VERSION=`basename $ELASTICFILE|cut -f2 -d"-"|cut -f1 -d"r"`
	else
		Missing_file ElasticSearch
	fi
	if [ -f $INSTALL_FILE_DIR/software/kibana-$KEVERSION-x86_64.rpm ]
	then
		KIBANAFILE=`ls $INSTALL_FILE_DIR/software/kibana-$KEVERSION-x86_64.rpm`
		KIBANAVERSION=`ls $KIBANAFILE|cut -f2 -d"-"|cut -f1 -d"."`
		KIBANA_VERSION=`basename $KIBANAFILE|cut -f2 -d"-"`
		if [ "$ESVERSION" -ge "5" ]
		then
			if [ ! "$KIBANAVERSION" -ge "5" ]
			then
				Screen_ouput 0 "The Elastic Search and Kibana installation file versions do not match !!"
				Continue
			else
				ESKBVERSION=5
				if [ -f $INSTALL_FILE_DIR/software/jdk-8u*-linux-x64.rpm ]
				then
					JDK8_INSTALL_FILE=`ls $INSTALL_FILE_DIR/software/jdk-8u*-linux-x64.rpm`
				else
					Missing_file JDK1.8
				fi
			fi
		else
			ESKBVERSION=2
		fi
	else
		Missing_file Kibana
	fi
	echo "E.S. and Kibana version : $ESKBVERSION" >>$INSTALL_LOG_FILE
	if [ -f $INSTALL_FILE_DIR/software/elasticsearch-head-master.zip ]
	then
		ESHEADFILE=`ls $INSTALL_FILE_DIR/software/elasticsearch-head-master.zip`
	else
		Missing_file ESHeadMaster
	fi
	if [ "$APPLICATION" = "IBPM" ]
	then
		if [ -f $INSTALL_FILE_DIR/software/oracle-xe-11.2*x86_64.rpm.zip ]
		then
			if [ -f $INSTALL_FILE_DIR/software/ppasmeta-9.5*linux-x64.tar* ]
			then
				if [ "$SILENT" = "false" ]
				then
					Screen_output 1 "Which database do you want to use, Oracle-XE or Postgres (o/p) ? [p] : "
					if [ "$INPUT" = "" -o "$INPUT" = "p" ]
					then
						INSTALLDB="postgresas"
					else
						INSTALLDB="oracle"
					fi
				else
					if grep "INSTALLDB:" $SILENT_FILE >/dev/null 2>>$ERROR
					then
						INSTALLDB=`grep INSTALLDB: $SILENT_FILE|grep -v Specify|cut -f2 -d":"` >/dev/null 2>>$ERROR
						if [ "$INSTALLDB" = "postgres" ]
						then
							INSTALLDB="postgresas"
						fi
					else
						Screen_output 0 "No default database selection can be found in the silent file."
						Continue
					fi
				fi
			else
				INSTALLDB="oracle"
			fi
		else
			if [ -f $INSTALL_FILE_DIR/software/ppasmeta-9.5*linux-x64.tar* ]
			then
				INSTALLDB="postgresas"
			else
				Missing_file DBFiles
			fi
		fi
		if [ -f $INSTALL_FILE_DIR/software/I-BPM11.3.?-EnterpriseEdition*zip ]
		then
			IBPMFILE=`ls $INSTALL_FILE_DIR/software/I-BPM11.3.?-EnterpriseEdition*zip`
			IBPMVERSION="3"
		else
			if [ -f $INSTALL_FILE_DIR/software/I-BPM11.4-EnterpriseEdition*zip ]
			then
				IBPMFILE=`ls $INSTALL_FILE_DIR/software/I-BPM11.4-EnterpriseEdition*zip`
				IBPMVERSION="4"
			else
				if [ -f $INSTALL_FILE_DIR/software/I-BPM11.4.1-EnterpriseEdition*zip ]
				then
					IBPMFILE=`ls $INSTALL_FILE_DIR/software/I-BPM11.4.1-EnterpriseEdition*zip`
					IBPMVERSION="4.1"
				else
					Missing_file IBPM
				fi
			fi
		fi
		case $IBPMVERSION in
		3)
			JBOSSVERSION="6.1.0"
		;;
		4)
			JBOSSVERSION="6.1.0"
		;;
		4.1)
			JBOSSVERSION="6.4"
		;;
		esac
		if [ -f $INSTALL_FILE_DIR/software/jboss-eap-$JBOSSVERSION.zip ]
		then
			JBOSS_FILE=`ls $INSTALL_FILE_DIR/software/jboss-eap-$JBOSSVERSION.zip`
		else
			Missing_file JBoss$JBOSSVERSION
		fi
		if [ "$JBOSSVERSION" = "6.1.0" ]
		then
			JBOSSVERSION="6.1"
		fi
		IBPM_VERSION=`basename $IBPMFILE|cut -f2 -d"-"|cut -f2 -d"M"`
		if [ -f $INSTALL_FILE_DIR/software/alfresco-community-install*bin ]
		then
			ALFRESCO_FILE=`ls $INSTALL_FILE_DIR/software/alfresco-community-install*bin`
		else
			Missing_file Alfresco
		fi
		if [ -f $INSTALL_FILE_DIR/alfresco.start ]
		then
			ALFRESCOSTART_FILE=`ls $INSTALL_FILE_DIR/alfresco.start`
		else
			Missing_file AlfrescoService
		fi
		if [ -f $INSTALL_FILE_DIR/jars/BPMActionLibrary.jar ]
		then
			BPMACTIONFILE=`ls $INSTALL_FILE_DIR/jars/BPMAction*jar`
		else
			Missing_file BAL.jar
		fi
		if [ -f $INSTALL_FILE_DIR/jars/mendo.jar ]
		then
			MENDOFILE=`ls $INSTALL_FILE_DIR/jars/mendo*jar`
		else
			Missing_file mendo.jar
		fi
		if [ -f $INSTALL_FILE_DIR/jars/twitter4j-core*.jar ]
		then
			TWITTERFILE=`ls $INSTALL_FILE_DIR/jars/twitter4j-core*jar`
		else
			Missing_file Twitter.jar
		fi
	else
		if [ -f $INSTALL_FILE_DIR/software/flowable-6.1.2.zip ]
		then
			FLOWABLE_FILE=`ls $INSTALL_FILE_DIR/software/flowable*zip`
		else
			Missing_file Flowable6.1
		fi
		if [ -f $INSTALL_FILE_DIR/software/postgresql96-9.6.3-1PGDG.rhel7.x86_64.rpm ]
		then
			INSTALLDB="postgres"
			POSTGRES_FILE=`ls $INSTALL_FILE_DIR/software/postgresql96-9.6.3-1PGDG.rhel7.x86_64.rpm`
		else
			Missing_file Postgres
		fi
		if [ -f $INSTALL_FILE_DIR/software/postgresql96-server-9.6.3-1PGDG.rhel7.x86_64.rpm ]
		then
			POSTGRES_SERVER_FILE=`ls $INSTALL_FILE_DIR/software/postgresql96-server-9.6.3-1PGDG.rhel7.x86_64.rpm`
		else
			Missing_file PostgresServer
		fi
		if [ -f $INSTALL_FILE_DIR/software/postgresql96-libs-9.6.3-1PGDG.rhel7.x86_64.rpm ]
		then
			POSTGRES_LIBS_FILE=`ls $INSTALL_FILE_DIR/software/postgresql96-libs-9.6.3-1PGDG.rhel7.x86_64.rpm`
		else
			Missing_file PostgresLibs
		fi
		if [ -f $INSTALL_FILE_DIR/jars/postgresql-42.1.3.jre7.jar ]
		then
			POSTGRES_DRIVER=`ls $INSTALL_FILE_DIR/jars/postgresql-42.1.3.jre7.jar`
		else
			Missing_file PostgresDriver
		fi
		if [ ! -f $INSTALL_FILE_DIR/logs/tomcat.log ]
		then
			if [ -f $INSTALL_FILE_DIR/software/apache-tomcat-*.tar.gz ]
			then
				TOMCAT_FILE=`ls $INSTALL_FILE_DIR/software/apache-tomcat-*.tar.gz`
			else
				Missing_file ApacheTomcat
			fi
		fi
	fi
	case "$INSTALLDB" in
		oracle)
			ORACLE_FILE=`ls $INSTALL_FILE_DIR/software/oracle-xe-11.2*x86_64.rpm.zip`
		;;
		postgresas)
			POSTGRES_FILE=`ls $INSTALL_FILE_DIR/software/ppasmeta-9.5*linux-x64.tar*`
			if [ -f $INSTALL_FILE_DIR/smtphost.sql ]
			then
				SMTPHOST_FILE=`ls $INSTALL_FILE_DIR/smtphost.sql`
			else
				Missing_file SMTPhost
			fi
		;;
	esac
}

Check_tools()
{
# **************************************************************************************
# *                                                                                    *
# *  This function will check to make sure the various tools required for the          *
# *  installation are available.                                                       *
# *                                                                                    *
# **************************************************************************************
	echo "*** Checking tools ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Checking to make sure the various tools required are installed .... "
	else
		echo -n " Checking and installing tools .... "
	fi
	if ! type unzip >/dev/null 2>&1
	then
		if [ "$SILENT" = "false" ]
		then
			Screen_output 0 "unzip needs to be installed. Starting yum .... "
		fi
		yum -y install unzip >/dev/null 2>&1
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "Unzip failed to get installed !!"
			Continue
		fi
	fi
	if ! type telnet >/dev/null 2>&1
	then
		if [ "$SILENT" = "false" ]
		then
			Screen_output 0 "telnet needs to be installed. Starting yum .... "
		fi
		yum -y install telnet >/dev/null 2>&1
		yum -y install telnet-server >/dev/null 2>&1
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "Telnet failed to get installed !!"
			Continue
		else
			if [ -f /etc/securetty ]
			then
				rm -rf /etc/securetty
			fi
			echo "#! /bin/bash" > /etc/rc.d/init.d/telnet
			echo "#" >> /etc/rc.d/init.d/telnet
			echo "# telnet	Start and Stop telnet" >> /etc/rc.d/init.d/telnet
			echo "#" >> /etc/rc.d/init.d/telnet
			echo "# chkconfig: 3 85 04" >> /etc/rc.d/init.d/telnet
			echo "#" >> /etc/rc.d/init.d/telnet
			echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" >> /etc/rc.d/init.d/telnet
			echo "case \"\$1\" in" >> /etc/rc.d/init.d/telnet
			echo "start)" >> /etc/rc.d/init.d/telnet
			echo "	systemctl enable telnet.socket" >> /etc/rc.d/init.d/telnet
			echo "	systemctl start telnet.socket" >> /etc/rc.d/init.d/telnet
			echo ";;" >> /etc/rc.d/init.d/telnet
			echo "esac" >> /etc/rc.d/init.d/telnet
			chmod 755 /etc/rc.d/init.d/telnet 2>>$ERROR
			chkconfig --add telnet 2>>$ERROR
			chkconfig --level 3 telnet on 2>>$ERROR
		fi
	fi
	if [ "$INSTALLDB" = "oracle" ]
	then
		if ! type bc >/dev/null 2>&1
		then
			if [ "$SILENT" = "false" ]
			then
				Screen_output 0 "bc needs to be installed. Starting yum .... "
			fi
			yum -y install bc >/dev/null 2>&1
			ret=$?
			if [ $ret -ne 0 ]
			then
				Screen_output 0 "bc failed to get installed !!"
				Continue
			fi
		fi
	fi
	if ! type netstat >/dev/null 2>&1
	then
		if [ "$SILENT" = "false" ]
		then
			Screen_output 0 "netstat needs to be installed. Starting yum .... "
		fi
		yum -y install net-tools >/dev/null 2>&1
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "net-tools failed to get installed !!"
			Continue
		fi
	fi
	if ! type httpd >/dev/null 2>&1
	then
		if [ "$SILENT" = "false" ]
		then
			Screen_output 0 "httpd needs to be installed. Starting yum .... "
		fi
		yum -y install httpd >/dev/null 2>&1
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "httpd failed to get installed !!"
			Continue
		fi
	fi
	if ! type git >/dev/null 2>&1
	then
		if [ "$SILENT" = "false" ]
		then
			Screen_output 0 "git needs to be installed. Starting yum .... "
		fi
		yum -y install git >/dev/null 2>&1
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "git failed to get installed !!"
			Continue
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/vmwaretools.log ]
	then
		if [ "$SILENT" = "false" ]
		then
			Screen_output 0 "VMWare tools needs to be installed. Starting yum ...."
		fi
		yum -y install open-vm-tools >/dev/null 2>&1
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "VMWare tools failed to get installed !!"
			Continue
		else
			/usr/bin/vmware-toolbox-cmd timesync enable >/dev/null 2>&1
			touch $INSTALL_LOG_DIR/vmwaretools.log
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/yumupdate.log ]
	then
		if [ "$SILENT" = "false" ]
		then
			Screen_output 0 "CentOS 7 needs to be updated. Starting yum ...."
		fi
		yum -y update >/dev/null 2>&1
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "CentOS 7 failed to update !!"
			Continue
		else
			touch $INSTALL_LOG_DIR/yumupdate.log
		fi
		if [ "$SILENT" = "false" ]
		then
			Continue
		else
			echo "Done."
		fi
	fi
}

Change_os_settings()
{
# **************************************************************************************
# *                                                                                    *
# * This function makes the required changes to the OS settings, such as network,      *
# * firewall, SElinux etc. changes.
# *                                                                                    *
# **************************************************************************************
	echo "*** Changing OS settings ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Changing O.S. settings ...."
	else
		echo -n " Changing O.S. settings .... "
	fi
	if [ ! -f $INSTALL_LOG_DIR/colorchange.log ]
	then
		sed -i -e 's/COLOR tty/COLOR none/g' /etc/DIR_COLORS 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The modification of the file /etc/DIR_COLORS failed."
			echo " Errorcode : $ret"
			echo "The modification of /etc/DIR_COLORS failed" >> $INSTALL_LOG_FILE
			Continue
		else
			touch $INSTALL_LOG_DIR/colorchange.log
			echo "The modification of /etc/DIR_COLORS completed" >> $INSTALL_LOG_FILE
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/rootchange.log ]
	then
		sed -i -e 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The modification of the file /etc/ssh/sshd_config failed."
			echo " Errorcode : $ret"
			echo "The modification of /etc/ssh/sshd_config failed" >> $INSTALL_LOG_FILE
			Continue
		else
			touch $INSTALL_LOG_DIR/rootchange.log
			echo "The modification of /etc/ssh/sshd_config completed" >> $INSTALL_LOG_FILE
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/selinuxchange.log ]
	then
		sed -i -e 's/\=enforcing/\=disabled/g' /etc/sysconfig/selinux 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The modification of the file /etc/sysconfig/selinux failed."
			echo " Errorcode : $ret"
			echo "The modification of /etc/sysconfig/selinux failed" >> $INSTALL_LOG_FILE
			Continue
		else
			touch $INSTALL_LOG_DIR/selinuxchange.log
			echo "The modification of /etc/sysconfig/selinux completed" >> $INSTALL_LOG_FILE
		fi
	fi
	if systemctl | grep firewalld >/dev/null
	then
		if [ ! -f $INSTALL_LOG_DIR/firewallchange.log ]
		then
			systemctl stop firewalld >/dev/null 2>>$ERROR
			ret=$?
			if [ $ret -ne 0 ]
			then
				Screen_output 0 "The firewall could not be stopped. This can lead to failures and access issues later on."
				echo " Errorcode : $ret"
				echo "The firewall could not be stopped" >> $INSTALL_LOG_FILE
				Continue
			else
				echo "The firewall was stopped" >> $INSTALL_LOG_FILE
			fi
			systemctl disable firewalld >/dev/null 2>>$ERROR
			ret=$?
			if [ $ret -ne 0 ]
			then
				Screen_output 0 "The firewall could not be disabled. This can lead to failures and access issues later on."
				echo " Errorcode : $ret"
				echo "The firewall could not be disabled" >> $INSTALL_LOG_FILE
				Continue
			else
				echo "The firewall was disabled" >> $INSTALL_LOG_FILE
				touch $INSTALL_LOG_DIR/firewallchange.log
			fi
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/networkchange.log ]
	then
		if [ "$SILENT" = "false" ]
		then
			Screen_output 1 "Do you want to change the server's hostname (y/n) ? [y] : "
			if [ "$INPUT" = "" -o "$INPUT" = "y" ]
			then
				if [ "$APPLICATION" = "IBPM" ]
				then
					TEMPHOSTNAME="interstagedemo"
				else
					TEMPHOSTNAME="flowabledemo"
				fi
				Screen_output 1 "What would you like the new hostname to be ? [$TEMPHOSTNAME] : "
				if [ "$INPUT" = "" -o "$INPUT" = "$TEMPHOSTNAME" ]
				then
					NEWHOSTNAME="$TEMPHOSTNAME"
				else
					NEWHOSTNAME=$INPUT
				fi
			fi
		else
			if [ "$APPLICATION" = "IBPM" ]
			then
				NEWHOSTNAME=`grep "IBPMHOSTNAME:" $SILENT_FILE | cut -f2 -d":"`
			else
				NEWHOSTNAME=`grep "FLOWABLEHOSTNAME:" $SILENT_FILE | cut -f2 -d":"`
			fi
		fi
		hostnamectl set-hostname $NEWHOSTNAME> /dev/null 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The VM's hostname could not be changed to $NEWHOSTNAME"
			echo " Errorcode : $ret"
			echo "Hostname change failure" >> $INSTALL_LOG_FILE
			Abort_install
		else
			echo "The hostname has been changed" >> $INSTALL_LOG_FILE
		fi
		HOSTENTRY=`grep $NEWHOSTNAME /etc/hosts`
		if [ "$HOSTENTRY" = "" ]
		then
			IPADDRESS=`ip addr | grep "inet" | grep -ve "127.0.0.1" | grep -ve "inet6" | awk '{print $2}' | cut -f1 -d"/"`
			echo "$IPADDRESS	$NEWHOSTNAME" >> /etc/hosts 2>>$ERROR
		fi
		if [ ! -d $INSTALL_DIR/utilities ]
		then
			mkdir $INSTALL_DIR/utilities 2>>$ERROR
		fi
		echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
		echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
		if [ -f /etc/sysconfig/network-scripts/ifcfg-eno* ]
		then
			NETWORKFILE=`ls /etc/sysconfig/network-scripts/ifcfg-eno*`
		else
			NETWORKFILE=`ls /etc/sysconfig/network-scripts/ifcfg-ens*`
		fi
		sed -i -e 's/IPV6INIT="yes"/IPV6INIT="no"/g' $NETWORKFILE 2>>$ERROR 
		systemctl restart network >/dev/null 2>>$ERROR
		echo "Network change completed" >> $INSTALL_LOG_FILE
		touch $INSTALL_LOG_DIR/networkchange.log
	fi
	if [ -f /usr/lib/systemd/system/poweroff.target ]
	then
		sed -i -e "s/30min/1min/g" /usr/lib/systemd/system/poweroff.target
	fi
		if [ -f /usr/lib/systemd/system/reboot.target ]
	then
		sed -i -e "s/30min/1min/g" /usr/lib/systemd/system/reboot.target
	fi
	touch $INSTALL_LOG_DIR/oschange.log
	if [ "$SILENT" = "false" ]
	then
		Continue
	else
		echo "Done."
	fi
}

Install_scripts()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install the Welcome screen and the ipchange script.             *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Service scripts ***" >>$ERROR
		if [ "$SILENT" = "false" ]
		then
			Screen_output 0 "Installing the VM welcome screen and the ipchange script .... "
		else
			echo -n " Installing the VM welcome screen .... "
		fi
		echo "#!/bin/sh" > /etc/rc.d/init.d/ipchange
		echo "#" >> /etc/rc.d/init.d/ipchange
		echo "# chkconfig: 3 70 05" >> /etc/rc.d/init.d/ipchange
		echo "#" >> /etc/rc.d/init.d/ipchange
		echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" >> /etc/rc.d/init.d/ipchange
		echo "NEWVMIP=\`ip addr | grep \"inet\" | grep -ve \"127.0.0.1\" | grep -ve \"inet6\" | awk '{print \$2}' | cut -f1 -d\"/\"\`" >> /etc/rc.d/init.d/ipchange
		echo "HOSTNAME=\`hostname\`" >> /etc/rc.d/init.d/ipchange
		echo "OLDVMIP=\`grep \$HOSTNAME /etc/hosts | cut -f1 -d'	'\`" >> /etc/rc.d/init.d/ipchange
		echo "sed -i -e \"s/\$HOSTNAME//g\" /etc/hosts 2>/dev/null" >> /etc/rc.d/init.d/ipchange
		echo "sed -i -e \"s/\$NEWVMIP//g\" /etc/hosts 2>/dev/null" >> /etc/rc.d/init.d/ipchange
		echo "sed -i -e \"s/\$OLDVMIP//g\" /etc/hosts 2>/dev/null" >> /etc/rc.d/init.d/ipchange
		echo "sed -i '/^\s*$/d' /etc/hosts 2>/dev/null" >> /etc/rc.d/init.d/ipchange
		echo "echo \"\$NEWVMIP	\$HOSTNAME\" >> /etc/hosts" >> /etc/rc.d/init.d/ipchange
		chmod 755 /etc/rc.d/init.d/ipchange 2>>$ERROR
		chkconfig --add ipchange 2>>$ERROR
		chkconfig --level 3 ipchange on 2>>$ERROR
		if [ "$APPLICATION" = "IBPM" ]
		then
			if [ "$IBPMVERSION" = "3" ]
			then
				IBPMNUMBER="3.0"
				else
				if [ "$IBPMVERSION" = "4" ]
				then
					IBPMNUMBER="4.0"
				else
					IBPMNUMBER=$IBPMVERSION
				fi
			fi
			APPNAME="Interstage BPM11.${IBPMNUMBER}"
		else
			APPNAME=" Flowable BPM 6.1.2 "
		fi
		echo "#!/bin/bash" > /etc/rc.d/rc.local
		echo "echo \" \"  > /etc/issue" >> /etc/rc.d/rc.local
		echo "" >> /etc/rc.d/rc.local
		echo "VMURL=\`ip addr | grep \"inet\" | grep -ve \"127.0.0.1\" | grep -ve \"inet6\" | awk '{print \$2}' | cut -f1 -d\"/\"\`" >> /etc/rc.d/rc.local
		echo "DUMMY=\"                         \"" >> /etc/rc.d/rc.local
		echo "HOSTNAME=\`hostname\`" >> /etc/rc.d/rc.local
		echo "" >> /etc/rc.d/rc.local
		echo "echo    \" ****************************************************************************** \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \" |                                                                            | \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \" |                        Fujitsu ${APPNAME} demo VM                | \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \" |                                                                            | \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo -n \" |                         Hostname : \"                                       >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \"\${HOSTNAME}\${DUMMY:0:\`expr 31 - \${#HOSTNAME}\`}         | \"                         >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo -n \" |                       IP address : \"                                       >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \"\${VMURL}\${DUMMY:0:\`expr 31 - \${#VMURL}\`}         | \"                                    >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \" |                                                                            | \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \" |                          LoginID : root                                    | \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \" |                         Password : Fujitsu1                                | \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \" |----------------------------------------------------------------------------| \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \" |                                                                            | \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo -n \" |                              URL : \"                                       >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \"http://\${HOSTNAME}\${DUMMY:0:\`expr 31 - \${#HOSTNAME}\`}  | \"                             >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \" |                                                                            | \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \" ****************************************************************************** \"      >> /etc/issue" >> /etc/rc.d/rc.local
		echo "echo    \"\"                                                                                      >> /etc/issue" >> /etc/rc.d/rc.local
		chmod 755 /etc/rc.d/rc.local 2>>$ERROR
		systemctl enable rc-local.service 2>>$ERROR
		> /etc/issue 2>>$ERROR
		touch $INSTALL_LOG_DIR/scriptinstall.log
		/etc/rc.d/init.d/ipchange >/dev/null 2>>$ERROR
		if [ "$SILENT" = "true" ]
		then
			echo "Done."
		fi
}

Reset_rootpw()
{
# **************************************************************************************
# *                                                                                    *
# * This function will reset the root password to the default.                         *
# *                                                                                    *
# **************************************************************************************
	echo "*** Changing root password ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 1 " Do you want to reset the root password to the default value ? (y/n) [y] : "
		if [ "$INPUT" = "" -o "$INPUT" = "y" ]
		then
			passwd root <<RESETPW >/dev/null 2>&1
Fujitsu1
Fujitsu1
RESETPW
		fi
	else
		RESETROOTPW=`grep "RESETROOTPW:" $SILENT_FILE | cut -f2 -d":"` 
		if [ "$RESETROOTPW" = "yes" ]
		then
			passwd root <<RESETPW >/dev/null 2>&1
Fujitsu1
Fujitsu1
RESETPW
		fi
	fi
	touch $INSTALL_LOG_DIR/rootpwreset.log
}

Install_jdk()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install JDK in the default directory.                           *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing JDK ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 " JDK 1.$1 will be installed .... "
	else
		echo -n " Installing JDK1.$1 .... "
	fi
	if [ "$1" = "7" ]
	then
		JDK_INSTALL_FILE="$JDK7_INSTALL_FILE"
		JDK7VERSION=`basename $JDK_INSTALL_FILE|cut -f2 -d"-"`
	else
		JDK_INSTALL_FILE="$JDK8_INSTALL_FILE"
		JDK8VERSION=`basename $JDK_INSTALL_FILE|cut -f2 -d"-"`
	fi
	rpm -i $JDK_INSTALL_FILE >/dev/null 2>>$ERROR
	ret=$?
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "The installation of JDK1.$1 failed."
		echo ""
		echo " Errorcode : $ret"
		echo "The installation of JDK1.$1 failed" >> $INSTALL_LOG_FILE
		Abort_install
	else
		touch $INSTALL_LOG_DIR/jdk$1installed.log
		if [ "$SILENT" = "false" ]
		then
			java -version
			Continue
		else
			echo "Done."
		fi
		echo "The installation of JDK1.$1 is complete" >> $INSTALL_LOG_FILE
	fi
}

Install_oracle()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install and configure Oracle XE.                                *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Oracle ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Oracle XE will be installed next."
	else
		echo -n " Installing and configuring Oracle XE .... "
	fi
	if [ ! -f $INSTALL_LOG_DIR/oraclezip.log ]
	then
		unzip  -o $ORACLE_FILE >/dev/null 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The Oracle installation file failed to unzip !!"
			echo " Errorcode : $ret"
			echo ""
			Abort_install
		else
			>$INSTALL_LOG_DIR/oraclezip.log
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/oracledbinst.log ]
	then
		rpm -i $INSTALL_FILE_DIR/Disk1/oracle-xe*64.rpm >/dev/null 2>&1
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "Oracle failed to install completely !!"
			echo " Errorcode : $ret"
			echo ""
			Abort_install
		else
			>$INSTALL_LOG_DIR/oracledbinst.log
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/oracleconfigured.log ]
	then
		if [ "$SILENT" = "false" ]
		then
			Continue
			clear
			echo ""
			echo -n " Specify the HTTP port that will be used for Oracle Application Express [8080] :"
			read ORACLEHTTP
			if [ "$ORACLEHTTP" = "" -o "$ORACLEHTTP" = "8080" ]
			then
				ORACLEHTTP="8080"
			fi
			echo ""
			echo -n " Specify a port that will be used for the database listener [1521]:"
			read ORACLELIST
			if [ "$ORACLELIST" = "" -o "$ORACLELIST" = "1521" ]
			then
				ORACLELIST="1521"
			fi
			ORACLEPW1=""
			ORACLEPW2=" "
			while [ "$ORACLEPW1" != "$ORACLEPW2" ]
			do
				echo ""
				echo " Specify a password to be used for the database accounts. Note that the same"
				echo " password will be used for SYS and SYSTEM. Oracle recommends the use of"
				echo " different passwords for each database account. This can be done after"
				echo -n " initial configuration:"
				read -s ORACLEPW1
				echo ""
				echo -n " Confirm the password:"
				read -s ORACLEPW2
				if [ "$ORACLEPW1" != "$ORACLEPW2" ]
				then
					echo ""
					echo " The passwords do not match. Please try again."
					echo ""
				fi
			done
			ORACLEPWD="$ORACLEPW1"
			echo ""
			echo ""
			echo -n " Do you want Oracle Database 11g Express Edition to be started on boot (y/n) [y]:"
			read ORACLESTART
			if [ "$ORACLESTART" = "" -o "$ORACLESTART" = "y" ]
			then
				ORACLESTART="y"
			else
				ORACLESTART="n"
			fi
		else
			ORACLEHTTP=`grep "ORACLEHTTP:" $SILENT_FILE | cut -f2 -d":"` 
			ORACLELIST=`grep "ORACLELIST:" $SILENT_FILE | cut -f2 -d":"` 
			ORACLEPWD=`grep "ORACLEPWD:" $SILENT_FILE | cut -f2 -d":"` 
			ORACLESTART=`grep "ORACLESTART:" $SILENT_FILE | cut -f2 -d":"` 
		fi
		/etc/init.d/oracle-xe configure << ORACCONF >/dev/null 2>&1
$ORACLEHTTP
$ORACLELIST
$ORACLEPWD
$ORACLEPWD
$ORACLESTART
ORACCONF
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The Oracle DB configuration failed to complete !!"
			echo " Errorcode : $ret"
			echo ""
			Abort_install
		else
			>$INSTALL_LOG_DIR/oracleconfigured.log
		fi
	fi
	echo ". /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh" >> /root/.bashrc 2>>$ERROR
	touch $INSTALL_LOG_DIR/oracleinstalled.log
	if [ "$SILENT" = "false" ]
	then
		Continue
	else
		echo "Done."
	fi
}

Install_postgresas()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install and initialize Postgres.                                *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Postgres AS***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Postgres will be installed next."
	else
		echo -n " Installing and configuring Postgres .... "
	fi
	gunzip $POSTGRES_FILE >/dev/null 2>>$ERROR
	tar xvf $INSTALL_FILE_DIR/software/ppasmeta-9.5*tar -C $INSTALL_FILE_DIR>/dev/null 2>>$ERROR
	$INSTALL_FILE_DIR/ppasmeta*x64/ppas*run <<ENDPOSTGRES >/dev/null 2>>$ERROR
1












y
gerben7164@hotmail.com
Kawasaki7
$INSTALL_DIR/edb
y
y
y
n
y
n
n
y
n
n
y
$INSTALL_DIR/edb/9.5AS/data
$INSTALL_DIR/edb/9.5AS/data/pg_xlog
1
Fujitsu1
Fujitsu1
5444
1
n
2
1
y
y

y
ENDPOSTGRES
	ret=$?
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "The Postgres installation failed to complete !!"
		echo " Errorcode : $ret"
		echo ""
		Abort_install
	else
		source $INSTALL_DIR/edb/9.5AS/pgplus_env.sh >/dev/null 2>>$ERROR
		sed -i -e 's/#work_mem = 4MB/work_mem = 20MB/g' $INSTALL_DIR/edb/9.5AS/data/postgresql.conf 2>>$ERROR
		chmod 755 $INSTALL_DIR/edb/connectors/jdbc/*jar >/dev/null 2>>$ERROR
		POSTGRESJAR=`ls $INSTALL_DIR/edb/connectors/jdbc/edb-*17.jar`
		sed -i -e "s/127\.0\.0\.1\/32/0\.0\.0\.0\/0/g" $INSTALL_DIR/edb/9.5AS/data/pg_hba.conf
		echo "export PGDATA=$INSTALL_DIR/edb/9.5AS/data" >>/root/.bashrc
		su enterprisedb -c "$INSTALL_DIR/edb/9.5AS/bin/pg_ctl restart" >/dev/null 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The Postgres DB server failed to start !!"
			echo " Errorcode : $ret"
			echo ""
			Abort_install
		else
			sleep 20
			touch $INSTALL_LOG_DIR/postgresasinstalled.log
			echo "Done."
		fi
	fi
}

Install_postgres()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install and initialize Postgres.                                *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Postgres ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Postgres will be installed next."
	else
		echo -n " Installing and configuring Postgres .... "
	fi
	rpm -i $POSTGRES_LIBS_FILE>/dev/null 2>>$ERROR
	ret=$?
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "The Postgres Libs installation failed to complete !!"
		echo " Errorcode : $ret"
		echo ""
		Abort_install
	else
		rpm -i $POSTGRES_FILE>/dev/null 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The Postgres installation failed to complete !!"
			echo " Errorcode : $ret"
			echo ""
			Abort_install
		else
			mkdir -p $INSTALL_DIR/postgres/data >/dev/null 2>>$ERROR
			rpm -i $POSTGRES_SERVER_FILE>/dev/null 2>>$ERROR
			ret=$?
			if [ $ret -ne 0 ]
			then
				Screen_output 0 "The Postgres Server installation failed to complete !!"
				echo " Errorcode : $ret"
				echo ""
				Abort_install
			else
				chown postgres:postgres $INSTALL_DIR/postgres/data >/dev/null 2>>$ERROR
				su postgres -c '/usr/pgsql-9.6/bin/initdb -D /opt/postgres/data' >/dev/null 2>>$ERROR
				sed -i -e "s/127\.0\.0\.1\/32/0\.0\.0\.0\/0/g" $INSTALL_DIR/postgres/data/pg_hba.conf
				echo "#!/bin/sh" > /etc/rc.d/init.d/postgres
				echo "#" >> /etc/rc.d/init.d/postgres
				echo "# chkconfig: 3 70 05" >> /etc/rc.d/init.d/postgres
				echo "#" >> /etc/rc.d/init.d/postgres
				echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" >> /etc/rc.d/init.d/postgres
				echo "case \"\$1\" in" >> /etc/rc.d/init.d/postgres
				echo "start)" >> /etc/rc.d/init.d/postgres
				echo "	su postgres -c '/usr/pgsql*/bin/pg_ctl start -D /opt/postgres/data'" >> /etc/rc.d/init.d/postgres
				echo ";;" >> /etc/rc.d/init.d/postgres
				echo "stop)" >> /etc/rc.d/init.d/postgres
				echo "	su postgres -c '/usr/pgsql*/bin/pg_ctl stop -D /opt/postgres/data'" >> /etc/rc.d/init.d/postgres
				echo ";;" >> /etc/rc.d/init.d/postgres
				echo "esac" >> /etc/rc.d/init.d/postgres
				chmod 755 /etc/rc.d/init.d/postgres 2>>$ERROR
				chkconfig --add postgres 2>>$ERROR
				chkconfig --level 3 postgres on 2>>$ERROR
				service postgres start >/dev/null 2>>$ERROR
				ret=$?
				if [ $ret -ne 0 ]
				then
					Screen_output 0 "The Postgres Server failed to start !!"
					echo " Errorcode : $ret"
					echo ""
					Continue
				else
					touch $INSTALL_LOG_DIR/postgresinstalled.log
					echo "Done."
				fi
			fi
		fi
	fi
}

Install_flowable()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install Flowable BMP.                                           *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Flowable ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 " Flowable will be installed .... "
	else
		echo -n " Installing Flowable .... "
	fi
	unzip $FLOWABLE_FILE -d $INSTALL_DIR >/dev/null 2>>$ERROR
	ret=$?
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "The installation of Flowable failed."
		echo ""
		echo " Errorcode : $ret"
		echo "The installation of Flowable failed" >> $INSTALL_LOG_FILE
		Abort_install
	else
		touch $INSTALL_LOG_DIR/flowable.log
		if [ "$SILENT" = "false" ]
		then
			Continue
		else
			echo "Done."
			su postgres -c '/usr/pgsql*/bin/psql -f initflowable.sql' >/dev/null 2>>$ERROR
			su postgres -c '/usr/pgsql*/bin/psql -U flowable -d flowable -f /opt/flowable-6.1.2/database/create/flowable.postgres.create.engine.sql' >/dev/null 2>>$ERROR
			su postgres -c '/usr/pgsql*/bin/psql -U flowable -d flowable -f /opt/flowable-6.1.2/database/create/flowable.postgres.create.history.sql' >/dev/null 2>>$ERROR
		fi
		echo "The installation of Flowable is complete" >> $INSTALL_LOG_FILE
	fi
}

Install_tomcat()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install Apache Tomcat.                                          *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Tomcat ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 " Tomcat will be installed .... "
	else
		echo -n " Installing Tomcat .... "
	fi
	gunzip $TOMCAT_FILE >/dev/null 2>>$ERROR
	tar xvf $INSTALL_FILE_DIR/software/apache*tar -C $INSTALL_DIR >/dev/null 2>>$ERROR
	ret=$?
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "The installation of Tomcat failed."
		echo ""
		echo " Errorcode : $ret"
		echo "The installation of Tomcat failed" >> $INSTALL_LOG_FILE
		Abort_install
	else
		echo "export CLASSPATH=/opt/slf4j-1.7.25/slf4j-ext-1.7.25.jar" >>$INSTALL_DIR/apache-tomcat-8.5.16/bin/setenv.sh
		echo "JAVA_OPTS=\"-XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=256M\"" >>$INSTALL_DIR/apache-tomcat-8.5.16/bin/setenv.sh
		cp $INSTALL_FILE_DIR/jars/post*jar $INSTALL_DIR/apa*/lib >/dev/null 2>>$ERROR
		touch $INSTALL_LOG_DIR/tomcat.log
		if [ "$SILENT" = "false" ]
		then
			Continue
		else
			echo "Done."
		fi
		echo "The installation of Tomcat is complete" >> $INSTALL_LOG_FILE
	fi
}

Install_slf()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install the SLF4J logging framework.                            *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing SLF4J ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 " SLF4J will be started .... "
	else
		echo -n " Installing SLF4J .... "
	fi
	if [ -f $INSTALL_FILE_DIR/software/slf4j*tar.gz ]
		then
			gunzip $INSTALL_FILE_DIR/software/slf4j*gz >/dev/null 2>>$ERROR
			tar xvf $INSTALL_FILE_DIR/software/slf4j*tar -C $INSTALL_DIR >/dev/null 2>>$ERROR
			ret=$?
			if [ $ret -ne 0 ]
			then
				Screen_output 0 "The installation of SLF4J failed."
				echo ""
				echo " Errorcode : $ret"
				echo "The installation of SLF4J failed" >> $INSTALL_LOG_FILE
				Continue
			else
				touch $INSTALL_LOG_DIR/slf.log
				if [ "$SILENT" = "false" ]
				then
					Continue
				else
					echo "Done."
				fi
			fi
	else
		Screen_output 0 " SLF4J will not be installed !!"
		echo ""
		Continue
	fi
}

Install_flowable_wars()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install all Flowable applications / war files.                  *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Flowable wars ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 " Flowable war files will be installed .... "
	else
		echo -n " Installing Flowable war files .... "
	fi
	APADIR=`dirname $INSTALL_DIR/apa*/conf/context.xml`
	mkdir -p $APADIR/Catalina/localhost
	for wars in $INSTALL_DIR/flowable*/wars/flowable*.war
	do
		WARFILE=`basename $wars`
		case $WARFILE in
			flowable-rest.war)
				cp $INSTALL_DIR/flowable*/wars/flowable-rest.war $INSTALL_DIR/apache-tomcat-*/webapps >/dev/null 2>>$ERROR
				mkdir -p $INSTALL_FILE_DIR/WEB-INF/classes >/dev/null 2>>$ERROR
				cp $INSTALL_FILE_DIR/classes/db.properties $INSTALL_FILE_DIR/WEB-INF/classes >/dev/null 2>>$ERROR
				jar uvf $INSTALL_DIR/apache-tomcat-*/webapps/flowable-rest.war WEB-INF >/dev/null 2>>$ERROR
				rm -rf $INSTALL_FILE_DIR/WEB-INF >/dev/null 2>>$ERROR
			;;
			flowable-admin.war)
				cp $INSTALL_DIR/flowable*/wars/flowable-admin.war $INSTALL_DIR/apache-tomcat-*/webapps >/dev/null 2>>$ERROR
				mkdir -p $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app >/dev/null 2>>$ERROR
				cd $INSTALL_FILE_DIR >/dev/null 2>>$ERROR
				jar xvf $INSTALL_DIR/flow*/wars/flowable-admin.war -x WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/datasource.driver=org.h2.Driver/#datasource.driver=org.h2.Driver/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/datasource.url=jdbc:h2:mem:flowable;DB_CLOSE_DELAY=-1/#datasource.url=jdbc:h2:mem:flowable;DB_CLOSE_DELAY=-1/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/localhost/flowabledemo/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				echo "datasource.jndi.name=jdbc/flowable-admin" >>$INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties
				echo "datasource.jndi.resourceRef=true" >>$INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties
				jar uvf $INSTALL_DIR/apache-tomcat-*/webapps/flowable-admin.war WEB-INF >/dev/null 2>>$ERROR
				rm -rf $INSTALL_FILE_DIR/WEB-INF >/dev/null 2>>$ERROR
			;;
			flowable-idm.war)
				cp $INSTALL_DIR/flowable*/wars/flowable-idm.war $INSTALL_DIR/apache-tomcat-*/webapps >/dev/null 2>>$ERROR
				mkdir -p $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app >/dev/null 2>>$ERROR
				cd $INSTALL_FILE_DIR >/dev/null 2>>$ERROR
				jar xvf $INSTALL_DIR/flow*/wars/flowable-idm.war -x WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/datasource.driver=org.h2.Driver/#datasource.driver=org.h2.Driver/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/datasource.url=jdbc:h2:mem:flowable;DB_CLOSE_DELAY=-1/#datasource.url=jdbc:h2:mem:flowable;DB_CLOSE_DELAY=-1/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/localhost/flowabledemo/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				echo "datasource.jndi.name=jdbc/flowable-idm" >>$INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties
				echo "datasource.jndi.resourceRef=true" >>$INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties
				jar uvf $INSTALL_DIR/apache-tomcat-*/webapps/flowable-idm.war WEB-INF >/dev/null 2>>$ERROR
				rm -rf $INSTALL_FILE_DIR/WEB-INF >/dev/null
			;;
			flowable-modeler.war)
				cp $INSTALL_DIR/flowable*/wars/flowable-modeler.war $INSTALL_DIR/apache-tomcat-*/webapps >/dev/null 2>>$ERROR
				mkdir -p $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app >/dev/null 2>>$ERROR
				cd $INSTALL_FILE_DIR >/dev/null 2>>$ERROR
				jar xvf $INSTALL_DIR/flow*/wars/flowable-modeler.war -x WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/datasource.driver=org.h2.Driver/#datasource.driver=org.h2.Driver/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/datasource.url=jdbc:h2:mem:flowable;DB_CLOSE_DELAY=-1/#datasource.url=jdbc:h2:mem:flowable;DB_CLOSE_DELAY=-1/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/localhost/flowabledemo/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				echo "datasource.jndi.name=jdbc/flowable-modeler" >>$INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties
				echo "datasource.jndi.resourceRef=true" >>$INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties
				jar uvf $INSTALL_DIR/apache-tomcat-*/webapps/flowable-modeler.war WEB-INF >/dev/null 2>>$ERROR
				rm -rf $INSTALL_FILE_DIR/WEB-INF >/dev/null 2>>$ERROR
			;;
			flowable-task.war)
				cp $INSTALL_DIR/flowable*/wars/flowable-task.war $INSTALL_DIR/apache-tomcat-*/webapps >/dev/null 2>>$ERROR
				mkdir -p $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app >/dev/null 2>>$ERROR
				cd $INSTALL_FILE_DIR >/dev/null 2>>$ERROR
				jar xvf $INSTALL_DIR/flow*/wars/flowable-task.war -x WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/datasource.driver=org.h2.Driver/#datasource.driver=org.h2.Driver/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/datasource.url=jdbc:h2:mem:flowable;DB_CLOSE_DELAY=-1/#datasource.url=jdbc:h2:mem:flowable;DB_CLOSE_DELAY=-1/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/localhost/flowabledemo/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/#email.host=flowabledemo/email.host=flowabledemo/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/#email.port=1025/email.port=2525/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				sed -i -e 's/#email.useCredentials=false/email.useCredentials=false/g' $INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties >/dev/null 2>>$ERROR
				echo "datasource.jndi.name=jdbc/flowable-task" >>$INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties
				echo "datasource.jndi.resourceRef=true" >>$INSTALL_FILE_DIR/WEB-INF/classes/META-INF/flowable-ui-app/flowable-ui-app.properties
				jar uvf $INSTALL_DIR/apache-tomcat-*/webapps/flowable-task.war WEB-INF >/dev/null 2>>$ERROR
				rm -rf $INSTALL_FILE_DIR/WEB-INF >/dev/null 2>>$ERROR
			;;
		esac
	cp $INSTALL_FILE_DIR/classes/flowable-*.xml $APADIR/Catalina/localhost
	done
	if [ "$SILENT" = "false" ]
	then
		Continue
	else
		echo "Done."
	fi
	touch $INSTALL_LOG_DIR/flowablewars.log
}

Start_tomcat()
{
# **************************************************************************************
# *                                                                                    *
# * This function will configure the integration between Flowable and Tomcat           *
# * and create the startup script, and start Tomcat.                                   *
# *                                                                                    *
# **************************************************************************************
	echo "*** Starting Tomcat ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 " Tomcat will be started .... "
	else
		echo -n " Starting Tomcat .... "
	fi
	echo "#!/bin/sh" > /etc/rc.d/init.d/flowable
	echo "#" >> /etc/rc.d/init.d/flowable
	echo "# chkconfig: 3 75 05" >> /etc/rc.d/init.d/flowable
	echo "#" >> /etc/rc.d/init.d/flowable
	echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" >> /etc/rc.d/init.d/flowable
	echo "case \"\$1\" in" >> /etc/rc.d/init.d/flowable
	echo "start)" >> /etc/rc.d/init.d/flowable
	echo "	$INSTALL_DIR/apache-tomcat-*/bin/catalina.sh run &" >> /etc/rc.d/init.d/flowable
	echo "	echo \$! >$INSTALL_DIR/utilities/tomcatpid" >> /etc/rc.d/init.d/flowable
	echo ";;" >> /etc/rc.d/init.d/flowable
	echo "stop)" >> /etc/rc.d/init.d/flowable
	echo "	kill \`cat $INSTALL_DIR/utilities/tomcatpid\`" >> /etc/rc.d/init.d/flowable
	echo ";;" >> /etc/rc.d/init.d/flowable
	echo "esac" >> /etc/rc.d/init.d/flowable
	chmod 755 /etc/rc.d/init.d/flowable 2>>$ERROR
	chkconfig --add flowable 2>>$ERROR
	chkconfig --level 3 flowable on 2>>$ERROR
	service flowable start >/dev/null 2>>$ERROR
	touch $INSTALL_LOG_DIR/tomcatstart.log
	if [ "$SILENT" = "false" ]
	then
		Continue
	else
		echo "Done."
	fi
	echo "The startup of Tomcat is complete" >> $INSTALL_LOG_FILE
}

Install_jboss()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install JBoss6.1 / 6.4                                          *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing JBoss ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "JBoss $JBOSSVERSION is being installed and configured .... "
	else
		echo -n " JBoss $JBOSSVERSION is being installed and configured .... "
	fi
	if [ ! -f $INSTALL_LOG_DIR/jbossinstalled.log ]
		then
		unzip  -o $JBOSS_FILE -d $INSTALL_DIR >/dev/null 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The JBoss $JBOSSVERSION file failed to unzip !!"
			echo " Errorcode : $ret"
			echo ""
			Abort_install
		else
			if [ "$JBOSSVERSION" = "6.4" ]
			then
				chmod 755 $INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/*.sh >/dev/null 2>>$ERROR
			fi
			touch $INSTALL_LOG_DIR/jbossinstalled.log
			echo "Jboss$JBOSSVERSION has been installed" >> $INSTALL_LOG_FILE
		fi
		JBOSS_VERSION=`basename $JBOSS_FILE|cut -f3 -d"-"|cut -f1 -d"z"`
	fi
	if [ ! -f $INSTALL_LOG_DIR/jbossconfigured.log ]
	then
		JBOSSFAIL="false"
		SECTIONSERVERS="none"
		SECTIONREALM="none"
		SECTIONDOMAIN="none"
		SECTIONIPADDRESS="none"
		PORTOFFSET="none"
		if [ ! -f $INSTALL_LOG_DIR/jbossserversection.log ]
		then
			sed -i -e '/<servers>/,/<\/servers>/{//!d}' $INSTALL_DIR/jboss-eap-$JBOSSVERSION/domain/configuration/host.xml 2>>$ERROR
			ret=$?
			if [ $ret -ne 0 ]
			then
				SECTIONSERVERS=$ret
				JBOSSFAIL=true
			else
				touch $INSTALL_LOG_DIR/jbossserversection.log
			fi
		fi
		if [ ! -f $INSTALL_LOG_DIR/sectionrealm.log ]
		then
			sed -i -s 's/security-realm=\"ApplicationRealm\"//g' $INSTALL_DIR/jboss-eap-$JBOSSVERSION/domain/configuration/domain.xml 2>>$ERROR
			ret=$?
			if [ $ret -ne 0 ]
			then
				SECTIONREALM=$ret
				JBOSSFAIL=true
			else
				touch $INSTALL_LOG_DIR/sectionrealm.log
			fi
		fi
		if [ ! -f $INSTALL_LOG_DIR/sectiondomain.log ]
		then
			sed -i -e 's/230\.0\.0\.4/230\.0\.0\.1/g' $INSTALL_DIR/jboss-eap-$JBOSSVERSION/domain/configuration/domain.xml 2>>$ERROR
			ret=$?
			if [ $ret -ne 0 ]
			then
				SECTIONDOMAIN=$ret
				JBOSSFAIL=true
			else
				sed -i -e 's/231\.7\.7\.7/231\.7\.7\.1/g' $INSTALL_DIR/jboss-eap-$JBOSSVERSION/domain/configuration/domain.xml 2>>$ERROR
				ret=$?
				if [ $ret -ne 0 ]
				then
					SECTIONDOMAIN=$ret
					JBOSSFAIL=true
				else
					touch $INSTALL_LOG_DIR/sectiondomain.log
				fi
			fi
		fi
		if [ ! -f $INSTALL_LOG_DIR/sectionipaddress.log ]
		then
			sed -i -e "s/127\.0\.0\.1/$NEWHOSTNAME/g" $INSTALL_DIR/jboss-eap-$JBOSSVERSION/domain/configuration/host.xml 2>>$ERROR
			ret=$?
			if [ $ret -ne 0 ]
			then
				SECTIONIPADDRESS=$ret
				JBOSSFAIL=true
			else
				touch $INSTALL_LOG_DIR/sectionipaddress.log
			fi
		fi
		if [ "$JBOSSFAIL"="true" ]
		then
			if [ "$SECTIONSERVERS" != "none" ]
			then
				Screen_output 0 "The configuration of the <servers> tags in the host.xml file failed !!"
				echo " The errorcode is : $SECTIONSERVERS"
				echo " Without this change, JBoss will not function properly"
				echo ""
				Abort_install
			fi
			if [ "$SECTIONREALM" != "none" ]
			then
				Screen_output 0 "The configuration of the <security-realm> tags in the domain.xml file failed !!"
				echo " The errorcode is : $SECTIONSERVERS"
				echo " Without this change, JBoss will not function properly"
				echo ""
				Abort_install
			fi
			if [ "$SECTIONDOMAIN" != "none" ]
			then
				Screen_output 0 "The configuration of the multi cast address in the domain.xml file failed !!"
				echo " The errorcode is : $SECTIONDOMAIN"
				echo " Without this change, JBoss will not function properly"
				echo ""
				Abort_install
			fi
			if [ "$SECTIONIPADDRESS" != "none" ]
			then
				Screen_output 0 "The configuration of the hostname in the host.xml file failed !!"
				echo " The errorcode is : $SECTIONIPADDRESS"
				echo " Without this change, JBoss will not function properly"
				echo ""
				Abort_install
			fi
		else
			touch $INSTALL_LOG_DIR/jbossconfigured.log
		fi
	fi
	touch $INSTALL_LOG_DIR/jboss.log
	if [ "$SILENT" = "true" ]
	then
		echo "Done."
	fi
}

Jboss_startup()
{
# **************************************************************************************
# *                                                                                    *
# * This function will setup the scripts to automatically startup JBoss.               *
# *                                                                                    *
# **************************************************************************************
	echo "*** Starting JBoss ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "The JBoss startup script is being installed, and JBoss is being started .... "
	else
		echo -n " Starting JBoss .... "
	fi
	mkdir $INSTALL_DIR/utilities/log 2>>$ERROR
	echo "#! /bin/bash" > /etc/rc.d/init.d/jbossibpm
	echo "#" >> /etc/rc.d/init.d/jbossibpm
	echo "# jbossibpm	Start and Stop JBoss / Interstage BPM" >> /etc/rc.d/init.d/jbossibpm
	echo "#" >> /etc/rc.d/init.d/jbossibpm
	echo "# chkconfig: 3 85 04" >> /etc/rc.d/init.d/jbossibpm
	echo "#" >> /etc/rc.d/init.d/jbossibpm
	echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" >> /etc/rc.d/init.d/jbossibpm
	echo "case \"\$1\" in" >> /etc/rc.d/init.d/jbossibpm
	echo "start)" >> /etc/rc.d/init.d/jbossibpm
	echo "	export LAUNCH_JBOSS_IN_BACKGROUND=true" >> /etc/rc.d/init.d/jbossibpm
	echo "	$INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/domain.sh >$INSTALL_DIR/utilities/log/jbossibpmstart &" >> /etc/rc.d/init.d/jbossibpm
	echo "	touch /var/lock/subsys/jbossibpm" >> /etc/rc.d/init.d/jbossibpm
	echo "	echo \$! >$INSTALL_DIR/utilities/log/jbosspid" >> /etc/rc.d/init.d/jbossibpm
	echo ";;" >> /etc/rc.d/init.d/jbossibpm
	echo "stop)" >> /etc/rc.d/init.d/jbossibpm
	echo "	echo \"Stopping JBoss / Interstage BPM\"" >> /etc/rc.d/init.d/jbossibpm
	echo "	echo \"Stop\" >$INSTALL_DIR/utilities/log/jbossstop" >> /etc/rc.d/init.d/jbossibpm
	echo "	kill \`cat $INSTALL_DIR/utilities/log/jbosspid\`" >> /etc/rc.d/init.d/jbossibpm
	echo "	rm -rf /var/lock/subsys/jbossibpm" >> /etc/rc.d/init.d/jbossibpm
	echo ";;" >> /etc/rc.d/init.d/jbossibpm
	echo "esac" >> /etc/rc.d/init.d/jbossibpm
	chmod 755 /etc/rc.d/init.d/jbossibpm 2>>$ERROR
	chkconfig --add jbossibpm 2>>$ERROR
	chkconfig --level 3 jbossibpm on 2>>$ERROR
	sed -i -e "s/localhost/$NEWHOSTNAME/g" $INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/jboss-cli.xml 2>>$ERROR
	service jbossibpm start >/dev/null 2>>$ERROR
	touch $INSTALL_LOG_DIR/jbossstart.log
	sleep 5
	IPADDRESS=`ip addr | grep "inet" | grep -ve "127.0.0.1" | grep -ve "inet6" | awk '{print $2}' | cut -f1 -d"/"` 2>>$ERROR
	JBOSSPRC=`ps -ef|grep jboss|wc -l`
	if [ $JBOSSPRC -ge 2 ]
	then
		if [ "$SILENT" = "false" ]
		then
			echo " JBoss should be running at the moment."
			echo " Please check by opening the browser on your machine and going to :"
			echo ""
			echo " http://$IPADDRESS:9990"
			Continue
		else
			echo "Done."
		fi
	else
		echo " JBoss does not appear to be running. Please check this first before continuing."
		echo ""
		Continue
	fi
}

Jdbc_config()
{
# **************************************************************************************
# *                                                                                    *
# * This function will configure the JBoss JDBC settings.                              *
# *                                                                                    *
# **************************************************************************************
	echo "*** Configuring JBoss ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "The JDBC settings need to be configured in JBoss, and the admin user needs to be added."
	else
		echo -n " Configuring JDBC for JBoss and adding the admin user .... "
	fi
	if [ "$INSTALLDB" = "oracle" ]
	then
		. /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh 2>>$ERROR
	fi
	if [ ! -f $INSTALL_LOG_DIR/jbossmodule.log ]
	then
		case "$INSTALLDB" in
			oracle)
				echo "module add --name=com.oracle.jdbc --resources=$ORACLE_HOME/jdbc/lib/ojdbc6.jar --dependencies=javax.api,javax.transaction.api">$INSTALL_FILE_DIR/cliscript 2>>$ERROR
			;;
			postgresas)
				POSTGRESJAR=`ls $INSTALL_DIR/edb/connectors/jdbc/edb-*17.jar`
				echo "module add --name=com.postgres.jdbc --resources=$POSTGRESJAR --dependencies=javax.api,javax.transaction.api">$INSTALL_FILE_DIR/cliscript 2>>$ERROR
			;;
		esac
		echo "quit">>$INSTALL_FILE_DIR/cliscript 2>>$ERROR
		$INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/jboss-cli.sh --file=$INSTALL_FILE_DIR/cliscript 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			clear
			echo ""
			echo " The JDBC / JBoss configuration failed."
			echo ""
			echo " The errorcode is : $ret"
			echo ""
			Abort_install
		else
			rm -rf $INSTALL_FILE_DIR/cliscript
			touch $INSTALL_LOG_DIR/jbossmodule.log
		fi
	fi
	if [ "$SILENT" = "false" ]
	then
		$INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/add-user.sh 
	else
		JBOSSUSER=`grep "JBOSSUSER:" $SILENT_FILE | cut -f2 -d":"`
		JBOSSPWD=`grep "JBOSSPWD:" $SILENT_FILE | cut -f2 -d":"`
		$INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/add-user.sh -s $JBOSSUSER $JBOSSPWD > /dev/null 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			clear
			echo ""
			echo " The JBoss admin user did not get added."
			echo ""
			echo " The errorcode is : $ret"
			echo ""
			Continue
		else
			echo "Done."
		fi
	fi
	touch $INSTALL_LOG_DIR/jdbcconfig.log
	echo "JDBC configuration completed" >> $INSTALL_LOG_FILE
}

Ibpm_engine()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install the I-BPM engine directory.                             *
# *                                                                                    *
# **************************************************************************************
	echo "*** Unzipping I-BPM engine directory ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "The engine directory for Interstage BPM will be installed ... "
	else
		echo -n " Installing the I-BPM engine directory .... "
	fi
	if [ "$IBPMVERSION" = "3" -o "$IBPMVERSION" = "4.1" ]
	then
		unzip  -o $IBPMFILE 'engine/*' -d $INSTALL_DIR >/dev/null 2>>$ERROR
		ret=$?
	fi
	if [ "$IBPMVERSION" = "4" ]
	then
		unzip  -o $IBPMFILE 'I-BPM11.4-EnterpriseEdition-CD_IMAGE/engine/*' -d $INSTALL_DIR >/dev/null 2>>$ERROR
		ret=$?
		mv $INSTALL_DIR/I-BPM11.4-EnterpriseEdition-CD_IMAGE/engine $INSTALL_DIR >/dev/null 2>>$ERROR
		rm -rf $INSTALL_DIR/I-BPM11.4-EnterpriseEdition-CD_IMAGE >/dev/null 2>>$ERROR
		sleep 2
	fi
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "The Interstage BPM engine folder did not get installed !!"
		echo ""
		echo " The errorcode is : $ret"
		echo ""
		if [ ! -d $INSTALL_DIR/engine ]
		then
			echo " The folder $INSTALL_DIR/engine does not exist. Please check the $IBPMFILE to make sure it contains an engine folder."
		fi
		Abort_install
	else
		chmod 755 $INSTALL_DIR/engine/server/setup.sh 2>>$ERROR
		touch $INSTALL_LOG_DIR/engineconfig.log
		echo "Interstage BPM engine directory completed" >> $INSTALL_LOG_FILE
		if [ "$SILENT" = "true" ]
		then
			echo "Done."
		fi
	fi
	
}

Setup_config()
{
# **************************************************************************************
# *                                                                                    *
# * This function will modify the setup.config file for IBPM prior to the installation.*
# *                                                                                    *
# **************************************************************************************
	echo "*** Modifying I-BPM config files ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "The setup.config for the Interstage BPM installation is being modified .... "
	else
		echo -n " Preparing for the I-BPM installation .... "
	fi
	case "$INSTALLDB" in
		oracle)
			ORACLELIST=`grep "ORACLELIST:" $SILENT_FILE | cut -f2 -d":"` 
			ORACLEPWD=`grep "ORACLEPWD:" $SILENT_FILE | cut -f2 -d":"` 
		;;
	esac
	sed -i -e 's/appserver_selected\=/appserver_selected\=JBoss/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
	case "$INSTALLDB" in
		oracle)
			sed -i -e 's/database_selected\=/database_selected\=Oracle/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e 's/jdbc_module_name\=/jdbc_module_name\=com.oracle.jdbc/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s/db_ibpm_password\=/db_ibpm_password\=$ORACLEPWD/g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s/db_port\=/db_port\=$ORACLELIST/g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s|db_jdbc_library_path\=|db_jdbc_library_path\=$ORACLE_HOME\/jdbc\/lib\/ojdbc6.jar|g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s|db_database_home\=|db_database_home\=$ORACLE_HOME|g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s/db_admin_password\=/db_admin_password\=$ORACLEPWD/g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e 's/db_data_file_location\=/db_data_file_location\=\/u01\/app\/oracle\/oradata\/XE/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e 's/db_instance_name\=ORCL/db_instance_name\=XE/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
		;;
		postgresas)
			sed -i -e 's/database_selected\=/database_selected\=EDBPostgres/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e 's/jdbc_module_name\=/jdbc_module_name\=com.postgres.jdbc/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s/db_ibpm_password\=/db_ibpm_password\=Fujitsu1/g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s/db_port\=/db_port\=5444/g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s|db_jdbc_library_path\=|db_jdbc_library_path\=$POSTGRESJAR|g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s/db_admin_user_name\=sa/db_admin_user_name\=enterprisedb/g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s/db_admin_password\=/db_admin_password\=Fujitsu1/g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s|db_data_file_location\=|db_data_file_location\=$INSTALL_DIR\/edb\/9.5AS\/data|g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e 's/database_creation_selection\=0/database_creation_selection\=1/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			echo "db_name=ibpmdb" >>$INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			echo "postgres_home=$INSTALL_DIR/edb/9.5AS" >>$INSTALL_DIR/engine/server/setup.config 2>>$ERROR
			sed -i -e "s/^PASSWORD\=/PASSWORD\=Fujitsu1/g" $INSTALL_DIR/engine/server/deployment/dbsetup/postgresql/config.sh 2>>$ERROR
			sed -i -e "s|POSTGRES_HOME\=|POSTGRES_HOME\=$INSTALL_DIR\/edb\/9.5AS|g" $INSTALL_DIR/engine/server/deployment/dbsetup/postgresql/config.sh 2>>$ERROR
			sed -i -e "s/DB_ADMIN_USER\=/DB_ADMIN_USER\=enterprisedb/g" $INSTALL_DIR/engine/server/deployment/dbsetup/postgresql/config.sh 2>>$ERROR
			sed -i -e "s/DB_ADMIN_PASSWORD\=/DB_ADMIN_PASSWORD\=Fujitsu1/g" $INSTALL_DIR/engine/server/deployment/dbsetup/postgresql/config.sh 2>>$ERROR
			sed -i -e "s/PORT\=/PORT\=5444/g" $INSTALL_DIR/engine/server/deployment/dbsetup/postgresql/config.sh 2>>$ERROR
		;;
	esac
	sed -i -e "s|appserver_home\=|appserver_home\=$INSTALL_DIR\/jboss-eap-$JBOSSVERSION|g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
	sed -i -e "s/db_host\=localhost/db_host\=$NEWHOSTNAME/g" $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
	sed -i -e 's/super_user\=ibpm_server1/super_user\=admin/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
	sed -i -e 's/super_user_password\=/super_user_password\=Fujitsu1/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
	sed -i -e 's/LDAPAccessUserID\=ibpm_server1/LDAPAccessUserID\=admin/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
	sed -i -e 's/LDAPAccessUserPassword\=/LDAPAccessUserPassword\=Fujitsu1/g' $INSTALL_DIR/engine/server/setup.config 2>>$ERROR
	sed -i -e "s/localhost/$NEWHOSTNAME/g" $INSTALL_DIR/engine/server/deployment/bin/setIBPMEnv.sh 2>>$ERROR
	touch $INSTALL_LOG_DIR/setupconfig.log
	if [ "$SILENT" = "true" ]
	then
		echo "Done."
	fi
}

Install_bpmaction()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install the BPM Action Library files.                           *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing BPMAction ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "The BPM Action Library files will be installed ...."
	else
		echo -n " Installing the BPM Action Library files .... "
	fi
	cp $INSTALL_FILE_DIR/jars/BPMAction*jar $INSTALL_DIR/engine/server/instance/default/lib/ext 2>>$ERROR
	cp $INSTALL_FILE_DIR/jars/mendo.jar $INSTALL_DIR/engine/server/instance/default/lib/ext 2>>$ERROR
	cp $INSTALL_FILE_DIR/jars/twitter*jar $INSTALL_DIR/engine/server/instance/default/lib/ext 2>>$ERROR
	if [ "$SILENT" = "true" ]
	then
		echo "Done."
	fi
	touch $INSTALL_LOG_DIR/bpmaction.log
}

Install_ibpm()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install Interstage BPM.                                         *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing I-BPM ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Interstage BPM will be installed next ...."
	else
		echo -n " Installing Interstage BPM .... "
	fi
	JAVAPATH=`ls /usr/java/jdk*/LIC*` 2>>$ERROR
	export JAVA_HOME=`dirname $JAVAPATH` 2>>$ERROR
	case "$INSTALLDB" in
		oracle)
			. /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh 2>>$ERROR
			echo "INBOUND_CONNECT_TIMEOUT_XE=0" >> $ORACLE_HOME/network/admin/listener.ora 2>>$ERROR
			echo "DIRECT_HANDOFF_TTC_XE=OFF" >> $ORACLE_HOME/network/admin/listener.ora 2>>$ERROR
			echo "SQLNET.INBOUND_CONNECT_TIMEOUT=0" > $ORACLE_HOME/network/admin/sqlnet.ora 2>>$ERROR
			lsnrctl reload >/dev/null 2>&1
		;;
		postgresas)
			if [ ! -f $INSTALL_LOG_DIR/postgresdbinstalled.log ]
			then
				cd $INSTALL_DIR/engine/server/deployment/dbsetup/postgresql
				chmod 755 *.sh >/dev/null 2>>$ERROR
				export PGDATA="$INSTALL_DIR/edb/9.5AS/data"
				./dbsetup.sh >/dev/null 2>>$ERROR
				ret=$?
				if [ $ret -ne 0 ]
				then
					Screen_output 0 "The Interstage BPM Postgres DB installation failed !!"
					echo ""
					echo " The errorcode is : $ret"
					echo ""
					echo " Also check the log file in $INSTALL_FILE_DIR/logs"
					echo ""
					Abort_install
				else
					touch $INSTALL_LOG_DIR/postgresdbinstalled.log
				fi
				cd $INSTALL_FILE_DIR
			fi
		;;
	esac
	sleep 20
	$INSTALL_DIR/engine/server/setup.sh -configFilePath $INSTALL_DIR/engine/server/setup.config >/dev/null 2>>$ERROR
	ret=$?
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "The Interstage BPM installion failed !!"
		echo ""
		echo " The errorcode is : $ret"
		echo ""
		echo " Also check the log file in $INSTALL_DIR/engine/server/deployment/logs"
		echo ""
		Abort_install
	else
		case "$INSTALLDB" in
			oracle)
				sed -i -e "s/jdbc:oracle:thin:@localhost:1521:XE/jdbc:oracle:thin:@$NEWHOSTNAME:1521:XE/g" $INSTALL_DIR/jboss-eap-$JBOSSVERSION/domain/configuration/domain.xml 2>>$ERROR
			;;
		esac
		Change_smtp
		touch $INSTALL_LOG_DIR/ibpminstalled.log
		case "$INSTALLDB" in
			oracle)
				rm -rf $ORACLE_HOME/network/admin/sqlnet.ora
			;;
		esac
		echo "Interstage BPM installation completed" >> $INSTALL_LOG_FILE
		if [ "$SILENT" = "false" ]
		then
			Continue
		else
			echo "Done."
		fi
	fi
}

Restart_Jboss()
{
# **************************************************************************************
# *                                                                                    *
# * This function will restart JBoss.                                                  *
# *                                                                                    *
# **************************************************************************************
	echo "*** Restarting JBoss ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Restarting JBoss ...."
	else
		echo -n " Restarting JBoss .... "
	fi
	service jbossibpm stop >/dev/null 2>>$ERROR
	sleep 30
	service jbossibpm start > /dev/null 2>>$ERROR
	sleep 40
	if [ "$SILENT" = "false" ]
		then
			Continue
		else
			echo "Done."
	fi
}

Change_smtp()
{
# **************************************************************************************
# *                                                                                    *
# * This function will change the I-BPM SMTP settings to use kMail by default.         *
# *                                                                                    *
# **************************************************************************************
	echo "*** Changing SMTP settings ***" >>$ERROR
	case "$INSTALLDB" in
		oracle)
			sqlplus ibpmuser/Fujitsu1 @ $INSTALL_FILE_DIR/smtphost.sql >/dev/null 2>>$ERROR
			ret=$?
		;;
		postgresas)
			$INSTALL_DIR/edb/9.5AS/bin/psql -U enterprisedb -d ibpmdb -c "\copy ibpmproperties to 'bpmprop' csv;" >/dev/null 2>>$ERROR
			sed -i -e "s/SMTPServerHost,\"\",-1,0/SMTPServerHost,\"$NEWHOSTNAME\",-1,0/g" bpmprop >/dev/null 2>>$ERROR
			sed -i -e 's/SMTPServerPort,25,-1,0/SMTPServerPort,2525,-1,0/g' bpmprop >/dev/null 2>>$ERROR
			$INSTALL_DIR/edb/9.5AS/bin/psql -U enterprisedb -d ibpmdb -c "delete from ibpmproperties" >/dev/null 2>>$ERROR
			$INSTALL_DIR/edb/9.5AS/bin/psql -U enterprisedb -d ibpmdb -c "\copy ibpmproperties from 'bpmprop' csv;" >/dev/null 2>>$ERROR
			ret=$?
		;;
	esac
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "The SMTP host setting did not get changed !!"
		echo ""
		echo " The errorcode is : $ret"
		echo ""
		Continue
	fi
}

Install_webpage()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install the Welcome web page shown by going to the default      *
# * URL once the VM has been installed completely.                                     *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing webpage ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "The default web page is being installed .... "
		echo -n " What is the version number of the VM you are building ? "
		read INPUT
		NEWVMVERSION=`echo $INPUT | sed -e 's/[^0-9]*//g'` 2>>$ERROR
		if [ -z $NEWVMVERSION ]
		then
			echo ""
			echo " You did not specify a version number for this new VM ...."
			Continue
		fi
	else
		echo -n " Installing the Welcome web page .... "
		NEWVMVERSION=`grep "NEWVMVERSION:" $SILENT_FILE | cut -f2 -d":"`
	fi
	systemctl enable httpd >/dev/null 2>&1
	if [ "$APPLICATION" = "IBPM" ]
	then
		cp -r $INSTALL_FILE_DIR/ibpmweb $INSTALL_FILE_DIR/web >/dev/null 2>>$ERROR
	else
		cp -r $INSTALL_FILE_DIR/flowweb $INSTALL_FILE_DIR/web >/dev/null 2>>$ERROR
	fi
	cp $INSTALL_FILE_DIR/web/*.htm* /var/www/html 2>>$ERROR
	cp -r $INSTALL_FILE_DIR/web/css /var/www/html 2>>$ERROR
	cp -r $INSTALL_FILE_DIR/web/scripts /var/www/html 2>>$ERROR
	cp $INSTALL_FILE_DIR/README.txt /root/README.txt 2>>$ERROR
	sed -i -e "s/version : /version : $NEWVMVERSION/g" /root/README.txt 2>>$ERROR
	chmod 755 /var/www/html/scripts/systemstatus 2>>$ERROR
	/var/www/html/scripts/systemstatus 2>>$ERROR
	echo "0,5,10,15,20,25,30,35,40,45,50,55 * * * * root /var/www/html/scripts/systemstatus" >> /etc/crontab 2>>$ERROR
	/usr/sbin/apachectl start 2>>$ERROR
	touch $INSTALL_LOG_DIR/webpage.log
	if [ "$SILENT" = "true" ]
	then
		echo "Done."
	fi
}

Install_alfresco()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install Alfresco.                                               *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Afresco ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Afresco is being installed ...."
	else
		echo -n " Installing Alfresco .... "
	fi
	yum -y install fontconfig libSM libICE libXrender libXext cups-libs >/dev/null 2>>$ERROR
	chmod 755 $ALFRESCO_FILE
	$INSTALL_DIR/edb/9.5AS/bin/psql -U enterprisedb -c 'create database alfresco' >/dev/null 2>>$ERROR
	$INSTALL_DIR/edb/9.5AS/bin/psql -U enterprisedb -c "create user alfresco password 'alfresco'" >/dev/null 2>>$ERROR
	$INSTALL_DIR/edb/9.5AS/bin/psql -U enterprisedb -c 'grant all privileges on database alfresco to alfresco' >/dev/null 2>>$ERROR
	$ALFRESCO_FILE<<ALFRESCO >/dev/null 2>>$ERROR
y
1
2
n
n
y
y
y
y
y
y
y

jdbc:postgresql://localhost:5444/alfresco


alfresco
alfresco
alfresco
$NEWHOSTNAME



8010


Fujitsu1
Fujitsu1
y

y
n
n
ALFRESCO
	JAVA8DIR=`basename /usr/java/jdk1.8*`
	sed -i -e "s/JAVA_HOME=\/usr/JAVA_HOME=\/usr\/java\/$JAVA8DIR/g" $INSTALL_DIR/alfresco-community/tomcat/bin/setenv.sh
	rm -rf $INSTALL_DIR/alfresco-community/tomcat/lib/postgres*jar
	cp $INSTALL_FILE_DIR/jars/postgres*jar $INSTALL_DIR/alfresco-community/tomcat/lib 2>>$ERROR
	echo "" >> $INSTALL_DIR/AgileAdapterData/iFlowClient.properties 2>>$ERROR
	echo "cmis_user=admin" >> $INSTALL_DIR/AgileAdapterData/iFlowClient.properties 2>>$ERROR
	echo "cmis_password=Fujitsu1" >> $INSTALL_DIR/AgileAdapterData/iFlowClient.properties 2>>$ERROR
	echo "cmis_url=http://$NEWHOSTNAME:8080/alfresco/api/-default/cmis/versions/1.1/atom" >> $INSTALL_DIR/AgileAdapterData/iFlowClient.properties 2>>$ERROR
	echo "cmis_repository=" >> $INSTALL_DIR/AgileAdapterData/iFlowClient.properties 2>>$ERROR
	echo "" >> $INSTALL_DIR/alfresco-community/tomcat/shared/classes/alfresco-global.properties
	service alfresco start >/dev/null 2>>$ERROR
	cd $INSTALL_FILE_DIR
	while ! service alfresco status | grep "tomcat already running" >/dev/null 2>>$ERROR
	do
		sleep 5
	done
	sed -i -e '/start () {/r alfresco.start' /etc/rc.d/init.d/alfresco
	ret=$?
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "The Alfresco Service failed to start !!"
		Continue
	fi
	if [ -f $INSTALL_DIR/alfresco-community/tomcat/shared/classes/alfresco-global.properties ]
	then
		sed -i -e 's/db.pool.max=275/db.pool.max=50/g' $INSTALL_DIR/alfresco-community/tomcat/shared/classes/alfresco-global.properties 2>>$ERROR
		touch $INSTALL_LOG_DIR/alfresco.log
	fi
	if [ "$SILENT" = "true" ]
	then
		echo "Done."
	fi
}

Create_appversion()
{
# **************************************************************************************
# *                                                                                    *
# * This function will a json file containing all applications and versions installed. *
# *                                                                                    *
# **************************************************************************************
	echo "*** Creating appversion json file ***" >>$ERROR
	APPVERSIONFILE=/var/www/html/scripts/appversions.json
	case "$INSTALLDB" in
		oracle)
			ORACLEVERSION=`basename $ORACLE_FILE|cut -f3 -d"-"`
			DBVERSION="Oracle $ORACLEVERSION"
		;;
		*)
			POSTGRESVERSION=`basename $POSTGRES_FILE|cut -f2 -d"-"`
			DBVERSION="Postgres $POSTGRESVERSION"
		;;
	esac
	MAILTEST="false"
	if [ -f $INSTALL_LOG_DIR/kmail.log ]
	then
		jar xvf $INSTALL_FILE_DIR/options/kMail.war WEB-INF/BuildInfo.properties >/dev/null
		MAILVERSION=`cat WEB-INF/BuildInfo.properties|cut -f2 -d"="|grep "-"`
		rm -rf WEB-INF >/dev/null
		MAILNAME="kMail"
		MAILTEST="true"
	fi
	if [ -f $INSTALL_LOG_DIR/phoc.log ]
	then
		jar xvf $INSTALL_FILE_DIR/options/posthoc.war WEB-INF/BuildInfo.properties >/dev/null
		MAILVERSION=`cat WEB-INF/BuildInfo.properties|cut -f2 -d"="|grep "-"`
		rm -rf WEB-INF >/dev/null
		MAILNAME="PostHoc"
		MAILTEST="true"
	fi
	if [ "$MAILTEST" = "false" ]
	then
		MAILVERSION="unknown"
	else
		sed -i -e "s/PostHoc/$MAILNAME/g" /var/www/html/appversions.html
	fi
	if [ "$APPLICATION" = "IBPM" ]
	then
		if [ "$JBOSSINSTALL" = "no" ]
		then
			JBOSS_VERSION="not installed"
		else
			JBOSS_VERSION=`basename $JBOSS_FILE | cut -f3 -d"-" | cut -f1 -d"z"`
			if [ "$JBOSS_VERSION" = "6.4." ]
			then
				JBOSS_VERSION="6.4.9"
			fi
		fi
		if [ "$IBPMINSTALL" = "no" ]
		then
			IBPM_VERSION="not installed"
		fi
		if [ "$IBPMINSTALL" = "no" -o "$JBOSSINSTALL" = "no" ]
		then
			CHATVERSION="not installed"
			AAVERSION="not installed"
			KMAILVERSION="not installed"
			DEMOVERSION="not installed"
			SSOFIVERSION="not installed" 
		else
			CHATVERSION="unknown"
			if [ -f $INSTALL_LOG_DIR/aa.log ]
			then
				jar xvf $INSTALL_FILE_DIR/options/aa.war WEB-INF/BuildInfo.properties >/dev/null
				AAVERSION=`cat WEB-INF/BuildInfo.properties|cut -f2 -d"="|grep "-"`
				rm -rf WEB-INF >/dev/null
			else
				AAVERSION="unknown"
			fi
			if [ -f $INSTALL_LOG_DIR/ssofi.log ]
			then
				jar xvf $INSTALL_FILE_DIR/options/ssofi.war WEB-INF/BuildInfo.properties >/dev/null
				SSOFIVERSION=`cat WEB-INF/BuildInfo.properties|cut -f2 -d"="|grep "-"`
				rm -rf WEB-INF >/dev/null
			else
				SSOFIVERSION="unknown"
			fi
			if [ -f $INSTALL_LOG_DIR/ea.log ]
			then
				jar xvf $INSTALL_FILE_DIR/options/ea.war WEB-INF/BuildInfo.properties >/dev/null
				EAVERSION=`cat WEB-INF/BuildInfo.properties|cut -f2 -d"="|grep "-"`
				rm -rf WEB-INF >/dev/null
			else
				EAVERSION="unknown"
			fi
		fi
		if [ -f $ALFRESCO_FILE ]
		then
			ALFRESCOVERSION=`ls $ALFRESCO_FILE|cut -f4 -d"-"`
		else
			ALFRESCOVERSION="unknown"
		fi
	else
		CHATVERSION="unknown"
		if [ -f $INSTALL_FILE_DIR/software/apache-tomcat-*.tar ]
		then
			TOMCATVERSION=`ls $INSTALL_FILE_DIR/software/apache-tomcat-*.tar|cut -f3 -d"-"|cut -f1-3 -d"."`
		else
			TOMCATVERSION="not installed"
		fi
		if [ -f $INSTALL_FILE_DIR/software/flowable*.zip ]
		then
			FLOWABLEVERSION=`ls $INSTALL_FILE_DIR/software/flowable*.zip|cut -f2 -d"-"|cut -f1-3 -d"."`
		else
			FLOWABLEVERSION="not installed"
		fi
	fi
	if [ -f /etc/centos-release ]
	then
		OSRELEASE=`cat /etc/centos-release`
	else
		OSRELEASE="unknown"
	fi
	INSTALLDATE=`date`
	JDK7VERSION=`basename $JDK7_INSTALL_FILE|cut -f2 -d"-"`
	JDK8VERSION=`basename $JDK8_INSTALL_FILE|cut -f2 -d"-"`
	ELASTIC_VERSION=`basename $ELASTICFILE|cut -f2 -d"-"|cut -f1 -d"r"|cut -f1-3 -d"."`
	KIBANA_VERSION=`basename $KIBANAFILE|cut -f2 -d"-"`
	if [ "$APPLICATION" = "IBPM" ]
	then
		if [ "$IBPMVERSION" = "4.1" ]
		then
			echo "{\"installdate\":\"$INSTALLDATE\",\"script\":\"$VERSION\",\"vmversion\":\"$NEWVMVERSION\",\"osversion\":\"$OSRELEASE\",\"jdk8\":\"$JDK8VERSION\",\"database\":\"$DBVERSION\",\"jboss\":\"$JBOSS_VERSION\",\"ibpm\":\"$IBPM_VERSION\",\"es\":\"$ELASTIC_VERSION\",\"kibana\":\"$KIBANA_VERSION\",\"chat\":\"$CHATVERSION\",\"aa\":\"$AAVERSION\",\"email\":\"$MAILVERSION\",\"ea\":\"$EAVERSION\",\"ssofi\":\"$SSOFIVERSION\",\"alfresco\":\"$ALFRESCOVERSION\"}" >$APPVERSIONFILE
		else
			echo "{\"installdate\":\"$INSTALLDATE\",\"script\":\"$VERSION\",\"vmversion\":\"$NEWVMVERSION\",\"osversion\":\"$OSRELEASE\",\"jdk7\":\"$JDK7VERSION\",\"jdk8\":\"$JDK8VERSION\",\"database\":\"$DBVERSION\",\"jboss\":\"$JBOSS_VERSION\",\"ibpm\":\"$IBPM_VERSION\",\"es\":\"$ELASTIC_VERSION\",\"kibana\":\"$KIBANA_VERSION\",\"chat\":\"$CHATVERSION\",\"aa\":\"$AAVERSION\",\"email\":\"$MAILVERSION\",\"ea\":\"$EAVERSION\",\"ssofi\":\"$SSOFIVERSION\",\"alfresco\":\"$ALFRESCOVERSION\"}" >$APPVERSIONFILE
		fi	
	else
		echo "{\"installdate\":\"$INSTALLDATE\",\"script\":\"$VERSION\",\"vmversion\":\"$NEWVMVERSION\",\"osversion\":\"$OSRELEASE\",\"jdk7\":\"$JDK7VERSION\",\"jdk8\":\"$JDK8VERSION\",\"database\":\"$DBVERSION\",\"es\":\"$ELASTIC_VERSION\",\"kibana\":\"$KIBANA_VERSION\",\"chat\":\"$CHATVERSION\",\"email\":\"$MAILVERSION\",\"flowable\":\"$FLOWABLEVERSION\",\"tomcat\":\"$TOMCATVERSION\"}" >$APPVERSIONFILE
	fi	
}

Install_war()
{
# **************************************************************************************
# *                                                                                    *
# * This function will check for WAR files in the installation directory. If any are   *
# * are present, it will give the user the option to install them into JBoss.          *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing war files ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "WAR files are being installed ...."
	fi
	if [ "$APPLICATION" = "IBPM" ]
	then
		for war in $INSTALL_FILE_DIR/options/*.war
		do
			WARFILE=`basename $war`
			case $WARFILE in
				kMail.war)
					if [ "$INSTALLMAIL" = "kmail" ]
					then
						if [ ! -f $INSTALL_LOG_DIR/kmail.log ]
						then
							if [ "$SILENT" = "false" ]
							then
								echo ""
								echo " Installing kMail.war ... "
							else
								echo -n " Installing kMail.war ...."
							fi
							Check_war $war WEB-INF/DataLocation.properties
							if [ "$WARCONTENT" = "true" ]
							then
								echo "connect" > $INSTALL_FILE_DIR/cliscript 2>>$ERROR
								echo "deploy $war --server-groups=iflow-server-group" >> $INSTALL_FILE_DIR/cliscript 2>>$ERROR
								echo "quit" >> $INSTALL_FILE_DIR/cliscript 2>>$ERROR
								$INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/jboss-cli.sh --file=$INSTALL_FILE_DIR/cliscript 2>>$ERROR
								ret=$?
								if [ $ret -ne 0 ]
								then
									Screen_output 0 "The kMail.war file failed to deploy !!"
									echo " Errorcode : $ret"
									echo ""
									Continue
								else
									touch $INSTALL_LOG_DIR/kmail.log
									if [ -f /var/www/html/index.html ]
										then
											sed -i -e "s/posthoc/kMail/g" /var/www/html/index.html
										fi
									if [ "$SILENT" = "true" ]
									then
										echo "Done."
									fi
								fi
							else
								Screen_output 0 "The kMail.war file does not contain a DataLocation.properties file !!"
								echo ""
								Continue
							fi
						fi
					fi
				;;
				posthoc.war)
					if [ "$INSTALLMAIL" = "posthoc" ]
					then
						if [ ! -f $INSTALL_LOG_DIR/phoc.log ]
						then
							if [ "$SILENT" = "false" ]
							then
								echo ""
								echo " Installing posthoc.war ... "
							else
								echo -n " Installing posthoc.war ...."
							fi
							cp $INSTALL_FILE_DIR/options/posthoc.war $INSTALL_FILE_DIR/options/posthoc.war.bck
							Check_war $war WEB-INF/DataLocation.properties
							if [ "$WARCONTENT" = "true" ]
							then
								Modify_posthoc
								echo "connect" > $INSTALL_FILE_DIR/cliscript 2>>$ERROR
								echo "deploy $war --server-groups=iflow-server-group" >> $INSTALL_FILE_DIR/cliscript 2>>$ERROR
								echo "quit" >> $INSTALL_FILE_DIR/cliscript 2>>$ERROR
								$INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/jboss-cli.sh --file=$INSTALL_FILE_DIR/cliscript 2>>$ERROR
								ret=$?
								if [ $ret -ne 0 ]
								then
									Screen_output 0 "The posthoc.war file failed to deploy !!"
									echo " Errorcode : $ret"
									echo ""
									Continue
								else
									touch $INSTALL_LOG_DIR/phoc.log
									if [ "$SILENT" = "true" ]
									then
										echo "Done."
									fi
								fi
							else
								Screen_output 0 "The posthoc.war file does not contain a DataLocation.properties file !!"
								echo ""
								Continue
							fi
						fi
					fi
				;;
				ssofi.war)
					if [ ! -f $INSTALL_LOG_DIR/ssofi.log ]
					then
						if [ "$SILENT" = "false" ]
						then
							echo " Installing ssofi.war ... "
						else
							echo -n " Installing ssofi.war .... "
						fi
						cp $INSTALL_FILE_DIR/options/ssofi.war $INSTALL_FILE_DIR/options/ssofi.war.bck
						mkdir -p $INSTALL_FILE_DIR/options/WEB-INF
						jar xvf $INSTALL_FILE_DIR/options/ssofi.war -x WEB-INF/EmailNotification.properties >/dev/null 2>>$ERROR
						mv $INSTALL_DIR/WEB-INF/EmailNotification.properties $INSTALL_FILE_DIR/options/WEB-INF
						rm -rf $INSTALL_DIR/WEB-INF
						sed -i -e "s/interstagedemo/$NEWHOSTNAME/g" $INSTALL_FILE_DIR/options/WEB-INF/EmailNotification.properties 2>>$ERROR
						cd $INSTALL_FILE_DIR/options
						jar uvf ssofi.war WEB-INF >/dev/null 2>>$ERROR
						cd $INSTALL_FILE_DIR
						rm -rf $INSTALL_FILE_DIR/options/WEB-INF
						echo "connect" > $INSTALL_FILE_DIR/cliscript 2>>$ERROR
						echo "deploy $war --server-groups=iflow-server-group" >> $INSTALL_FILE_DIR/cliscript 2>>$ERROR
						echo "quit" >> $INSTALL_FILE_DIR/cliscript 2>>$ERROR
						$INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/jboss-cli.sh --file=$INSTALL_FILE_DIR/cliscript 2>>$ERROR
						ret=$?
						if [ $ret -ne 0 ]
						then
							Screen_output 0 "The ssofi.war file failed to deploy !!"
							echo " Errorcode : $ret"
							echo ""
							Continue
						else
							touch $INSTALL_LOG_DIR/ssofi.log
							if [ "$SILENT" = "true" ]
							then
								echo "Done."
							fi
						fi
					fi
				;;
				aa.war)
					if [ ! -f $INSTALL_LOG_DIR/aa.log ]
					then
						if [ "$SILENT" = "false" ]
						then
							echo " Installing aa.war ... "
						else
							echo -n " Installing aa.war .... "
						fi
						cp $INSTALL_FILE_DIR/options/aa.war $INSTALL_FILE_DIR/options/aa.war.bck
						mkdir $INSTALL_DIR/AgileAdapterData 2>>$ERROR
						mkdir $INSTALL_DIR/BPM_Temp_Files 2>>$ERROR
						mkdir -p $INSTALL_FILE_DIR/options/WEB-INF/lib >/dev/null 2>>$ERROR
						cp $INSTALL_DIR/engine/client/lib/iFlow.jar $INSTALL_FILE_DIR/options/WEB-INF/lib >/dev/null 2>>$ERROR
						jar xvf $INSTALL_FILE_DIR/options/aa.war -x WEB-INF/EmailNotification.properties >/dev/null 2>>$ERROR
						jar xvf $INSTALL_FILE_DIR/options/aa.war -x WEB-INF/iFlowClient.properties >/dev/null 2>>$ERROR
						mv $INSTALL_FILE_DIR/WEB-INF/EmailNotification.properties $INSTALL_FILE_DIR/options/WEB-INF
						mv $INSTALL_FILE_DIR/WEB-INF/iFlowClient.properties $INSTALL_FILE_DIR/options/WEB-INF
						sed -i -e "s/127.0.0.1/$NEWHOSTNAME/g" $INSTALL_FILE_DIR/options/WEB-INF/EmailNotification.properties 2>>$ERROR
						sed -i -e "s/interstagedemo/$NEWHOSTNAME/g" $INSTALL_FILE_DIR/options/WEB-INF/iFlowClient.properties 2>>$ERROR
						cd $INSTALL_FILE_DIR/options
						jar uvf aa.war WEB-INF >/dev/null 2>>$ERROR
						cd $INSTALL_FILE_DIR
						rm -rf $INSTALL_FILE_DIR/options/WEB-INF
						echo "connect" > $INSTALL_FILE_DIR/cliscript 2>>$ERROR
						echo "deploy $war --server-groups=iflow-server-group" >> $INSTALL_FILE_DIR/cliscript 2>>$ERROR
						echo "quit" >> $INSTALL_FILE_DIR/cliscript 2>>$ERROR
						$INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/jboss-cli.sh --file=$INSTALL_FILE_DIR/cliscript 2>>$ERROR
						ret=$?
						if [ $ret -ne 0 ]
						then
							Screen_output 0 "The aa.war file failed to deploy !!"
							echo " Errorcode : $ret"
							echo ""
							Continue
						else
							touch $INSTALL_LOG_DIR/aa.log
							if [ "$SILENT" = "true" ]
							then
								echo "Done."
							fi
						fi
					fi
				;;
				ea.war)
					if [ ! -f $INSTALL_LOG_DIR/ea.log ]
					then
						if [ "$SILENT" = "false" ]
						then
							echo " Installing ea.war ... "
						else
							echo -n " Installing ea.war .... "
						fi
						cp $INSTALL_FILE_DIR/options/ea.war $INSTALL_FILE_DIR/options/ea.war.bck
						mkdir -p $INSTALL_FILE_DIR/options/WEB-INF
						jar xvf $INSTALL_FILE_DIR/options/ea.war -x WEB-INF/Analytics.properties >/dev/null 2>>$ERROR
						mv $INSTALL_FILE_DIR/WEB-INF/Analytics.properties $INSTALL_FILE_DIR/options/WEB-INF
						sed -i -e "s/interstagedemo/$NEWHOSTNAME/g" $INSTALL_FILE_DIR/options/WEB-INF/Analytics.properties 2>>$ERROR
						cd $INSTALL_FILE_DIR/options
						jar uvf ea.war WEB-INF >/dev/null 2>>$ERROR
						cd $INSTALL_FILE_DIR
						rm -rf $INSTALL_FILE_DIR/options/WEB-INF
						echo "connect" > $INSTALL_FILE_DIR/cliscript 2>>$ERROR
						echo "deploy $war --server-groups=iflow-server-group" >> $INSTALL_FILE_DIR/cliscript 2>>$ERROR
						echo "quit" >> $INSTALL_FILE_DIR/cliscript 2>>$ERROR
						$INSTALL_DIR/jboss-eap-$JBOSSVERSION/bin/jboss-cli.sh --file=$INSTALL_FILE_DIR/cliscript 2>>$ERROR
						ret=$?
						if [ $ret -ne 0 ]
						then
							Screen_output 0 "The ea.war file failed to deploy !!"
							echo " Errorcode : $ret"
							echo ""
							Continue
						else
							touch $INSTALL_LOG_DIR/ea.log
							if [ "$SILENT" = "true" ]
							then
								echo "Done."
							fi
						fi
					fi
				;;
			esac
		done
		Restart_Jboss
		if [ "$JBOSSVERSION" = "6.4" ]
		then
				$INSTALL_DIR/engine/server/deployment/bin/exportProperties.sh $INSTALL_FILE_DIR/ibpmprop enterprisedb Fujitsu1 >/dev/null 2>>$ERROR
				echo "ByPassJBoss6EjbLoadAfterEjbCreate=false" >>$INSTALL_FILE_DIR/ibpmprop
				$INSTALL_DIR/engine/server/deployment/bin/importProperties.sh $INSTALL_FILE_DIR/ibpmprop enterprisedb Fujitsu1 >/dev/null 2>>$ERROR
		fi
		for war in $INSTALL_FILE_DIR/options/*.war
		do
			WARFILE=`basename $war`
			case $WARFILE in
				ssofi.war)
					if  [ -f $INSTALL_DIR/SSOFI_Sessions/config.txt ]
					then
						sed -i -e 's/# authStyle=local/authStyle=local/g' $INSTALL_DIR/SSOFI_Sessions/config.txt >/dev/null 2>>$ERROR
						sed -i -e 's/# authStyle=ldap//g' $INSTALL_DIR/SSOFI_Sessions/config.txt >/dev/null 2>>$ERROR
						sed -i -e 's/authStyle=ldap//g' $INSTALL_DIR/SSOFI_Sessions/config.txt >/dev/null 2>>$ERROR
						sed -i -e "s/baseURL.*/baseURL=http:\/\/$NEWHOSTNAME:49950\/ssofi\//g" $INSTALL_DIR/SSOFI_Sessions/config.txt >/dev/null 2>>$ERROR
						sed -i -e "s/rootURL.*/rootURL=http:\/\/$NEWHOSTNAME:49950\/ssofi\//g" $INSTALL_DIR/SSOFI_Sessions/config.txt >/dev/null 2>>$ERROR
					fi
				;;
			esac
		done
		touch $INSTALL_LOG_DIR/warinstalled.log
	else
		for war in $INSTALL_FILE_DIR/options/*.war
		do
			WARFILE=`basename $war`
			case $WARFILE in
				posthoc.war)
						if [ ! -f $INSTALL_LOG_DIR/phoc.log ]
						then
							if [ "$SILENT" = "false" ]
							then
								echo ""
								echo " Installing posthoc.war ... "
							else
								echo -n " Installing posthoc.war ...."
							fi
							Check_war $war WEB-INF/DataLocation.properties
							if [ "$WARCONTENT" = "true" ]
							then
								Modify_posthoc
								cp $war $INSTALL_DIR/apa*/webapps >/dev/null 2>>$ERROR
								ret=$?
								if [ $ret -ne 0 ]
								then
									Screen_output 0 "The posthoc.war file failed to copy !!"
									echo " Errorcode : $ret"
									echo ""
									Continue
								else
									touch $INSTALL_LOG_DIR/phoc.log
									if [ "$SILENT" = "true" ]
									then
										echo "Done."
									fi
								fi
							else
								Screen_output 0 "The posthoc.war file does not contain a DataLocation.properties file !!"
								echo ""
								Continue
							fi
						fi
				;;
			esac
		done
		touch $INSTALL_LOG_DIR/warinstalled.log
	fi
}

Modify_posthoc()
{
# **************************************************************************************
# *                                                                                    *
# * This function will update the Config.properties file in the posthoc.war file       *
# * with the correct hostname.                                                         *
# *                                                                                    *
# **************************************************************************************
	cd $INSTALL_FILE_DIR/options
	jar xvf $INSTALL_FILE_DIR/options/posthoc.war -x WEB-INF/Config.properties >/dev/null 2>>$ERROR
	sed -i -e "s/interstagedemo/$NEWHOSTNAME/g" $INSTALL_FILE_DIR/options/WEB-INF/Config.properties 2>>$ERROR
	sed -i -e "s/127.0.0.1/$NEWHOSTNAME/g" $INSTALL_FILE_DIR/options/WEB-INF/Config.properties 2>>$ERROR
	jar uvf posthoc.war WEB-INF > /dev/null 2>>$ERROR
	cd $INSTALL_DIR
}

Check_war()
{
# **************************************************************************************
# *                                                                                    *
# * This function check war file for the existince of files as specified by the second *
# * option.                                                                            *
# *                                                                                    *
# **************************************************************************************
	if jar tvf $1 | grep "$2" >/dev/null 2>>$ERROR
	then
		WARCONTENT="true"
	else
		WARCONTENT="false"
	fi
}

Install_chat()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install the chat functionality.                                 *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing chat ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Installing chat ..."
	else
		echo -n " Installing the chat client .... "
	fi
	echo "#!/bin/sh" > /etc/rc.d/init.d/chat.sh
	echo "#" >> /etc/rc.d/init.d/chat.sh
	echo "# chkconfig: 3 85 04" >>/etc/rc.d/init.d/chat.sh
	echo "#" >> /etc/rc.d/init.d/chat.sh
	echo "PATH=REPLACE/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" >> /etc/rc.d/init.d/chat.sh
	echo "cd $INSTALL_DIR/chat" >> /etc/rc.d/init.d/chat.sh
	echo "node app.js &" >> /etc/rc.d/init.d/chat.sh
	if [ -d $INSTALL_FILE_DIR/options/chat ]
	then
		cp -r $INSTALL_FILE_DIR/options/chat $INSTALL_DIR 2>>$ERROR
	fi
	if [ -f $INSTALL_FILE_DIR/software/node*xz ]
	then
		if [ ! -f /usr/share/kibana/node/bin/node ]
		then
			gunzip -f $INSTALL_FILE_DIR/software/node*xz 2>>$ERROR
			tar xvf $INSTALL_FILE_DIR/node*tar > /dev/null 2>>$ERROR
			NODEVERSION=`basename $INSTALL_FILE_DIR/node*x64 | cut -f2 -d"-" | sed -e 's/[^0-9]*//g'` 2>>$ERROR
			mkdir $INSTALL_DIR/node$NODEVERSION 2>>$ERROR
			cp -r $INSTALL_FILE_DIR/node*x64/* $INSTALL_DIR/node$NODEVERSION 2>>$ERROR
			sed -i -e "s|REPLACE|$INSTALL_DIR/node$NODEVERSION|g" /etc/rc.d/init.d/chat.sh 2>>$ERROR
			PATH=$PATH:$INSTALL_DIR/node$NODEVERSION/bin 2>>$ERROR
		else
			sed -i -e "s|REPLACE|/usr/share/kibana/node|g" /etc/rc.d/init.d/chat.sh 2>>$ERROR
			PATH=$PATH:/usr/share/kibana/node/bin 2>>$ERROR
		fi
		chmod 755 /etc/rc.d/init.d/chat.sh 2>>$ERROR
		chkconfig --add chat.sh 2>>$ERROR
		chkconfig --level 3 chat.sh on 2>>$ERROR
		cd $INSTALL_DIR/chat 2>>$ERROR
		npm install > /dev/null 2>&1
		service chat.sh start > /dev/null 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The chat service failed to start !!"
			echo " Errorcode : $ret"
			echo ""
			Continue
		else
			cd $INSTALL_FILE_DIR
			touch $INSTALL_LOG_DIR/chat.log
			if [ "$SILENT" = "true" ]
			then
				echo "Done."
			fi
		fi
	fi
}

Install_elastic()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install the elastic search package.                             *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Elastic Search ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Installing elastic search ..."
	else
		echo -n " Installing Elastic Search .... "
	fi
	rpm -i $ELASTICFILE >/dev/null 2>>$ERROR
	ret=$?
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "Elastic Search failed to install !!"
		echo " Errorcode : $ret"
		echo ""
		Continue
	else
		if [ "$ESVERSION" = "5" ]
		then
			sed -i -e "/#network.host: /c\network.host: $NEWHOSTNAME" /etc/elasticsearch/elasticsearch.yml 2>>$ERROR
			sed -i -e '/#node.attr.rack: r1/ a script.inline: true' /etc/elasticsearch/elasticsearch.yml 2>>$ERROR
			sed -i -e '/#node.attr.rack: r1/ a script.stored: true' /etc/elasticsearch/elasticsearch.yml 2>>$ERROR
			echo "http.cors.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
			echo "http.cors.allow-origin: \"*\"" >> /etc/elasticsearch/elasticsearch.yml
		else
			sed -i -e "/# network.host: /c\network.host: $NEWHOSTNAME" /etc/elasticsearch/elasticsearch.yml	 2>>$ERROR
			sed -i -e '/# node.rack:/ a script.inline: true' /etc/elasticsearch/elasticsearch.yml 2>>$ERROR
			sed -i -e '/# node.rack:/ a script.indexed: true' /etc/elasticsearch/elasticsearch.yml 2>>$ERROR
		fi
		if [ "$ESVERSION" = "5" ]
		then
			JAVAHOME=`ls -d /usr/java/jdk1.8*`
			sed -i "/#!\/bin\/bash/aexport JAVA_HOME=$JAVAHOME" /usr/share/elasticsearch/bin/elasticsearch 2>>$ERROR
		fi
		systemctl daemon-reload >/dev/null 2>&1
		systemctl enable elasticsearch.service >/dev/null 2>&1
		if [ "$ESVERSION" = "5" ]
		then
			sed -i -e 's/killproc -p \$pidfile -d 86400 \$prog/kill `cat \$pidfile`/g' /etc/rc.d/init.d/elasticsearch 2>>$ERROR
		fi
		if [ -f /etc/elasticsearch/jvm.options ]
		then
			sed -i -e 's/Xms2g/Xms500m/g' /etc/elasticsearch/jvm.options 2>>$ERROR
			sed -i -e 's/Xmx2g/Xmx500m/g' /etc/elasticsearch/jvm.options 2>>$ERROR
		fi
		service elasticsearch start>/dev/null 2>&1
		sleep 15
		if [ "$SILENT" = "true" ]
		then
			echo "Done."
		fi
		touch $INSTALL_LOG_DIR/elasticsearch.log
	fi
}

Install_kibana()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install Kibana.                                                 *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Kibana ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Installing Kibana ..."
	else
		echo -n " Installing Kibana .... "
	fi
	rpm -i $KIBANAFILE >/dev/null 2>>$ERROR
	ret=$?
	if [ $ret -ne 0 ]
	then
		Screen_output 0 "Kibana failed to install !!"
		echo " Errorcode : $ret"
		Continue
	else
		if [ "$ESVERSION" = "5" ]
		then
			sed -i -e "s/#elasticsearch.url: \"http:\/\/localhost:9200\"/elasticsearch.url: \"http:\/\/$NEWHOSTNAME:9200\"/g" /etc/kibana/kibana.yml 2>>$ERROR
			sed -i -e "s/#server.host: \"localhost\"/server.host: \"$NEWHOSTNAME\"/g" /etc/kibana/kibana.yml 2>>$ERROR
		else
			sed -i -e "s/# elasticsearch.url: \"http:\/\/localhost:9200\"/elasticsearch.url: \"http:\/\/$NEWHOSTNAME:9200\"/g" /$INSTALL_DIR/kibana/config/kibana.yml 2>>$ERROR
		fi
		sed -i -e '/#!\/bin\// a # chkconfig: 3 85 04' /etc/rc.d/init.d/kibana 2>>$ERROR
		if [ "$ESVERSION" = "5" ]
		then
			JAVAHOME=`ls -d /usr/java/jdk1.8*`
			sed -i "/#!\/bin\/sh/aexport JAVA_HOME=$JAVAHOME" /usr/share/kibana/bin/kibana 2>>$ERROR
		fi
		if [ -f /etc/kibana/kibana.yml ]
		then
			sed -i -e 's/#server.basePath: ""/server.basePath: "\/aa\/kibana"/g' /etc/kibana/kibana.yml
		fi
		chkconfig --add kibana >/dev/null 2>>$ERROR
		chkconfig --level 3 kibana on >/dev/null 2>&1
		service kibana start >/dev/null 2>>$ERROR
		touch $INSTALL_LOG_DIR/kibana.log
		if [ "$SILENT" = "true" ]
		then
			echo "Done."
		fi
	fi
}

Install_kibanaplugin()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install several Kibana plugins                                  *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing Kibana plugins ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Installing Kibana plugins ..."
	else
		echo -n " Installing Kibana plugins .... "
	fi
	if [ ! -f $INSTALL_LOG_DIR/trafficlight.log ]
	then
		if [ -f $INSTALL_FILE_DIR/plugins/traffic-sg.zip ]
		then
			/usr/share/kibana/bin/kibana-plugin install file:///$INSTALL_FILE_DIR/plugins/traffic-sg.zip 1>/dev/null 2>>$ERROR
			ret=$?
			if [ $ret -ne 0 ]
			then
				Screen_output 0 "The Kibana traffic light plugin failed to install !!"
				Continue
			else
				cd $INSTALL_FILE_DIR
				touch $INSTALL_LOG_DIR/trafficlight.log
			fi
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/gaugeplugin.log ]
	then
		if [ -f $INSTALL_FILE_DIR/plugins/gauge-sg.zip ]
		then
			/usr/share/kibana/bin/kibana-plugin install file:///$INSTALL_FILE_DIR/plugins/gauge-sg.zip 1>/dev/null 2>>$ERROR
			ret=$?
			if [ $ret -ne 0 ]
			then
				Screen_output 0 "The Kibana Gauge plugin failed to install !!"
				Continue
			else
				cd $INSTALL_FILE_DIR
				touch $INSTALL_LOG_DIR/gaugeplugin.log
			fi
		fi
	fi
	touch $INSTALL_LOG_DIR/kibanaplugin.log
	if [ "$SILENT" = "true" ]
	then
		echo "Done."
	fi
}

Install_esgui()
{
# **************************************************************************************
# *                                                                                    *
# * This function will install the Elastic Search GUI (E.S. Head)                      *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installing E.S. GUI ***" >>$ERROR
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "Installing Elastic Search Head ..."
	else
		echo -n " Installing Elastic Search Head .... "
	fi
	if [ -f $ESHEADFILE ]
	then
		unzip $ESHEADFILE -d $INSTALL_DIR >/dev/null 2>>$ERROR
		ret=$?
		if [ $ret -ne 0 ]
		then
			Screen_output 0 "The Elastic Search Head installation failed to install !!"
			Continue
		else
			cd $INSTALL_DIR/elasticsearch-head-master
			sed -i -e "s/localhost:9100/$NEWHOSTNAME:9100/g" $INSTALL_DIR/elasticsearch-head-master/proxy/index.js
			PATH=$PATH:/usr/share/kibana/node/bin
			npm install >/dev/null 2>>$ERROR
			cd $INSTALL_DIR
			echo "#!/bin/sh" > /etc/rc.d/init.d/eshead
			echo "#" >> /etc/rc.d/init.d/eshead
			echo "# chkconfig: 3 75 04" >> /etc/rc.d/init.d/eshead
			echo "#" >> /etc/rc.d/init.d/eshead
			echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/share/kibana/node/bin" >> /etc/rc.d/init.d/eshead
			echo "cd /$INSTALL_DIR/elasticsearch-head-master" >> /etc/rc.d/init.d/eshead
			echo "nohup npm run start &" >> /etc/rc.d/init.d/eshead
			chmod 755 /etc/rc.d/init.d/eshead
			chkconfig --add eshead >/dev/null 2>>$ERROR
			chkconfig --level 3 eshead on >/dev/null 2>>$ERROR
			echo "Done"
			touch $INSTALL_LOG_DIR/esgui.log
		fi
	fi
}

Resource_check()
{
# **************************************************************************************
# *                                                                                    *
# * This function will check the server for certain resources (Memory / CPU), prior    *
# * to the start of the installation.                                                  *
# *                                                                                    *
# **************************************************************************************
	echo "*** Checking resource ***" >>$ERROR
	TOTALMEM=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
	if [ "$TOTALMEM" -lt "7000000" ]
	then
		Screen_output 0 "The Server requires at least 8GB of Memory for the installation !!"
		Abort_install
	fi
	TOTALCPU=`grep processor /proc/cpuinfo | wc -l`
	if [ "$TOTALCPU" -lt "2" ]
	then
		Screen_output 0 "The Server requires at least 2 CPU's for the installation !!"
		Abort_install
	fi	
}

Wait_alfresco()
{
# **************************************************************************************
# *                                                                                    *
# * This function will wait until Alfresco has been initialized, before the            *
# * installation can move to the next step.                                            *
# *                                                                                    *
# **************************************************************************************	
	if [ ! -f $INSTALL_DIR/alfresco-community/alfresco.log ]
	then
		touch $INSTALL_DIR/alfresco-community/alfresco.log
	fi
	if ! grep "Startup of 'Transformers' subsystem, ID: " $INSTALL_DIR/alfresco-community/alfresco.log | grep "complete" >/dev/null 2>>$ERROR
	then
		clear
		echo ""
		echo ""
		echo -n " Waiting for the Alfresco Database to finish initializing ."
		until grep "Startup of 'Transformers' subsystem, ID: " $INSTALL_DIR/alfresco-community/alfresco.log | grep "complete" >/dev/null
		do
			sleep 15
			echo -n "."
		done
		echo " Done."
	fi
}

Cleanup_install()
{
# **************************************************************************************
# *                                                                                    *
# * This function will remove the installation directory and all its files if the      *
# * user wants to do so.                                                               *
# *                                                                                    *
# **************************************************************************************
	echo "*** Installation cleanup ***" >>$ERROR
	if [ -s $ERROR ]
	then
		Screen_output 0 "Errors did occur during the installation process. Please check the file $ERROR first before continuing."
		echo ""
		more $ERROR
		Continue
	fi
	if [ "$SILENT" = "false" ]
	then
		if [ "$APPLICATION" = "IBPM" ]
		then
			Wait_alfresco
		fi
		clear
		Screen_output 1 "The installation has been completed. Would you like to remove the entire $INSTALL_FILE_DIR directory and it's content (y/n) : [n] ? "
		if [ "$INPUT" = "y" ]
		then
			cd $INSTALL_DIR
			rm -rf $INSTALL_FILE_DIR
		fi
	else
		if [ "$APPLICATION" = "IBPM" ]
		then
			Wait_alfresco
		fi
		clear
		if [ "$CLEANINSTALL" = "yes" ]
		then
			echo -n " Deleting the $INSTALL_FILE_DIR directory .... "
			cd $INSTALL_DIR
			rm -rf $INSTALL_FILE_DIR/logs
			if [ -f $INSTALL_FILE_DIR/bpmprop ]
			then
				rm -rf $INSTALL_FILE_DIR/bpmprop
			fi
			if [ -f $INSTALL_FILE_DIR/ibpmprop ]
			then
				rm -rf $INSTALL_FILE_DIR/ibpmprop
			fi
			if [ -f $INSTALL_FILE_DIR/cliscript ]
			then
				rm -rf $INSTALL_FILE_DIR/cliscript
			fi
			rm -rf $INSTALL_FILE_DIR/options/aa.war
			rm -rf $INSTALL_FILE_DIR/options/ea.war
			rm -rf $INSTALL_FILE_DIR/options/ssofi.war
			rm -rf $INSTALL_FILE_DIR/options/posthoc.war
			mv $INSTALL_FILE_DIR/options/aa.war.bck $INSTALL_FILE_DIR/options/aa.war
			mv $INSTALL_FILE_DIR/options/ea.war.bck $INSTALL_FILE_DIR/options/ea.war
			mv $INSTALL_FILE_DIR/options/posthoc.war.bck $INSTALL_FILE_DIR/options/posthoc.war
			mv $INSTALL_FILE_DIR/options/ssofi.war.bck $INSTALL_FILE_DIR/options/ssofi.war
			if [ -d $INSTALL_FILE_DIR/ppasmeta*x64 ]
			then
				rm -rf $INSTALL_FILE_DIR/ppasmeta*x64
			fi
			if [ -d $INSTALL_FILE_DIR/web ]
			then
				rm -rf $INSTALL_FILE_DIR/web
			fi
			echo "Done."
		fi
	fi
}

Last_reboot()
{
# **************************************************************************************
# *                                                                                    *
# * This function will reboot the VM at the end of the installation.                   *
# *                                                                                    *
# **************************************************************************************
	if [ "$SILENT" = "false" ]
	then
		Screen_output 0 "To finish, please add the line below to your local hosts file (on your desk- / laptop)"
		echo ""
		IPADDRESS=`ip addr | grep "inet" | grep -ve "127.0.0.1" | grep -ve "inet6" | awk '{print $2}' | cut -f1 -d"/"`
		echo "$IPADDRESS	$HOSTNAME"
		echo ""
		echo " Please do this now, then press <ENTER> to reboot the VM ..... "
		Continue
		reboot
	else
		if [ "$REBOOTEND" = "yes" ]
		then
			echo ""
			echo " The system is about to reboot ...."
			sleep 5
			reboot
		fi
	fi
}

Press_enter()
{
# **************************************************************************************
# *                                                                                    *
# * This function waits until the Enter key has been pressed.                          *
# *                                                                                    *
# **************************************************************************************
	Screen_output 1 "Please press ENTER to continue .... : "
}

Abort_install()
{
# **************************************************************************************
# *                                                                                    *
# * This function gets called when the installation needs to be aborted due to a       *
# * critical error.                                                                    *
# *                                                                                    *
# **************************************************************************************
	echo ""
	echo ""
	echo " Please correct / complete the step shown above and restart the installation."
	if [ -s $ERROR ]
	then
		echo ""
		echo " You may want to check the file $ERROR as well."
	fi
	echo "Aborting installation." >> $INSTALL_LOG_FILE
	Press_enter
	touch $INSTALL_LOG_DIR/abort.log
	exit 1
}

Missing_file()
{
# **************************************************************************************
# *                                                                                    *
# * This function displays the missing file warning.                                   *
# *                                                                                    *
# **************************************************************************************
	Screen_output 0 "The $1 installation file cannot be found in $INSTALL_FILE_DIR. The installation will be aborted !!"
	echo "File $1 missing." >> $INSTALL_LOG_FILE
	Abort_install
	exit 0
}

Check_war()
{
# **************************************************************************************
# *                                                                                    *
# * This function check war file for the existince of files as specified by the second *
# * option.                                                                            *
# *                                                                                    *
# **************************************************************************************
	if jar tvf $1 | grep "$2" >/dev/null 2>>$ERROR
	then
		WARCONTENT="true"
	else
		WARCONTENT="false"
	fi
}

Main()
{
	Init
	if [ "$SILENT" = "true" ]
	then
		if [ ! -f $SILENT_FILE ]
		then
			echo ""
			echo " You have indicated this to be a silent installation, however the file app-install.silent cannot be found."
			echo " The installation will continue as a normal installation."
			echo ""
			Continue
			SILENT=false
		else
			INSTALL_DIR=`grep "INSTALL_DIR:" $SILENT_FILE | cut -f2 -d":"`
			if [ ! -d $INSTALL_DIR ]
			then
				mkdir -p $INSTALL_DIR >/dev/null
			fi
		fi
	fi
	Install_user_check
	if [ ! -f logs/welcome.log ]
	then
		Welcome
	else
		INSTALL_FILE_DIR=`pwd`
		INSTALL_LOG_DIR=$INSTALL_FILE_DIR/logs
		INSTALL_LOG_FILE="$INSTALL_LOG_DIR/install-log"
		INSTALL_DIR=`grep "INSTALL_DIR" $INSTALL_LOG_DIR/init.config | cut -f2 -d"="`
		NEWHOSTNAME=`hostname`
		ERROR="$INSTALL_LOG_DIR/install-error.log"
		if [ -f $ERROR ]
		then
			touch $ERROR
		fi
		if [ -f $INSTALL_LOG_DIR/abort.log ]
		then
			REASON="restart of the installation."
			rm -rf $INSTALL_LOG_DIR/abort.log
		else
			REASON="reboot of the server / VM."
		fi
		Screen_output 0 "The Installation process will continue where it stopped before the $REASON."
		if [ "$SILENT" = "false" ]
		then
			Continue
		else
			echo ""
		fi
	fi
	if [ "$APPLICATION" = "IBPM" ]
	then
		Resource_check
	fi
	Check_install_files
	if [ ! -f $INSTALL_LOG_DIR/oschange.log ]
	then
		Change_os_settings
	fi
	if [ ! -f $INSTALL_LOG_DIR/scriptinstall.log ]
	then
		Install_scripts
	fi
	if [ ! -f $INSTALL_LOG_DIR/rootpwreset.log ]
	then
		Reset_rootpw
	fi
	if [ ! -f $INSTALL_LOG_DIR/reboot.log ]
	then
		if [ "$SILENT" = "false" ]
		then
			Screen_output 0 "The server / VM needs to be rebooted. Once done, log in again and start the installation in the same way again as you did before."
			Continue
			touch $INSTALL_LOG_DIR/reboot.log
			reboot
		else
			echo " The system is about to reboot ...."
			sleep 5
			touch $INSTALL_LOG_DIR/reboot.log
			reboot
		fi
	fi
	Check_tools
	if [ "$IBPMVERSION" = "4.1" ]
	then
		JVERSION="8"
	else
		JVERSION="7"
	fi
	if [ ! -f $INSTALL_LOG_DIR/jdk${JVERSION}installed.log ]
	then
		Install_jdk $JVERSION
	fi
	case "$INSTALLDB" in
		oracle)
			if [ ! -f $INSTALL_LOG_DIR/oracleinstalled.log ]
			then
				Install_oracle
			fi
		;;
		postgresas)
			if [ ! -f $INSTALL_LOG_DIR/postgresasinstalled.log ]
			then
				Install_postgresas
			fi
		;;
		postgres)
			if [ ! -f $INSTALL_LOG_DIR/postgresinstalled.log ]
			then
				Install_postgres
			fi
		;;
		*)
			Screen_ouput 0 "No database has been installed !!!"
			Continue
		;;
	esac
	if [ "$APPLICATION" = "IBPM" ]
	then
		if [ "$SILENT" = "true" ]
		then
			JBOSSINSTALL=`grep "JBOSSINSTALL:" $SILENT_FILE | cut -f2 -d":"` 
		else
			Screen_output 0 "JBoss $JBOSSVERSION installation."
			Screen_output 1 "Do you want to configure and install JBoss (y/n) ? [y] : "
			if [ "$INPUT" = "" -o "$INPUT" = "y" ]
			then
				JBOSSINSTALL="yes"
			else
				JBOSSINSTALL="no"
			fi 
		fi
		if [ "$JBOSSINSTALL" = "yes" ]
		then
			if [ ! -f $INSTALL_LOG_DIR/jboss.log ]
			then
				Install_jboss
			fi
			if [ "$JBOSSVERSION" = "6.4" ]
			then
				echo "*** Installing JBoss Patches ***" >>$ERROR
				if [ "$SILENT" = "false" ]
				then
					Screen_output 0 "JBoss 6.4 Patches are being installed : "
				else
					echo -n " JBoss 6.4 Patches are being installed (1-10): "
				fi
				if [ ! -f $INSTALL_LOG_DIR/jbosspatches.log ]
				then
					PNUM=1
					for patch in `ls $INSTALL_FILE_DIR/Patch/jboss-eap-6/jboss-eap-6.4.?.CP.zip`
					do
						if [ ! -f $INSTALL_LOG_DIR/jbosspatch$PNUM ]
						then
							$INSTALL_DIR/jboss-eap-6.4/bin/jboss-cli.sh --command="patch apply $patch" >/dev/null 2>>$ERROR
							ret=$?
							if [ $ret -ne 0 ]
							then
								Screen_output 0 " JBoss patch $patch failed to install !!"
								Continue
							else
								if [ "$SILENT" = "true" ]
								then
									touch $INSTALL_LOG_DIR/jbosspatch$PNUM
									echo -n "$PNUM "
									PNUM=`expr $PNUM + 1`
								fi
							fi
						fi
					done
					if [ ! -f $INSTALL_LOG_DIR/jbosspatchBZ1358913 ]
					then
						if [ -f $INSTALL_FILE_DIR/Patch/BZ-1358913.zip ]
						then
							$INSTALL_DIR/jboss-eap-6.4/bin/jboss-cli.sh --command="patch apply $INSTALL_FILE_DIR/Patch/BZ-1358913.zip" >/dev/null 2>>$ERROR
							ret=$?
							if [ $ret -ne 0 ]
							then
								Screen_output 0 " JBoss patch BZ-1358913 failed to install !!"
								Continue
							else
								if [ "$SILENT" = "true" ]
								then
									touch $INSTALL_LOG_DIR/jbosspatchBZ1358913
									echo -n "10 .... "
									echo "Done."
								fi
							fi
						fi
					fi
					touch $INSTALL_LOG_DIR/jbosspatches.log
				fi
			fi
			if [ ! -f $INSTALL_LOG_DIR/jbossstart.log ]
			then
				Jboss_startup
			fi

			if [ ! -f $INSTALL_LOG_DIR/jdbcconfig.log ]
			then
				Jdbc_config
			fi
		else
			if [ "$SILENT" = "false" ]
			then
				Screen_output 0 "Skipping the JBoss setup and installation ..."
			else
				echo " Skipping the JBoss setup and installation .... Done."
			fi
		fi
		if [ "$SILENT" = "true" ]
		then
			IBPMINSTALL=`grep "IBPMINSTALL:" $SILENT_FILE | cut -f2 -d":"` 
		else
			if [ "$JBOSSINSTALL" = "yes" ]
			then
				Screen_output 0 "Insterstage BPM installation."
				Screen_output 1 "Do you want to install Interstage BPM (y/n) ? [y] : "
				if [ "$INPUT" = "" -o "$INPUT" = "y" ]
				then
					IBPMINSTALL="yes"
				else
					IBPMINSTALL="no"
				fi
			else
				IBPMINSTALL="no"
			fi
		fi
		if [ "$IBPMINSTALL" = "no" -o "$JBOSSINSTALL" = "no" ]
		then
			if [ "$SILENT" = "false" ]
			then
				Screen_output 0 "Skipping the Interstage BPM setup and installation ..."
			else
				echo " Skipping the Interstage BPM setup and installation .... Done."
			fi
		else
			if [ ! -f $INSTALL_LOG_DIR/engineconfig.log ]
			then
				Ibpm_engine
			fi
			if [ ! -f $INSTALL_LOG_DIR/setupconfig.log ]
			then
				Setup_config
			fi
			if [ ! -f $INSTALL_LOG_DIR/ibpminstalled.log ]
			then
				Install_ibpm
			fi
			if [ ! -f $INSTALL_LOG_DIR/bpmaction.log ]
			then
				Install_bpmaction
			fi
		fi
	else
		if [ ! -f $INSTALL_LOG_DIR/flowable.log ]
		then
			Install_flowable
		fi
		if [ ! -f $INSTALL_LOG_DIR/tomcat.log ]
		then
			Install_tomcat
		fi
		if [ ! -f $INSTALL_LOG_DIR/slf.log ]
		then
			Install_slf
		fi
		if [ ! -f $INSTALL_LOG_DIR/flowablewars.log ]
		then
			Install_flowable_wars
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/webpage.log ]
	then
		Install_webpage
	fi
	if [ "$APPLICATION" = "IBPM" ]
	then
		if [ "$JBOSSVERSION" = "6.4" ]
		then
			sed -i -e 's/JBoss6.1/JBoss6.4.9/g' /var/www/html/index.html 2>>$ERROR
			sed -i -e 's/JBoss6.1/JBoss6.4.9/g' /var/www/html/appversions.html 2>>$ERROR
			sed -i -e 's/6.1/6.4/g' /var/www/html/scripts/systemstatus 2>>$ERROR
		fi
	fi
	if [ "$APPLICATION" = "IBPM" ]
	then
		if [ "$IBPMINSTALL" = "no" -o "$JBOSSINSTALL" = "no" ]
		then
			if [ "$SILENT" = "false" ]
			then
				Screen_output 0 "Skipping the WAR file installation ..."
			else
				echo " Skipping the WAR file installation .... Done."
			fi
		else
			if [ ! -f $INSTALL_LOG_DIR/warinstalled.log ]
			then
				if ls $INSTALL_FILE_DIR/options/*.war > /dev/null 2>>$ERROR
				then
					Install_war
				fi
			fi
		fi
	else
		if [ ! -f $INSTALL_LOG_DIR/warinstalled.log ]
		then
			if ls $INSTALL_FILE_DIR/options/*.war > /dev/null 2>>$ERROR
			then
				Install_war
			fi
		fi
	if [ ! -f $INSTALL_LOG_DIR/tomcatstart.log ]
	then
		Start_tomcat
	fi
	fi
	if [ "$ESKBVERSION" = "5" ]
	then
		if [ ! -f $INSTALL_LOG_DIR/jdk8installed.log ]
		then
			Install_jdk 8
		fi
	fi
	if [ "$APPLICATION" = "IBPM" ]
	then
		if [ ! -f $INSTALL_LOG_DIR/alfresco.log ]
		then
			Install_alfresco
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/elasticsearch.log ]
	then
		Install_elastic
	fi
	if [ ! -f $INSTALL_LOG_DIR/kibana.log ]
	then
		Install_kibana
	fi
	if [ "$APPLICATION" = "IBPM" ]
	then
		if [ "$KEVERSION" = "5.1.1" ]
		then
			if [ ! -f $INSTALL_LOG_DIR/kibananplugin.log ]
			then
				Install_kibanaplugin
			fi
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/esgui.log ]
	then
		Install_esgui
	fi
	if [ "$IBPMVERSION" != "4.1" ]
	then
		if [ "$ESVERSION" = "5" ]
		then
			rm -rf /etc/alternatives/java
			JAVAEXEC=`ls /usr/java/jdk1.7*/jre/bin/java`
			ln -s $JAVAEXEC /etc/alternatives/java
		fi
	fi
	if [ ! -f $INSTALL_LOG_DIR/chat.log ]
	then
		if [ ! -d $INSTALL_FILE_DIR/options/chat ]
		then
			touch $INSTALL_LOG_DIR/chat.log
		else
			Install_chat
		fi
	fi
	if [ -f $INSTALL_DIR/AgileAdapterData/Analytics.properties ]
	then
		sed -i -e "s/polling_in_seconds: 30/polling_in_seconds: 0/g" $INSTALL_DIR/AgileAdapterData/Analytics.properties
	fi
	Create_appversion
	CLEANINSTALL=`grep "CLEANINSTALL:" $SILENT_FILE | cut -f2 -d":"`
	REBOOTEND=`grep "REBOOTEND:" $SILENT_FILE | cut -f2 -d":"`
	Cleanup_install
	Last_reboot
}

Main
