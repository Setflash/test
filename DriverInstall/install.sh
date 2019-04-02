#!/bin/sh
###############################################################################
# Part of Marvell Yukon/SysKonnect sk98lin Driver for Linux                   #
###############################################################################
# Installation script for Marvell Chip based Ethernet Gigabit Cards           #
# $Revision: 1.1.4.24 $                                                       #
# $Date: 2008/04/09 12:18:00 $                                                #
# =========================================================================== #
#                                                                             #
#  Main - Global function                                                     #
#                                                                             #
# Description:                                                                #
#  This file includes all functions and parts of the script                   #
#                                                                             #
# Returns:                                                                    #
#       N/A                                                                   #
# =========================================================================== #
# Usage:                                                                      #
#     ./install.sh                                                            #
#                                                                             #
# =========================================================================== #
# COPYRIGHT NOTICE :                                                          #
#                                                                             #
# (C)Copyright 2003-2008 Marvell(R).                                          #
#                                                                             #
#  LICENSE:                                                                   #
#  This program is free software; you can redistribute it                     # 
#  and/or modify it under the terms of the GNU General Public                 #
#  License as published by the Free Software Foundation; either               #
#  version 2 of the License, or (at your option) any later version.           #
#  /LICENSE                                                                   #
#                                                                             #
#                                                                             #
# WARRANTY DISCLAIMER:                                                        #
#                                                                             #
# THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT WITHOUT #
# ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF MERCHANTABILITY OR       #
# FITNESS FOR A PARTICULAR PURPOSE.                                           #
#                                                                             #
#                                                                             #
###############################################################################

# Check the existence of functions
if [ -f ./functions ] ; then
	. ./functions
elif [ -f /common/functions ] ; then
	. /common/functions
else
	# Error. Functions not found
	echo "An error has occurred during the check proces which prevented  "; \
	echo "the installation from completing.                              "; \
	echo "The functions file is not available.";
	echo "";
	exit 0
fi


