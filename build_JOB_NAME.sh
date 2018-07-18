#!/bin/sh -xvf

#Usage: build.sh <clientname>
################################################################

#set the Environment
export JAVA_HOME=/ngsitops/tools/wls1035/jrockit-jdk1.6.0_29
export PATH=$PATH:$JAVA_HOME/bin
export ANT_HOME=/ngsitops/tools/wls1035/modules/org.apache.ant_1.7.1
export PATH=$PATH:$ANT_HOME/bin
alias p4=/ngsitops/tools/p4
export PATH=$PATH:/ngsitops/tools/p4
export P4USER=ngsitsync
export P4PASSWD=syncngsit
export P4PORT=itp4prd.corp.netapp.com:1818
HOME=/ngsitops/apps/xterra/build

#. /ngsitops/tools/wls1035/wlserver_10.3/server/bin/setWLSEnv.sh


#check if argument is given
if [  $# -ne 1  ]
then
    echo "Client name is not given: Please give client name"
    echo "Usage:  build.sh <clientname> "
    exit 1
fi

P4CLIENT=$1
if [  ${P4CLIENT} == "cmode_bu"  ];then
 echo "Building for Xterra-cmode branch"
 RELEASE=asupput_xterra_cmode
 echo BRANCH=Xterra_cmode
elif [ ${P4CLIENT} == "ASUP_Releases_devbuild" ];then
  echo "Building for ASUP_Releases branch"
 RELEASE=asupput_asup_releases
  echo BRANCH=asup_releases
elif [ ${P4CLIENT} == "xterra_dev_build"  ];then
   echo "Building for xterra_r3"
   RELEASE=isfput_r3
   ENVSET=envset.sh
   echo BRANCH=xterra_r3
elif [ ${P4CLIENT} == "xterra_r4_build"  ];then
   echo "Building for xterra_r4"
   RELEASE=isfput_r4
   ENVSET=r4.envset.sh
   echo BRANCH=xterra_r4
elif [ ${P4CLIENT} == "xterra_asupreleases_build"  ];then
   echo "Building for asup_releases"
   RELEASE=isfput_asupreleases
   ENVSET=asupreleases.envset.sh
   echo BRANCH=asup_releases
elif [ ${P4CLIENT} == "xterra_hdc_build"  ];then
   echo "Building for xterra_hdc"
   RELEASE=isfput_hdc
   ENVSET=hdc.envset.sh
   echo BRANCH=xterra_hdc
elif [ ${P4CLIENT} == "xterra_r1_build"  ];then
   echo "Building for r1"
   RELEASE=isfput_r1
   ENVSET=r1.envset.sh
   echo BRANCH=r1
elif [ ${P4CLIENT} == "xterra_asupprod_build"  ];then
   echo "Building for asupprod"
   RELEASE=isfput_asupprod
   ENVSET=asupprod.envset.sh
   echo BRANCH=asupprod
elif [ ${P4CLIENT} == "xterra_r2_build"  ];then
   echo "Building for r2"
   RELEASE=isfput_r2
   ENVSET=r2.envset.sh
   echo BRANCH=r2

else
    echo "This build ${P4CLIENT} is NOT supported"
exit
fi

echo ${RELEASE}
source ${HOME}/${ENVSET}

#set the P4CLIENT
export P4CLIENT=$1
echo "P4CLIENT is set to:" ${P4CLIENT}
P4WSROOT=`p4 client -o ${P4CLIENT}  | grep ^Root | cut -d: -f2`
echo "P4WSROOT is" ${P4WSROOT}
PROJNAME=` p4 client -o ${P4CLIENT} | grep "//depot" | head -1|  awk '{print $2}' | cut -d/ -f4 `
echo "PROJNAME is" ${PROJNAME}
PROJDEPOPATH=` p4 client -o ${P4CLIENT} | grep "//depot" | head -1|  awk '{print $1}' `
echo "PROJDEPOPATH is" ${PROJDEPOPATH}
 cd ${P4WSROOT}
# rm -rf ${PROJNAME}

 p4 sync  ${PROJDEPOPATH}
 cd ${PROJNAME}/src/webapps/ISFPut

TODAYDATE=`date +%b%d%Y`
APPVER=`ls ${P4WSROOT}/../Releases | grep ${RELEASE}  | grep ${TODAYDATE} | cut -d"." -f2| sort | tail -1 `

if [ ${APPVER} ]; then
     APPVER=`expr ${APPVER} + 1`
 else
      APPVER=0
 fi

echo ${APPVER}

  ant -f isfputbuild.xml -v publish -Dversion=${APPVER} | tee build.txt
#  ant -f isfputbuild.xml -v tarfile  -Dversion=${APPVER} | tee build.txt


 TARFILEPATH=`find  ${P4WSROOT}/${PROJNAME}/src/webapps/ISFPut/ISFPut-EAR/dist | grep \.tar$`

echo ${TARFILEPATH}
TARFILE=`basename ${TARFILEPATH}`
echo ${TARFILE}

   cp ${TARFILEPATH} ${P4WSROOT}/../Releases
