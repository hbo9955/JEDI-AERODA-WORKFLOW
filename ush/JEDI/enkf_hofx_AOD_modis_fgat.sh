#!/bin/ksh
set -x

JEDIcrtm=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/
WorkDir=${DATA:-$pwd/hofx_aod.$$}
RotDir=${ROTDIR:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/}
ObsDir=${COMIN_OBS:-./}
validtime=${CDATE:-"2001010100"}
nexttime=$($NDATE $assim_freq $CDATE)
nexttimem3=$($NDATE -3 $nexttime)
nexttimep3=$($NDATE 3 $nexttime)
cdump=${CDUMP:-"gdas"}
itile=${itile:-1}
mem=${imem:-0}
fgatfixdir=${HOMEgfs}/fix/fix_fgat/
#sensorID=${sensorID:-"Pass sensorID falied"};

if [[ 0 -eq 1 ]]; then
HOMEgfs=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow/
#JEDIcrtm=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/
JEDIcrtm=Data/Little_Endian/
WorkDir=./hofx_aod
#RotDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_C96_C96_M20_jedi3denvar_yesFRP_testBkgOutput_201606/dr-data/
RotDir=Data
#ObsDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/dataSets/NNR_AOD_Obs/2016Case/thinned_C192/
ObsDir=Data
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate 
validtime=2016060318
assim_freq=6
nexttime=$($NDATE $assim_freq $validtime)
nexttimem3=$($NDATE -3 $nexttime)
nexttimep3=$($NDATE 3 $nexttime)
cdump="gdas"
itile=-1
mem=0
#cdump=gdas
#itile=6
#mem=20
fi

nrm="/bin/rm -rf"
ncp="/bin/cp -r"
nln="/bin/ln -sf"

mkdir ${WorkDir}

CRTMFix=${JEDIcrtm}

if [[ ${mem} -gt 0 ]]; then
   cdump="enkfgdas"
   memdir="mem"`printf %03d $mem`
elif [[ ${mem} -eq -1 ]]; then
   cdump="enkfgdas"
   memdir="ensmean"
elif [[ ${mem} -eq 0 ]]; then
   cdump="gdas"
   memdir=""
fi


vyy=$(echo $validtime | cut -c1-4)
vmm=$(echo $validtime | cut -c5-6)
vdd=$(echo $validtime | cut -c7-8)
vhh=$(echo $validtime | cut -c9-10)
#vdatestr="${vyy}${vmm}${vdd}.${vhh}0000"
vdatestr="${vyy}-${vmm}-${vdd}T${vhh}:00:00Z"

nyy=$(echo $nexttime | cut -c1-4)
nmm=$(echo $nexttime | cut -c5-6)
ndd=$(echo $nexttime | cut -c7-8)
nhh=$(echo $nexttime | cut -c9-10)
#ndatestr="${nyy}${nmm}${ndd}.${nhh}0000"
ndatestr="${nyy}-${nmm}-${ndd}T${nhh}:00:00Z"
ndatestr1="${nyy}${nmm}${ndd}.${nhh}0000"

nm3yy=$(echo $nexttimem3 | cut -c1-4)
nm3mm=$(echo $nexttimem3 | cut -c5-6)
nm3dd=$(echo $nexttimem3 | cut -c7-8)
nm3hh=$(echo $nexttimem3 | cut -c9-10)
#ndatestr="${nyy}${nmm}${ndd}.${nhh}0000"
nm3datestr="${nm3yy}-${nm3mm}-${nm3dd}T${nm3hh}:00:00Z"


cd ${WorkDir}
if [  -d "${WorkDir}/RESTART" ]; then
   $nrm ${WorkDir}/RESTART
fi

