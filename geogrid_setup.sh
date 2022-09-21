#!/bin/bash

#Function to round floats correctly including the removal of decimal points when rounding to an integer value

function round_float() {
     local digit="${2}"; [[ "${2}" =~ ^[0-9]+$ ]] || digit="0"
     LC_ALL=C printf "%.${digit}f" "${1}"
}

max_dom=$1
namelist_wps_fil=$2
temp_namelist_wps_fil="temp_${namelist_wps_fil}"

#echo -e "\n"
#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#echo "Welcome to the WRF FORCE automatic domain generator, this tool aims to construct WRF domains based on simple user input."
#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#

#for i in $( seq 1 ${max_dom} )
#do
#   if [ "${i}" == 1 ];
#   then

while true; do
   cp ${namelist_wps_fil} ${temp_namelist_wps_fil}
   parent_id="1,"
   parent_grid_ratio="1,"
   i_parent_start="1,"
   j_parent_start="1,"
   while true; do
      echo -e "\nPlease enter the Latitude and Longitude of the centre of your proposed external model domain"
      echo "Latitude:"
      read cent_lat
      echo "Longitude:"
      read cent_lon

      if [[ ${cent_lat} =~ ^[+-]?[0-9]+$  ||  ${cent_lat} =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] && [ 1 -eq "$(echo "${cent_lat} >= -90.0 && ${cent_lat} <= 90.0" | bc)" ] && [[ ${cent_lon} =~ ^[+-]?[0-9]+$ || ${cent_lon} =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]  && [ 1 -eq "$(echo "${cent_lon} >= -180.0 && ${cent_lon} <= 180.0" | bc)" ];
      then
         if [ 1 -eq "$(echo "${cent_lat} > 65.0 || ${cent_lat} < -65.0" | bc)" ];
         then
            stnd_proj_name="Polar Stereographic"
            stnd_proj="polar"
            break
         elif [ 1 -eq "$(echo "${cent_lat} <= 65.0 &&  ${cent_lat} > 25.0" | bc)" ] || [ 1 -eq "$(echo "${cent_lat} >= -65.0 &&  ${cent_lat} < -25.0" | bc)" ];
         then
            stnd_proj_name="Lambert Conformal"
            stnd_proj="lambert"
            break
         elif [ 1 -eq "$(echo "${cent_lat} <= 25.0 || ${cent_lat} >= -25.0" | bc)" ];
         then
            stnd_proj_name="Mercator"
            stnd_proj="mercator"
            break
               else
#               echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            echo  "You have not selected valid latitude or longitude values, please try again."
#               echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
         fi
      else
#            echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
         echo  "You have not selected valid latitude or longitude values, please try again."
#            echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      fi
   done
#   fi
#done

ref_lat=${cent_lat}
ref_lon=${cent_lon}

#echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
   echo "The standard projection for the latitude selected is ${stnd_proj_name}, is this correct (Y/N)" 
#echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

   read ans
   if [ ${ans} == "Y" ] || [ ${ans} == "y" ] || [ ${ans} == "YES" ] || [ ${ans} == "Yes" ] || [ ${ans} == "yes" ];
   then
      MAP_PROJ=${stnd_proj}
   else
      while true; do
         echo "Please select altenative map projection"
         echo "1. Lambert Conformal, 2. Mercator, 3. Lat-Lon, 4. Polar"
         read ans
         if [ ${ans} == "1" ];
         then
            MAP_PROJ="lambert"
            break
         elif [ ${ans} == "2" ];
         then
            MAP_PROJ="mercator"
            break
         elif [ ${ans} == "3" ];
         then
            MAP_PROJ="lat-lon"
            break
         elif [ ${ans} == "4" ];
         then
            MAP_PROJ="polar"
            break
         else
            echo "You have not selected a valid map projection, please try again."
         fi
      done
   fi
   
   if [ ${MAP_PROJ} == "polar" ] || [ ${MAP_PROJ} == "lambert" ] || [ ${MAP_PROJ} == "mercator" ];
   then
      DX_DY_unit="km"
   elif [ ${MAP_PROJ} == "lat-lon" ];
   then
      DX_DY_unit="degrees"
   fi

   while true; do
      echo -e "\nPlease indicate the grid spacing you wish to use in your external domain in ${DX_DY_unit}."
      read ans
      if [[ ${ans} =~ ^[+-]?[0-9]+$  ||  ${ans} =~ ^[+-]?[0-9]+\.?[0-9]*$ ]];
      then
         GRID_RES=${ans}
         GRID_RES_temp=${ans}
         break
      else
         echo "You have not selected a valid grid resolution, please try again."
      fi
   done

   dx=$(echo "${GRID_RES} * 1000.0" | bc -l)
   dy=$(echo "${GRID_RES} * 1000.0" | bc -l)

   if [ ${MAP_PROJ} == "polar" ];
   then
      if [ 1 -eq "$(echo "${cent_lat} == 90.0 || ${cent_lat} == -90.0" | bc)" ];
      then
         while true; do
            echo -e "\nAs you have centred your domain over a pole please select a standard longitude. This will orient your domain such that your standard longitude is positioned at the top of your domain."
            read ans
            if [[ ${ans} =~ ^[+-]?[0-9]+$  ||  ${ans} =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] && [ 1 -eq "$(echo "${ans} >= -180.0 && ${ans} <= 180.0" | bc)" ];
            then
               STAND_LON=${ans}
               break
            else
               echo "You have not selected a valid longitude value, please try again."
            fi
         done
      else
         STAND_LON=${cent_lon}
      fi
      TRUELAT1=${cent_lat}
      TRUELAT2=${cent_lat}
   else
      STAND_LON=${cent_lon}
      if [ ${MAP_PROJ} == "mercator" ];
      then
         TRUELAT1="30.0"
         TRUELAT2="30.0"
      fi
      if [ ${MAP_PROJ} == "lambert" ];
      then
         TRUELAT1=$(echo "(${cent_lat} + 5.0)" | bc -l )
         TRUELAT2=$(echo "(${cent_lat} - 5.0)" | bc -l )
      fi
   fi

# Need to edit to allow for nested domains

#echo "In this section you will choose the size of your domains"
   for i in $( seq 1 ${max_dom} )
   do
      if [ "${i}" == 1 ];
      then
         while true; do
            echo "Please choose how you will specify domain size."
            echo "1. Grid points"
            echo "2. ${DX_DY_unit}"
            read ans
            if [ 1 -eq "$(echo "${ans} == 1 || ${ans} == 2" | bc)" ];
            then
               if [ 1 -eq "$(echo "${ans} == 1" | bc)" ];
               then
                  domain_size_unit="grid points"
               elif [ 1 -eq "$(echo "${ans} == 2" | bc)" ];
               then
                  domain_size_unit=${DX_DY_unit}
               fi
               domain_size_flag=${ans}
               break
            else
               "You have not selected a valid choice, please try again."
            fi
         done
         while true; do
            echo "Input the x dimension of domain ${i} in ${domain_size_unit}."
            read ans
            if [[ ${ans} =~ ^[+-]?[0-9]+$  ||  ${ans} =~ ^[+-]?[0-9]+\.?[0-9]*$ ]];
            then
               x_dim=${ans}
               break
            else
               "You have not selected a valid x dimension, please try again."
            fi
         done
         while true; do
            echo "Input the y dimension of domain ${i} in ${domain_size_unit}."
            read ans
            if [[ ${ans} =~ ^[+-]?[0-9]+$  ||  ${ans} =~ ^[+-]?[0-9]+\.?[0-9]*$ ]];
            then
               y_dim=${ans}
               break
            else
               "You have not selected a valid x dimension, please try again."
            fi
         done
         if [ "${domain_size_flag}" == "1" ];
         then
            e_we="$( round_float ${x_dim} 0 ),"
            e_sn="$( round_float ${y_dim} 0 ),"
         else
            e_we="$( round_float $(echo "(${x_dim} / ${GRID_RES})" | bc -l ) 0 ),"
            e_sn="$( round_float $(echo "(${y_dim} / ${GRID_RES})" | bc -l ) 0 ),"
         fi
         e_we_temp=${e_we}
         e_sn_temp=${e_sn}
      else

         parent_id="${parent_id} $((${i}-1)),"
         while true; do
            while true; do
               echo "What is the grid ratio between domain ${i} and it's parent domain?"
               echo "1. Grid ratio of 3:1"
               echo "2. Grid ratio of 5:1"
               read ans
               if [ 1 -eq "$(echo "${ans} == 1 || ${ans} == 2" | bc)" ];
               then
                  if [ 1 -eq "$(echo "${ans} == 1" | bc)" ];
                  then
                     grid_ratio_temp="3,"
                  elif [ 1 -eq "$(echo "${ans} == 2" | bc)" ];
                  then
                     grid_ratio_temp="5,"
                  fi
                  GRID_RES_temp=$( echo "${GRID_RES} / ${grid_ratio_temp::-1} " | bc -l )
                  parent_grid_ratio="${parent_grid_ratio} ${grid_ratio_temp}"
                  break
               else
                  "You have not selected a valid choice, please try again."
               fi
            done
   
            echo "Please provide the x and y value of the lower left corner of domain ${i} within it's parent domain."
            echo "Select values based on the size of the parent domain (x dimension = ${e_we_temp} and y dimension = ${e_sn_temp})"
            while true; do
               echo "Lower left x position:"
               read ans
               if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [ 1 -eq "$(echo "${ans} >= 6" | bc)" ];
               then
                  i_parent_start_temp=${ans}
                  break
               else
                  "You have not selected a valid choice, please try again."
               fi
            done
            while true; do
               echo "Lower left y position:"
               read ans
               if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [ 1 -eq "$(echo "${ans} >= 6" | bc)" ];
               then
                  j_parent_start_temp=${ans}
                  break
               else
                  "You have not selected a valid choice, please try again."
               fi
            done
            while true; do
               echo "Input the x dimension of domain ${i} in ${domain_size_unit}."
               read ans
               if [[ ${ans} =~ ^[+-]?[0-9]+$  ||  ${ans} =~ ^[+-]?[0-9]+\.?[0-9]*$ ]];
               then
                  x_dim=${ans}
                  break
               else
                  "You have not selected a valid x dimension, please try again."
               fi
            done
            while true; do
               echo "Input the y dimension of domain ${i} in ${domain_size_unit}."
               read ans
               if [[ ${ans} =~ ^[+-]?[0-9]+$  ||  ${ans} =~ ^[+-]?[0-9]+\.?[0-9]*$ ]];
               then
                  y_dim=${ans}
                  break
               else
                  "You have not selected a valid y dimension, please try again."
               fi
            done
            if [ "${domain_size_flag}" == "1" ];
            then
               x_dim_temp="$( echo "($( round_float $(echo "(${x_dim} / ${grid_ratio_temp::-1})" | bc -l ) 0 ) * ${grid_ratio_temp::-1}) + 1" | bc -l )"
               y_dim_temp="$( echo "($( round_float $(echo "(${y_dim} / ${grid_ratio_temp::-1})" | bc -l ) 0 ) * ${grid_ratio_temp::-1}) + 1" | bc -l )"
            else
               x_dim_temp="$( echo "($( round_float $(echo "(${x_dim} / ${GRID_RES_temp})/${grid_ratio_temp::-1}" | bc -l) 0 ) * ${grid_ratio_temp::-1}) + 1" | bc -l )"
               y_dim_temp="$( echo "($( round_float $(echo "(${y_dim} / ${GRID_RES_temp})/${grid_ratio_temp::-1}" | bc -l) 0 ) * ${grid_ratio_temp::-1}) + 1" | bc -l )"
            fi
   
            x_limit=$( echo "((${x_dim_temp} - 1)/${grid_ratio_temp::-1}) + ${i_parent_start_temp} + 6" | bc -l )
            y_limit=$( echo "((${y_dim_temp} - 1)/${grid_ratio_temp::-1}) + ${j_parent_start_temp} + 6" | bc -l )
   
            echo ${x_limit}
            echo ${y_limit}
            echo ${e_we_temp::-1}
            echo ${e_sn_temp::-1}
   
            if [ 1 -eq "$(echo "${x_limit} <= ${e_we_temp::-1}  && ${y_limit} <= ${e_sn_temp::-1}" | bc)" ];
            then
               e_we_temp="${x_dim_temp},"
               e_sn_temp="${y_dim_temp},"
               i_parent_start="${i_parent_start} ${i_parent_start_temp},"
               j_parent_start="${j_parent_start} ${j_parent_start_temp},"
               e_we="${e_we} ${e_we_temp}"
               e_sn="${e_sn} ${e_sn_temp}"
               GRID_RES=${GRID_RES_temp}
               break
            else
               echo "The nested domain you have tried to create does not fit within its parent domain, please try again."
            fi
         done
      fi
   done

   echo "&geogrid" >> ${temp_namelist_wps_fil}
   echo " parent_id         =   ${parent_id}" >> ${temp_namelist_wps_fil}
   echo " parent_grid_ratio =   ${parent_grid_ratio}" >> ${temp_namelist_wps_fil}
   echo " i_parent_start    =   ${i_parent_start}" >> ${temp_namelist_wps_fil}
   echo " j_parent_start    =   ${j_parent_start}" >> ${temp_namelist_wps_fil}
   echo " e_we              =   ${e_we}" >> ${temp_namelist_wps_fil}
   echo " e_sn              =   ${e_sn}" >> ${temp_namelist_wps_fil}
   echo " dx = ${dx}," >> ${temp_namelist_wps_fil}
   echo " dy = ${dy}," >> ${temp_namelist_wps_fil}
   echo " map_proj = '${MAP_PROJ}'," >> ${temp_namelist_wps_fil}
   echo " ref_lat  = ${ref_lat}," >> ${temp_namelist_wps_fil}
   echo " ref_lon  = ${ref_lon}," >> ${temp_namelist_wps_fil}
   echo " truelat1 = ${TRUELAT1}," >> ${temp_namelist_wps_fil}
   echo " truelat2 = ${TRUELAT2}," >> ${temp_namelist_wps_fil}
   echo " stand_lon = ${STAND_LON}," >> ${temp_namelist_wps_fil}
   echo " geog_data_path = '/home/earajr/WPS_GEOG'" >> ${temp_namelist_wps_fil}
   echo "/" >> ${temp_namelist_wps_fil}
   echo "" >> ${temp_namelist_wps_fil}
   
   source /home/earajr/anaconda3/etc/profile.d/conda.sh
   conda activate ncl

   ncl plotgrids.ncl &> /dev/null

   display wps_show_dom.png &
   display_PID=$!
 
   echo "Are you happy with the domains as shown on screen?"
   read ans
   if [ ${ans} == "Y" ] || [ ${ans} == "y" ] || [ ${ans} == "YES" ] || [ ${ans} == "Yes" ] || [ ${ans} == "yes" ];
   then
      mv ${temp_namelist_wps_fil} ${namelist_wps_fil}
      kill ${display_PID}
      break
   else
      echo "Please re-enter domain information to improve your selected domains."
      kill ${display_PID}
      rm wps_show_dom.png 
   fi
done

./ungrib_setup.sh ${namelist_wps_fil}
