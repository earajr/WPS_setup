#!/bin/bash

namelist_wps_fil=$1

echo "&metgrid" >> ${namelist_wps_fil}
echo " fg_name                      = 'FILE'," >> ${namelist_wps_fil}
echo " io_form_metgrid              = 2," >> ${namelist_wps_fil}