function unpack_driver ()
{
	# Create tmp dir and unpack the driver
	# Syntax: unpack_driver 
	# Author: mlindner
	# Returns:
	#       N/A


	# Create tmp dir and unpack the driver
	cd $working_dir
	fname="Unpack the sources"
	echo -n $fname
	message_status 3 "working"

	# Archive file not found
	if [ ! -f $drv_name.tar.bz2 ]; then
		echo -en "\015"
		echo -n $fname
		message_status 0 "error"
	 	echo
		echo "Driver package $drv_name.tar.bz2 not found. "; \
		echo "Please download the package again."; \
		echo "+++ Unpack error!!!" >> $logfile 2>&1
		echo $inst_failed
		clean
		exit 1
	
	fi

	echo "+++ Unpack the sources" >> $logfile
	echo "+++ ====================================" >> $logfile
	cp $drv_name.tar.bz2 ${TMP_DIR}/

	cd ${TMP_DIR}
	bunzip2 $drv_name.tar.bz2 &> /dev/null
	echo "+++ tar xfv $drv_name.tar" >> $logfile
	tar xfv $drv_name.tar >> $logfile
	cd ..

	if [ -f ${TMP_DIR}/2.4/skge.c ]; then
		echo -en "\015"
		echo -n $fname
		message_status 1 "done"
	else
		echo -en "\015"
		echo -n $fname
		message_status 0 "error"
	 	echo
		echo "An error has occurred during the unpack proces which prevented "; \
		echo "the installation from completing.                              "; \
		echo "Take a look at the log file install.log for more informations.  "; \
		echo "+++ Unpack error!!!" >> $logfile 2>&1
		echo $inst_failed
		clean
		exit 1
	fi

	# Generate all build dir...
	mkdir ${TMP_DIR}/all
	cp -pr ${TMP_DIR}/common/* ${TMP_DIR}/all
	cp -pr ${TMP_DIR}/${KERNEL_FAMILY}/* ${TMP_DIR}/all
}


function help ()
{
	echo "Usage: install.sh [OPTIONS]"
	echo "   Install the sk98lin driver or generate a patch"
  	echo "   Example: install.sh"
	echo
	echo "Optional parameters:"
	echo "   -s              install the driver wothout any user interaction"
	echo "   -c              cleanup all sk98lin temp directories"
	echo "   -p [KERNEL_DIR] [PATCH_FILE]         generate a patch"
	echo "   -h              display this help and exit"
	echo "   -v              output version information and exit"
	echo
	echo "Report bugs to <linux@syskonnect.de>."
	exit
}

#################################################################
# Kernel 2.4 make functions
#################################################################
function create_makefile_24 ()
{
	# Create makefile (kernel 2.4 version)
	# Syntax: create_makefile_24
	# Author: mlindner
	# Returns:
	#       N/A

	if [ $IPMI_SUPPORT == "1" ]; then
		ipmi_oflags=`echo skgeasf.o skgeasfconv.o skgespi.o skgespilole.o skfops.o`;
		ipmi_cflags=`echo skgeasf.c skgeasfconv.c skgespi.c skgespilole.c skfops.c`;
		ipmi_flag=`echo -DSK_ASF`
	else
		if [ $DASH_SUPPORT == "1" ]; then
			ipmi_oflags=`echo skgeasf.o skgeasfconv.o skgespi.o skgespilole.o skfops.o`;
			ipmi_cflags=`echo skgeasf.c skgeasfconv.c skgespi.c skgespilole.c skfops.c`;
			ipmi_flag=`echo -DSK_ASF -DUSE_ASF_DASH_FW`
		else
			ipmi_oflags=""
			ipmi_cflags=""
			ipmi_flag=""
		fi
	fi

	if [ $1 == "1" ]; then
	{
	echo '# Makefile for Marvell Yukon/SysKonnect SK-98xx/SK-95xx Gigabit'
	echo '# Ethernet Adapter driver'
	echo ''
	echo '# just to get the CONFIG_SMP and CONFIG_MODVERSIONS defines:'
	echo 'ifeq ($(KERNEL_SOURCE)/.config, $(wildcard $(KERNEL_SOURCE)/.config))'
	echo 'include $(KERNEL_SOURCE)/.config'
	echo 'endif'
	echo 'SYSINC =  -I$(KERNEL_HEADER) -I.'
	echo 'SYSDEF = -DLINUX -D__KERNEL__'
	echo 'ifdef CONFIG_SMP'
	echo 'SYSDEF += -D__SMP__'
	echo 'endif'
	echo 'SRCDEF = -DMODULE -O2 -DGENESIS -DSK_DIAG_SUPPORT -DSK_USE_CSUM \'
	echo '         -DYUKON -DYUK2 -DSK_EXTREME  -DCONFIG_SK98LIN_ZEROCOPY ${ipmi_flag}'
	echo 'ifdef CONFIG_MODVERSIONS'
	echo 'SRCDEF += -DMODVERSIONS -include $(KERNEL_HEADER)/linux/modversions.h'
	echo 'SRCDEF += -include $(KERNEL_HEADER)/config/modversions.h '
	echo 'endif'
	echo 'USERDEF='
	echo 'WARNDEF=-Wall -Wimplicit -Wreturn-type -Wswitch -Wformat -Wchar-subscripts \'
	echo '	   -Wparentheses -Wpointer-arith -Wcast-qual -Wno-multichar  \'
	echo '	   -Wno-cast-qual $(MCMODEL)'
	echo 'INCLUDE= $(SYSINC)'
	echo 'DEFINES=  $(SYSDEF) $(SRCDEF) $(USERDEF) $(WARNDEF)'
	echo 'SRCFILES = skge.c kgeinit.c skgesirq.c skxmac2.c skvpd.c skgehwt.c \'
	echo '	   skqueue.c sktimer.c sktwsi.c sklm80.c skrlmt.c $ipmi_cflags skgepnmi.c \'
	echo '	   skaddr.c skcsum.c skproc.c skdim.c sky2.c skethtool.c sky2le.c'
	echo 'OBJECTS =  skge.o skaddr.o skgehwt.o skgeinit.o skgepnmi.o skgesirq.o \'
	echo '	   sktwsi.o sklm80.o skqueue.o skrlmt.o sktimer.o skvpd.o skdim.o\'
	echo '	   skxmac2.o skcsum.o skproc.o sky2.o skethtool.o ${ipmi_oflags} sky2le.o'
	echo 'DRVBIN = sk98lin.o'
	echo 'LD	= ld'
	echo "CC	= $GCCNAME"
	echo 'CFLAGS	= $(INCLUDE) $(DEFINES)'
	echo 'FILES	= $(SRCFILES) makefile'
	echo 'TARGETS	= $(DRVBIN)'
	echo '.c.o:   $<'
	echo '	$(CC) $(CFLAGS) -c $<'
	echo 'all:  $(OBJECTS)'
	echo '	$(LD) -r -o $(DRVBIN) $(OBJECTS)'
	echo 'clean:'
	echo '	rm *.o'
	echo '*.o: \'
	echo '	h/*.h'
	} &> ${TMP_DIR}/all/Makefile
	else
	cp ${TMP_DIR}/2.4/Makefile ${TMP_DIR}/all/Makefile
	fi
}

function make_driver_24 ()
{
	# Configure, check and build the driver (kernel 2.4)
	# Syntax: make_driver
	# Author: mlindner
	# Returns:
	#       N/A

	# Compile the driver
	echo >> $logfile 2>&1 
	echo "+++ Compile the driver" >> $logfile 2>&1
	echo "+++ ====================================" >> $logfile 2>&1
	cd ${TMP_DIR}/all

	fname="Compile the driver"
	echo -n $fname
	message_status 3 "working"
	make $MAKE_CPU_FLAG >> $logfile 2>&1


	if [ ! -f $drv_name.o ]; then
		echo -en "\015"
		echo -n $fname
		message_status 2 "failed"

		make_dep
		fname="Compile the driver"
		echo -n $fname
		message_status 3 "working"
		make $MAKE_CPU_FLAG >> $logfile 2>&1
	fi


	if [ -f $drv_name.o ]; then
		cp $drv_name.o ../
		echo -en "\015"
		echo -n $fname
		message_status 1 "done"
	else
		echo -en "\015"
		echo -n $fname
		message_status 0 "error"
 		echo
		echo "An error has occurred during the compile proces which prevented "; \
		echo "the installation from completing.                              "; \
		echo "Take a look at the log file install.log for more informations.  "; \
		echo "+++ Compiler error" >> $logfile 2>&1
		echo $inst_failed
		cleanup
		clean
		exit 1
	fi
}


#################################################################
# Kernel 2.6 make functions
#################################################################
function create_makefile_26 ()
{
	# Create makefile (kernel 2.6 version)
	# Syntax: create_makefile_26
	#	1 == change makefile for compilation
	#	1 != don't change
	# Author: mlindner
	# Returns:
	#       N/A


	# we have to use the makefile and change the include dir
	rm -rf ${TMP_DIR}/all/Makefile
 	if [ $1 == "1" ]; then
		rm -rf ${TMP_DIR}/all/Makefile
		local A="`echo | tr '\012' '\001' `"
		local AFirst="Idrivers/net/sk98lin"
		local ALast="I${TMP_DIR}/all"
		sed -e "s$A$AFirst$A$ALast$A" \
			${TMP_DIR}/2.6/Makefile \
			>> ${TMP_DIR}/all/Makefile
		if [ $IPMI_SUPPORT == "1" ]; then
			local IPMIFirst="# ASFPARAM += -DSK_ASF"
			local IPMILast="ASFPARAM += -DSK_ASF"
			sed -e "s$A$IPMIFirst$A$IPMILast$A" \
				${TMP_DIR}/all/Makefile \
				>> ${TMP_DIR}/all/Makefile2
			mv ${TMP_DIR}/all/Makefile2 ${TMP_DIR}/all/Makefile
		fi
		if [ $DASH_SUPPORT == "1" ]; then
			local IPMIFirst="# ASFPARAM += -DSK_ASF"
			local IPMILast="ASFPARAM += -DSK_ASF -DUSE_ASF_DASH_FW"
			sed -e "s$A$IPMIFirst$A$IPMILast$A" \
				${TMP_DIR}/all/Makefile \
				>> ${TMP_DIR}/all/Makefile2
			mv ${TMP_DIR}/all/Makefile2 ${TMP_DIR}/all/Makefile
		fi
	else
		cp ${TMP_DIR}/2.6/Makefile ${TMP_DIR}/all/Makefile
	fi

	# Insert additional informations
	if [ ${KERNEL_SUB_VERSION} ] && [ ${KERNEL_MINOR_VERSION} -eq 23 ] && [ ${KERNEL_SUB_VERSION} -gt 6 ];
		then
		addparam="${addparam} -DSK_DISABLE_PROC_UNLOAD"

		addparam="ADDPARAM +=  $addparam"
		local addparamfirst="# ADDPARAM +=" 
		sed -e "s$A$addparamfirst$A$addparam$A" \
			${TMP_DIR}/all/Makefile \
			>> ${TMP_DIR}/all/Makefile2
		cp ${TMP_DIR}/all/Makefile2 ${TMP_DIR}/all/Makefile
	fi

}

function make_driver_26 ()
{
	# Configure, check and build the driver (kernel 2.4)
	# Syntax: make_driver
	# Author: mlindner
	# Returns:
	#       N/A

	# Compile the driver
	echo >> $logfile 2>&1 
	echo "+++ Compile the driver" >> $logfile 2>&1
	echo "+++ ====================================" >> $logfile 2>&1
	cd ${TMP_DIR}/all

	fname="Compile the kernel"
	echo -n $fname
	message_status 3 "working"

	export CONFIG_SK98LIN=m
	make $MAKE_CPU_FLAG -C ${KERNEL_SOURCE}  SUBDIRS=${TMP_DIR}/all modules >> $logfile 2>&1

	if [ -f $drv_name.ko ]; then
		cp $drv_name.ko ../
		echo -en "\015"
		echo -n $fname
		message_status 1 "done"
	else
		echo -en "\015"
		echo -n $fname
		message_status 0 "error"
 		echo
		echo "An error has occurred during the compile proces which prevented "; \
		echo "the installation from completing.                              "; \
		echo "Take a look at the log file install.log for more informations.  "; \
		echo "+++ Compiler error" >> $logfile 2>&1
		echo $inst_failed
		cleanup
#		clean
		exit 1
	fi
}

function install_firmware ()
{
	# Install the firmware if available
	# Syntax: install_firmware
	# Author: mlindner
	# Returns:
	#       N/A
	echo -n "Check firmware availability"

	if [ -f ${TMP_DIR}/firmware/ipmiyk2-s1.bin ]; then
		message_status 1 "available"

		echo -n "Create /etc/sk98lin directory"
		if [ -d /etc/sk98lin ]; then
			message_status 1 "already created"
		else
			mkdir /etc/sk98lin
			message_status 1 "done"
		fi

		echo -n "Copying firmware"
		cp ${TMP_DIR}/firmware/ipmiyk2-s1.bin /etc/sk98lin/
		cp ${TMP_DIR}/firmware/ipmiyk2-s2.bin /etc/sk98lin/

		IPMI_SUPPORT=1
	else
		if [ -f ${TMP_DIR}/firmware/dashyex-s1.bin ]; then
			message_status 1 "available"

			echo -n "Create /etc/sk98lin directory"
			if [ -d /etc/sk98lin ]; then
				message_status 1 "already created"
			else
				mkdir /etc/sk98lin
				message_status 1 "done"
			fi	

			echo -n "Copying firmware"
			cp ${TMP_DIR}/firmware/dashyex-s1.bin /etc/sk98lin/
			cp ${TMP_DIR}/firmware/dashyex-s2.bin /etc/sk98lin/

			DASH_SUPPORT=1
		else
			message_status 1 "not available"
			return
		fi
	fi

	message_status 1 "done"
}


#################################################################
# Generate patch functions
#################################################################
function check_driver_sources ()
{
	# Get some infos from the driver sources dir
	# Syntax: check_driver_sources
	# Author: mlindner
	# Returns:
	#       N/A

	local verstring=`cat ${TMP_DIR}/common/h/skversion.h | grep "VER_STRING"`
	DRIVER_VERSION=`echo $verstring | cut -d '"' -f 2`
	verstring=`cat ${TMP_DIR}/common/h/skversion.h | grep "DRIVER_REL_DATE"`
	DRIVER_REL_DATE=`echo $verstring | cut -d '"' -f 2`
}


function check_headers_for_patch ()
{
	# Get some infos from the Makefile
	# Syntax: check_headers_for_patch
	# Author: mlindner
	# Returns:
	#       N/A

	local mainkernel
	local patchkernel
	local sublevelkernel

	# Check header files
	if [ -d $KERNEL_SOURCE ]; then
		export KERNEL_SOURCE=$KERNEL_SOURCE
	else
		echo
		echo "An error has occurred during the patch proces which prevented "; \
		echo "the installation from completing.                              "; \
		echo "Directory $KERNEL_SOURCE not found!.  "; \
		echo $inst_failed
		cleanup
		clean
		exit 1
	fi

	if [ -f $KERNEL_SOURCE/Makefile ]; then
		export KERNEL_SOURCE=$KERNEL_SOURCE
	else
		echo
		echo "An error has occurred during the patch proces which prevented "; \
		echo "the installation from completing.                              "; \
		echo "Makefile in the directory $KERNEL_SOURCE not found!.  "; \
		echo $inst_failed
		cleanup
		clean
		exit 1
	fi


	# Get main version
	local mainversion=`grep "^VERSION =" $KERNEL_SOURCE/Makefile`
	local vercount=`echo $mainversion | wc -c`
	if [ $vercount -lt 1 ]; then
		mainversion=`grep "^VERSION=" $KERNEL_SOURCE/Makefile`
	fi
	mainkernel=`echo $mainversion | cut -d '=' -f 2 | sed -e "s/ //g"`

	# Get patchlevel
	local patchlevel=`grep "^PATCHLEVEL =" $KERNEL_SOURCE/Makefile`
	vercount=`echo $patchlevel | wc -c`
	if [ $vercount -lt 1 ]; then
		patchlevel=`grep "^PATCHLEVEL=" $KERNEL_SOURCE/Makefile`
	fi
	patchkernel=`echo $patchlevel | cut -d '=' -f 2 | sed -e "s/ //g"`

	# Get sublevel
	local sublevel=`grep "^SUBLEVEL =" $KERNEL_SOURCE/Makefile`
	vercount=`echo $sublevel | wc -c`
	if [ $vercount -lt 1 ]; then
		sublevel=`grep "^SUBLEVEL=" $KERNEL_SOURCE/Makefile`
	fi
	sublevelkernel=`echo $sublevel | cut -d '=' -f 2 | sed -e "s/ //g"`

	# Version checks
	if [ $mainkernel != 2 ]; then
		kernel_check_failed
	fi

	if [ $patchkernel != 4 ] && [ $patchkernel != 6 ]; then
		kernel_check_failed
	fi

	if [ "$sublevelkernel" -lt  20 ] && [ $patchkernel == 4 ]; then
		kernel_check_failed
	fi

	KERNEL_VERSION=`echo "$mainkernel.$patchkernel.$sublevelkernel"`
	KERNEL_FAMILY=`echo "$mainkernel.$patchkernel"`
	KERNEL_MINOR_VERSION=$sublevelkernel
	KERNEL_MAJOR_VERSION=$patchkernel
}


function check_system_for_patch ()
{
	# Get some infos from host
	# Syntax: check_system_for_patch
	# Author: mlindner
	# Returns:
	#       N/A

	# Check kernel version

	export KERNEL_VERSION=`uname -r`	
	split_kernel_ver=`echo ${KERNEL_VERSION} | cut -d '.' -f 1`

	KERNEL_FAMILY="$split_kernel_ver"
	split_kernel_ver=`echo ${KERNEL_VERSION} | cut -d '.' -f 2`
	KERNEL_FAMILY="$KERNEL_FAMILY.$split_kernel_ver"

	split_kernel_ver=`echo ${KERNEL_VERSION} | cut -d '.' -f 3`
	split_kernel_ver2=`echo $split_kernel_ver | cut -d '-' -f 1`
	KERNEL_MINOR_VERSION=`echo $split_kernel_ver2`
	KERNEL_MAJOR_VERSION=`echo ${KERNEL_VERSION} | cut -d '.' -f 2`

	# Check header files
	if [ -d /usr/src/linux/include/linux/ ]; then
		export KERNEL_SOURCE="/usr/src/linux";
	else
		if [ -d /usr/src/linux-${KERNEL_VERSION}/include/linux/ ]; then
			export KERNEL_SOURCE="/usr/src/linux-${KERNEL_VERSION}";
		else
			kernel_check_dir="linux-$KERNEL_FAMILY"
			if [ -d /usr/src/$kernel_check_dir/include/linux/ ]; then
				export KERNEL_SOURCE="/usr/src/$kernel_check_dir";
			fi
   		fi
	fi

}

function get_patch_infos ()
{
	# Interactive formular
	# Syntax: get_patch_infos
	# Author: mlindner
	# Returns:
	#       N/A

	if [ ! ${INSTALL_AUTO} ]; then
		PS3='Choose your favorite installation method: ' # Sets the prompt string.
		echo -n "Kernel source directory (${KERNEL_SOURCE}) : "
		read kernel_source_in
		if [ "$kernel_source_in" != "" ]; then
			KERNEL_SOURCE=$kernel_source_in
		fi
	fi

	# Check the headers
	check_headers_for_patch

	# Check driver version
	check_driver_sources

	if [ ! ${INSTALL_AUTO} ]; then
		drvvertmp=`echo $DRIVER_VERSION | sed -e "s/ //g"`
		PATCH_NAME="$working_dir/sk98lin_v"
		PATCH_NAME="$PATCH_NAME$drvvertmp"
		PATCH_NAME="${PATCH_NAME}_${KERNEL_VERSION}_patch"

		echo -n "Patch name ($PATCH_NAME) : "
		read patch_name_in

		if [ "$patch_name_in" != "" ]; then
			case "$patch_name_in" in
			/*)
				PATCH_NAME="$patch_name_in"
			;;
			*)
				PATCH_NAME="$working_dir/$patch_name_in"
                       esac
		fi
	fi
}


function generate_patch_for_help24 ()
{
	# Generate a patch for the config file
	# Syntax: generate_patch_for_help24
	#	package_root, kernel_root
	# Author: mlindner
	# Returns:
	#       N/A
	fname="Generate Config.help patch"
	echo -n $fname
	message_status 3 "working"
	local packagedir="$1"
	local kerneldir=$2
	local startline
	local totalline
	local splitline
	local count=0
	local splt=0
	local A="`echo | tr '\012' '\001' `"

	# initial cleanup
	rm -rf ${TMP_DIR}/all_sources_patch

	# find the first line of the sk block
	startline=`grep "CONFIG_SK98LIN$" $kerneldir/Documentation/Configure.help -n | cut -d ':' -f 1`
	totalline=`cat $kerneldir/Documentation/Configure.help | wc -l`
	((startline=$startline - 2))
	((splitline=$totalline - $startline))
	((splitline=$splitline - 2))

	head -n $startline $kerneldir/Documentation/Configure.help > ${TMP_DIR}/Configure.help
	cat $packagedir/misc/Configure.help >> ${TMP_DIR}/Configure.help
	tail -n $splitline $kerneldir/Documentation/Configure.help > ${TMP_DIR}/Configuretemp

	# find the end of the block	
	while read line; do
		((count=$count + 1))
		splt=`echo $line | grep CONFIG_ -c`
		if [ $splt -gt 0 ]; then break; fi
	done < ${TMP_DIR}/Configuretemp
	((count=$count - 2))
	((splitline=$splitline - $count))
	tail -n $splitline $kerneldir/Documentation/Configure.help >> ${TMP_DIR}/Configure.help

	# Make diff
	diff -ruN $kerneldir/Documentation/Configure.help ${TMP_DIR}/Configure.help \
		> ${TMP_DIR}/all_sources_patch
	replacement="linux-new/Documentation"
	sed -e "s$A${TMP_DIR}$A$replacement$A" \
		${TMP_DIR}/all_sources_patch &> ${TMP_DIR}/all_sources_patch2
	replacement="linux"
	sed -e "s$A$kerneldir$A$replacement$A" \
		${TMP_DIR}/all_sources_patch2 &> ${TMP_DIR}/all_sources_patch


	# Complete the patch
	if [ -f ${TMP_DIR}/all_sources_patch ] && \
		[ `cat ${TMP_DIR}/all_sources_patch | wc -c` -gt 0 ]; then
		echo "diff -ruN linux/Documentation/Configure.help \
linux-new/Documentation/Configure.help" >> ${PATCH_NAME}
		cat ${TMP_DIR}/all_sources_patch >> ${PATCH_NAME}
	fi

	# Status
	echo -en "\015"
	echo -n $fname
	message_status 1 "done"
}


function generate_patch_for_config24 ()
{
	# Generate a patch for the config file
	# Syntax: generate_patch_for_config
	#	package_root, kernel_root
	# Author: mlindner
	# Returns:
	#       N/A
	fname="Generate Config.in patch"
	echo -n $fname
	message_status 3 "working"
	local packagedir="$1"
	local kerneldir=$2
	local startline
	local totalline
	local splitline
	local count=0
	local splt=0
	local A="`echo | tr '\012' '\001' `"

	# find the first line of the sk block
	startline=`grep "CONFIG_SK98LIN " $kerneldir/drivers/net/Config.in -n | cut -d ':' -f 1`
	totalline=`cat $kerneldir/drivers/net/Config.in | wc -l`


	((startline=$startline - 1))
	((splitline=$totalline - $startline))
	((splitline=$splitline - 1))
	head -n $startline $kerneldir/drivers/net/Config.in > ${TMP_DIR}/Config.in

	# Insert a new description
	echo "dep_tristate 'Marvell Yukon Chipset / SysKonnect SK-98xx Support' CONFIG_SK98LIN \$CONFIG_PCI" >> ${TMP_DIR}/Config.in
	echo 'if [ "$CONFIG_SK98LIN" != "n" ]; then' >> ${TMP_DIR}/Config.in
	echo "	bool '    Use Rx polling (NAPI)' CONFIG_SK98LIN_NAPI" >> ${TMP_DIR}/Config.in
	echo "fi" >> ${TMP_DIR}/Config.in

	tail -n $splitline $kerneldir/drivers/net/Config.in > ${TMP_DIR}/Config.intemp

	# find the end of the block	
	while read line; do
		((count=$count + 1))
		splt=`echo $line | grep "^dep_tristate"  -c`
		if [ $splt -gt 0 ]; then break; fi
	done < ${TMP_DIR}/Config.intemp
	((count=$count - 1))
	((splitline=$splitline - $count))
	tail -n $splitline $kerneldir/drivers/net/Config.in >> ${TMP_DIR}/Config.in

	# Make diff
	diff -ruN $kerneldir/drivers/net/Config.in ${TMP_DIR}/Config.in \
		> ${TMP_DIR}/all_sources_patch
	replacement="linux-new/drivers/net"
	sed -e "s$A${TMP_DIR}$A$replacement$A" \
		${TMP_DIR}/all_sources_patch &> ${TMP_DIR}/all_sources_patch2
	replacement="linux"
	sed -e "s$A$kerneldir$A$replacement$A" \
		${TMP_DIR}/all_sources_patch2 &> ${TMP_DIR}/all_sources_patch

	# Complete the patch
	if [ -f ${TMP_DIR}/all_sources_patch ] && \
		[ `cat ${TMP_DIR}/all_sources_patch | wc -c` -gt 0 ]; then
		echo "diff -ruN linux/drivers/net/Config.in \
linux-new/drivers/net/Config.in" >> ${PATCH_NAME}
		cat ${TMP_DIR}/all_sources_patch >> ${PATCH_NAME}
	fi


	# Status
	echo -en "\015"
	echo -n $fname
	message_status 1 "done"
}


function generate_patch_for_kconfig26 ()
{
	# Generate a patch for the config file (kernel 2.6.x)
	# Syntax: generate_patch_for_kconfig26
	#	package_root, kernel_root
	# Author: mlindner
	# Returns:
	#       N/A
	fname="Generate Kconfig patch"
	echo -n $fname
	message_status 3 "working"

	local packagedir="$1"
	local kerneldir=$2
	local startline
	local totalline
	local splitline
	local count=0
	local splt=0
	local A="`echo | tr '\012' '\001' `"

	# find the first line of the sk block
	startline=`grep "SK98LIN$" $kerneldir/drivers/net/Kconfig -n | grep -v "depends" | cut -d ':' -f 1`
	totalline=`cat $kerneldir/drivers/net/Kconfig | wc -l`
	((startline=$startline - 1))
	((splitline=$totalline - $startline))
	((splitline=$splitline - 2))
	head -n $startline $kerneldir/drivers/net/Kconfig > ${TMP_DIR}/Kconfig
	cat $packagedir/misc/Kconfig >> ${TMP_DIR}/Kconfig
	tail -n $splitline $kerneldir/drivers/net/Kconfig > ${TMP_DIR}/Kconfigtemp

	# find the end of the block	
	while read line; do
		((count=$count + 1))
		splt=`echo $line | grep "^config"  -c`
		if [ $splt -gt 0 ]; then break; fi
	done < ${TMP_DIR}/Kconfigtemp
	((count=$count - 2))
	((splitline=$splitline - $count))
	tail -n $splitline $kerneldir/drivers/net/Kconfig >> ${TMP_DIR}/Kconfig

	# Make diff
	diff -ruN $kerneldir/drivers/net/Kconfig ${TMP_DIR}/Kconfig \
		> ${TMP_DIR}/all_sources_patch
	replacement="linux-new/drivers/net"
	sed -e "s$A${TMP_DIR}$A$replacement$A" \
		${TMP_DIR}/all_sources_patch &> ${TMP_DIR}/all_sources_patch2
	replacement="linux"
	sed -e "s$A$kerneldir$A$replacement$A" \
		${TMP_DIR}/all_sources_patch2 &> ${TMP_DIR}/all_sources_patch


	# Complete the patch
	echo "diff -ruN linux/drivers/net/Kconfig \
linux-new/drivers/net/Kconfig" >> ${PATCH_NAME}
	cat ${TMP_DIR}/all_sources_patch >> ${PATCH_NAME}

	# Status
	echo -en "\015"
	echo -n $fname
	message_status 1 "done"
}


function generate_patch_for_readme ()
{
	# Generate a patch for the readme file
	# Syntax: generate_patch_for_readme
	#	package_root, kernel_root
	# Author: mlindner
	# Returns:
	#       N/A

	fname="Generate readme patch"
	echo -n $fname
	message_status 3 "working"
	local packagedir="$1/all"
	local kerneldir=$2
	local replacement
	local A="`echo | tr '\012' '\001' `"

	# initial cleanup
	rm -rf ${TMP_DIR}/all_sources_patch

	# Make diff
	diff -ruN $kerneldir/Documentation/networking/sk98lin.txt $packagedir/sk98lin.txt \
		> ${TMP_DIR}/all_sources_patch
	replacement="linux-new/drivers/net/sk98lin"
	sed -e "s$A$packagedir$A$replacement$A" \
		${TMP_DIR}/all_sources_patch &> ${TMP_DIR}/all_sources_patch2
	replacement="linux"
	sed -e "s$A$kerneldir$A$replacement$A" \
		${TMP_DIR}/all_sources_patch2 &> ${TMP_DIR}/all_sources_patch


	# Complete the patch
	
	if [ -f ${TMP_DIR}/all_sources_patch ] && \
		[ `cat ${TMP_DIR}/all_sources_patch | wc -c` -gt 0 ]; then
		echo "diff -ruN linux/Documentation/networking/sk98lin.txt \
linux-new/Documentation/networking/sk98lin.txt" >> ${PATCH_NAME}
		cat ${TMP_DIR}/all_sources_patch >> ${PATCH_NAME}
	fi

	# Status
	echo -en "\015"
	echo -n $fname
	message_status 1 "done"
}

function generate_patch_file ()
{
	# Generate a patch for a specific kernel version
	# Syntax: generate_patch_file
	#	package_root, kernel_root
	# Author: mlindner
	# Returns:
	#       N/A

	fname="Kernel version"
	echo -n $fname
	message_status 1 "${KERNEL_VERSION}"

	fname="Driver version"
	echo -n $fname
	message_status 1 "$DRIVER_VERSION"

	fname="Release date"
	echo -n $fname
	message_status 1 "$DRIVER_REL_DATE"

	# Check if some kernel functions are available
	check_kernel_functions

	fname="Generate driver patches"
	echo -n $fname
	message_status 3 "working"
	local packagedir="$1/all"
	local kerneldir=$2
	local replacement
	local line=`echo "-x '\*.\[o4\]' -x '.\*' -x '\*.ko' -x '\*.txt' -x '\*.htm\*' "`
	local A="`echo | tr '\012' '\001' `"

	diff -ruN -x "*.[o4]" -x ".*" -x "*.ko" -x "*.txt" -x "*.htm*" \
		$kerneldir/drivers/net/sk98lin $packagedir > ${TMP_DIR}/all_sources_patch
	replacement="linux-new/drivers/net/sk98lin"
	sed -e "s$A$packagedir$A$replacement$A" \
		${TMP_DIR}/all_sources_patch &> ${TMP_DIR}/all_sources_patch2
	replacement="linux"
	sed -e "s$A$kerneldir$A$replacement$A" \
		${TMP_DIR}/all_sources_patch2 &> ${TMP_DIR}/all_sources_patch
	replacement=`echo ""`
	sed -e "s$A$line$A$A" \
		${TMP_DIR}/all_sources_patch &> ${PATCH_NAME}

	# Status
	echo -en "\015"
	echo -n $fname
	message_status 1 "done"
}


function patch_generation ()
{
	# Generate a patch for a specific kernel version
	# Syntax: patch_generation
	# Author: mlindner
	# Returns:
	#       N/A

	# Check system
	check_system_for_patch

	# Generate safe tmp dir
	make_safe_tmp_dir

	# Create tmp dir and unpack the driver
	unpack_driver
	clear

	# Get user infos
	get_patch_infos

	# Copy files
	cp -pr ${TMP_DIR}/common/* ${TMP_DIR}/all
	cp -pr ${TMP_DIR}/${KERNEL_FAMILY}/* ${TMP_DIR}/all

	# Create makefile
	[ $KERNEL_FAMILY == "2.4" ] && create_makefile_24 0
	[ $KERNEL_FAMILY == "2.6" ] && create_makefile_26 0
	clear

	# Generate a patch for a specific kernel version
	generate_patch_file ${TMP_DIR} $KERNEL_SOURCE

	# Generate a patch for the readme file
	generate_patch_for_readme ${TMP_DIR} $KERNEL_SOURCE

	# Generate a patch for the config file
	if [ "${KERNEL_FAMILY}" == "2.4" ]; then
		generate_patch_for_config24 ${TMP_DIR} $KERNEL_SOURCE
	else
		generate_patch_for_kconfig26 ${TMP_DIR} $KERNEL_SOURCE
	fi

	# Generate a patch for the config file
	if [ "${KERNEL_FAMILY}" == "2.4" ]; then
		generate_patch_for_help24 ${TMP_DIR} $KERNEL_SOURCE
	fi


	# Clear the tmp dirs
	clean

	if [ ! -f ${PATCH_NAME} ] || \
		[ `cat ${PATCH_NAME} | wc -c` == 0 ]; then
		rm -rf ${PATCH_NAME}
		echo
		echo "Patch not generated."
		echo "The sources already installed on the system in the directory "
		echo "     $KERNEL_SOURCE"
		echo "are equal to the sources from the install package."
		echo "This implies that it makes not sense to create the patch, "
		echo "because it'll be of size zero!"
		echo "Don't worry, this is not a failure. It just means, that you"
		echo "already use the latest driver version." 
		echo 
		echo "                                                     Have fun..."

		exit
		
	else
		echo
		echo "All done. Patch successfully generated."
		echo "To apply the patch to the system, proceed as follows:"
		echo "      # cd $KERNEL_SOURCE"
		echo "      # cat ${PATCH_NAME} | patch -p1"
		echo 
		echo "                                                     Have fun..."
		exit
	fi
}




#################################################################
# Main functions
#################################################################
function start_sequence ()
{
	# Print copyright informations, mode selection and check
	# Syntax: start_sequence
	# Author: mlindner
	# Returns:
	#       N/A

	# Start. Choose a installation method and check method
	echo 
	echo "Installation script for $drv_name driver."
	echo "Version $VERSION"
	echo "(C)Copyright 2003-2008 Marvell(R)."
	echo "===================================================="
	echo "Add to your trouble-report the logfile install.log"
	echo "which is located in the  DriverInstall directory."
	echo "===================================================="
	echo 

	# Silent option. Return...
	[ "$OPTION_SILENT" ] && return
	[ "$INSTALL_AUTO" ] && patch_generation


	PS3='Choose your favorite installation method: ' # Sets the prompt string.

	echo

	select user_sel in "installation" "generate patch" "exit"
	do
		break  # if no 'break' here, keeps looping forever.
	done

	if [ "$user_sel" == "exit" ]; then
		echo "Exit."
		exit
	fi

	if [ "$user_sel" != "installation" ] && [ "$user_sel" != "expert installation" ] && [ "$user_sel" != "generate patch" ]; then
		echo "Exit."
		exit
	fi

	clear

	if [ "$user_sel" == "installation" ]; then
		echo "Please read this carfully!"
		echo
		echo "This script will automatically compile and load the $drv_name"
		echo "driver on your host system. Before performing both compilation"
		echo "and loading, it is necessary to shutdown any device using the" 
		echo "$drv_name kernel module and to unload the old $drv_name kernel "
		echo "module. This script will do this automatically per default."
		echo " "
		echo "Please plug a card into your machine. Without a card we aren't"
		echo "able to check the full driver functionality."
		echo
		echo -n "Do you want proceed? (y/N) "

		old_tty_settings=$(stty -g)		# Save old settings.
		stty -icanon
		Keypress=$(head -c1)
		stty "$old_tty_settings"			# Restore old terminal settings.
		echo "+++ Install mode: User" >> $logfile 2>&1
		echo "+++ Driver version: $VERSION" >> $logfile 2>&1

		if [ "$Keypress" == "Y" ]
		then
			clear
		else
			if [ "$Keypress" == "y" ]
			then
				clear
			else
				echo "Exit"
				clean
				exit 0
			fi
		fi
		
		export REMOVE_SKDEVICE=1

	else
		if [ "$user_sel" == "expert installation" ]; then
			INSTALL_MODE="INSTALL"
			echo "+++ Install mode: Expert" >> $logfile 2>&1
			clear
		else
			clear
			INSTALL_MODE="PATCH"
			patch_generation
		fi
	fi
}

function main_global ()
{
	# Main function
	# Syntax: patch_generation
	# Author: mlindner
	# Returns:
	#       N/A

	# Extract all given parameters
	extract_params $*

	# Run given functions
	if [ "${OPTION_HELP}" ]; then help; fi
	if [ "${OPTION_SILENT}" ]; then user_sel=`echo user`; fi
	if [ "${OPTION_CLEANUP}" ]; then clean; exit 0; fi
	if [ "${OPTION_PATCH}" ]; then
		INSTALL_MODE="PATCH"
		INSTALL_AUTO=1
		KERNEL_SOURCE=$2
		if [ `echo $3 | grep -c "/"` gt 0 ]; then
			PATCH_NAME=$3
		else
			PATCH_NAME=${working_dir}/$3
		fi
	fi

	# Print copyright informations, mode selection and check
	start_sequence

	# Check alternative driver availibility
	check_alt_driver

	# Generate safe tmp dir
	make_safe_tmp_dir

	# Check user informations and tools availability
	check_user_and_tools

	# Check kernel and module informations
	check_kernel_informations

	# Check config files
	generate_config

	# Check if modpost is available
	check_modpost

	# Create tmp dir and unpack the driver
	unpack_driver

	# Install firmware if available
	install_firmware

	# Create makefile
	[ $KERNEL_FAMILY == "2.4" ] && create_makefile_24 1
	[ $KERNEL_FAMILY == "2.6" ] && create_makefile_26 1

	# Check and generate a correct version.h file
	generate_sources_version

	# Check if some kernel functions are available
	check_kernel_functions


	# Configure, check and build the driver
	[ $KERNEL_FAMILY == "2.4" ] && make_driver_24
	[ $KERNEL_FAMILY == "2.6" ] && make_driver_26 1

	# Copy driver
	copy_driver

}


# Start
#####################################################################

drv_name=`echo sk98lin`
VERSION=`echo "10.61.3.3 (Jul-07-2008)"`
#drv_name=`echo sk98lin`
working_dir=`pwd`
logfile="$working_dir/install.log"
rm -rf $logfile &> /dev/null
trap cleanup_trap INT TERM
KERNEL_TREE_MAKE=0;
ALT_OPTION_FLAG=0
ALT_OPTION=0
IPMI_SUPPORT=0
DASH_SUPPORT=0
clear

# Run main function
main_global $*

# Exit
exit 0