mkdir -p ${WorkDir}/RESTART
$nln ${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART/*.fv_core.res.*nc.ges ${WorkDir}/RESTART/
$nln ${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART/*.fv_tracer.res.*.nc.ges ${WorkDir}/RESTART/
$nln ${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART/*.coupler.res.ges ${WorkDir}/RESTART/

inputdir=RESTART
outputdir=${RotDir}/${cdump}.${nyy}${nmm}${ndd}/${nhh}/${memdir}/hofx
obsin_terra=${ObsDir}/nnr_terra.${nexttime}.nc
obsin_aqua=${ObsDir}/nnr_aqua.${nexttime}.nc

mkdir -p ${outputdir}

bkgfreq=${FGAT3D_freq}
rm -rf ${WorkDir}/bkgtmp.info
if [[ ${FGAT3D_onlyCenter} == "TRUE" ]]; then
   bkgtimest=${nexttime}
   bkgtimeed=${nexttime}
else
   bkgtimest=${nexttimem3}
   bkgtimeed=${nexttimep3}
fi
while [ ${bkgtimest} -le ${bkgtimeed} ]; do
   bkgyy=$(echo $bkgtimest | cut -c1-4)
   bkgmm=$(echo $bkgtimest | cut -c5-6)
   bkgdd=$(echo $bkgtimest | cut -c7-8)
   bkghh=$(echo $bkgtimest | cut -c9-10)
   bkgdatestr="${bkgyy}-${bkgmm}-${bkgdd}T${bkghh}:00:00Z"
   bkgdatestr1="${bkgyy}${bkgmm}${bkgdd}.${bkghh}0000"
   
   echo "  - date: '${bkgdatestr}'" >> ${WorkDir}/bkgtmp.info
   echo "    filetype: gfs"        >> ${WorkDir}/bkgtmp.info
   echo "    datapath_tile: ${inputdir}" >> ${WorkDir}/bkgtmp.info
   echo "    filename_core: ${bkgdatestr1}.fv_core.res.nc.ges" >> ${WorkDir}/bkgtmp.info
   echo "    filename_trcr: ${bkgdatestr1}.fv_tracer.res.nc.ges" >> ${WorkDir}/bkgtmp.info
   echo "    filename_cplr: ${bkgdatestr1}.coupler.res.ges" >> ${WorkDir}/bkgtmp.info
   echo '    variables: ["T","DELP","sphum","sulf","bc1","bc2","oc1","oc2","dust1","dust2","dust3","dust4","dust5","seas1","seas2","seas3","seas4"]' >> ${WorkDir}/bkgtmp.info
   bkgtimest=$($NDATE ${bkgfreq} $bkgtimest)
done

bkgfiles=`cat ${WorkDir}/bkgtmp.info`

rm -rf ${WorkDir}/enkf_hofx_AOD_modis_fgat.yaml
cat << EOF > ${WorkDir}/enkf_hofx_AOD_modis_fgat.yaml
Assimilation Window:
  window_begin: '${nm3datestr}'
  window_length: PT6H
Geometry:
  nml_file_mpp: ${fgatfixdir}/fv3files/fmsmpp.nml
  nml_file: ${fgatfixdir}/fv3files/input_gfs_c12.nml
  trc_file: ${fgatfixdir}/fv3files/field_table
  pathfile_akbk: ${WorkDir}/RESTART/${ndatestr1}.fv_core.res.nc.ges
  Levels: 64
  FieldSets:
    - FieldSet: ${fgatfixdir}/fieldsets/dynamics.yaml
    - FieldSet: ${fgatfixdir}/fieldsets/aerosols_gfs.yaml
    - FieldSet: ${fgatfixdir}/fieldsets/ufo.yaml
Forecasts:
  state:
${bkgfiles}
Observations:
  ObsTypes:
  - ObsSpace:
      name: Aod
      ObsDataIn:
        obsfile: ${obsin_terra}
      ObsDataOut:
        obsfile: ${outputdir}/aod_nnr_terra_hofx_fgat.nc4.ges
      simulate:
        variables: [aerosol_optical_depth]
        channels: 4
    ObsOperator:
      name: Aod
      Absorbers: [H2O,O3]
      ObsOptions:
        Sensor_ID: v.modis_terra
        EndianType: little_endian
        CoefficientPath: ${CRTMFix}
        AerosolOption: aerosols_gocart_default
    Covariance:
      covariance: diagonal
  - ObsSpace:
      name: Aod
      ObsDataIn:
        obsfile: ${obsin_aqua}
      ObsDataOut:
        obsfile: ${outputdir}/aod_nnr_aqua_hofx_fgat.nc4.ges
      simulate:
        variables: [aerosol_optical_depth]
        channels: 4
    ObsOperator:
      name: Aod
      Absorbers: [H2O,O3]
      ObsOptions:
        Sensor_ID: v.modis_aqua
        EndianType: little_endian
        CoefficientPath: ${CRTMFix}
        AerosolOption: aerosols_gocart_default
    Covariance:
      covariance: diagonal
Prints:
  frequency: PT3H
EOF

