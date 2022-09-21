#!/bin/bash

namelist_wps_fil=$1

echo "&ungrib" >> ${namelist_wps_fil}
echo "out_format = 'WPS'" >> ${namelist_wps_fil}
echo "prefix = 'FILE'" >> ${namelist_wps_fil}
echo "/" >> ${namelist_wps_fil}

./metgrid_setup.sh ${namelist_wps_fil}
