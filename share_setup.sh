#!/bin/bash

echo -e "\n"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Welcome to the WRF FORCE preprocessing information gatherer. This will guide you through entering the information required to create a namelist.wps file."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

# Assumed variable values

wrf_core="ARW"
interval_seconds="10800"
io_form_geogrid="2"

# Create namelist.wps file
namelist_wps_fil="namelist.wps"

if [ -f "${namelist_wps_fil}" ] ; then
   rm "${namelist_wps_fil}"
fi
touch ${namelist_wps_fil}

while true; do
   echo -e "\nHow many domains do you wish to generate? (max 3 domains). "
   read ans
   if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [ ${ans} -gt 0 ] && [ ${ans} -lt 4 ];
   then
      max_dom=${ans}
      break
   else
      echo -e "\nThe number of domains you have entered is invalid, please try again."
   fi
done

simul_time_flag=1

if [ 1 -eq "$(echo "${max_dom} > 1" | bc)" ];
then
   while true; do
      echo "Do you want simulations for all domains to be initialised and end at the same time as each other? (Y/N)"
      read ans
      if [ ${ans} == "Y" ] || [ ${ans} == "y" ] || [ ${ans} == "YES" ] || [ ${ans} == "Yes" ] || [ ${ans} == "yes" ];
      then
         simul_time_flag=1
         break
      elif [ ${ans} == "N" ] || [ ${ans} == "n" ] || [ ${ans} == "NO" ] || [ ${ans} == "No" ] || [ ${ans} == "no" ];
      then
         simul_time_flag=0
         break
      else
      "The answer you gave was invalid, please try again."
      fi
   done
fi

# Does it make sense to add in additional controls to prevent people from entering historic dates or inputting dates that are too far into the future for GFS data to be available?


if [ "${simul_time_flag}" == "0" ];
then
   echo "Please enter the start date and time of the simulation for each domain."
   for i in $( seq 1 ${max_dom} )
   do
      while true; do
         if [ "${i}" == 1 ];
         then
            echo "Domain ${i} (external domain) start date and time"
         else
            echo "Domain ${i} start date and time"
         fi
         while true; do
            echo "Year (YYYY):"
            read ans
            if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [[ ${#ans} == 4 ]];
            then
               YYYY=${ans}
               break
            else
               echo "The format of the year you entered was incorrect, please retry."
            fi
         done
         while true; do
            echo "Month (MM):"
            read ans
            if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [[ ${#ans} == 2 ]] && [ 1 -eq "$(echo "${ans} > 0 && ${ans} <= 12" | bc)" ];
            then
               MM=${ans}
               break
            else
               echo "The format of the month you entered was incorrect, please retry."
            fi
         done
         max_DD=$( date -d "$MM/1 + 1 month - 1 day" "+%d")
         while true; do
            echo "Day (DD):"
            read ans
            if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [[ ${#ans} == 2 ]] && [ 1 -eq "$(echo "${ans} > 0 && ${ans} <= ${max_DD}" | bc)" ];
            then
               DD=${ans}
               break
            else
               echo "The format of the day you entered was incorrect, please retry."
            fi
         done
         echo "Please enter the start time of the simulation."
         while true; do
            echo "Hour UTC (hh):"
            read ans
            if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [[ ${#ans} == 2 ]] && [ 1 -eq "$(echo "${ans} >= 0 && ${ans} <= 23" | bc)" ];
            then
               hh=${ans}
               break
            else
               echo "The format of the hour you entered was incorrect, please retry."
            fi
         done
         while true; do
            echo "Minute (mm):"
            read ans
            if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [[ ${#ans} == 2 ]] && [ 1 -eq "$(echo "${ans} >= 0 && ${ans} <= 59" | bc)" ];
            then
               mm=${ans}
               break
            else
               echo "The format of the hour you entered was incorrect, please retry."
            fi
         done
         if [ "${i}" == 1 ];
         then
            echo "How long in hours will the simulation be for? Minimum 24 hours and maximum 96 hours."
         else
            echo "How long in hours will the simulation be for? Make sure that simulations in nested domains does not end after its parent domain."
         fi
         while true; do
            echo "Length of simulation (hours):"
            read ans
            if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [ 1 -eq "$(echo "${ans} >= 24 && ${ans} <= 96" | bc)" ];
            then
               sim_len=${ans}
               break
            else
               echo "The format of the simulation length you entered was incorrect, please retry."
            fi
         done
         if [ "${i}" == 1 ];
         then
            start_date="'${YYYY}-${MM}-${DD}_${hh}:${mm}:00',"
            end_date="'$( date -d "${hh}:${mm}:00 ${YYYY}-${MM}-${DD} +${sim_len} hours" +"%Y-%m-%d_%H:%M:%S" )' ,"
            old_YYYY=${YYYY}
            old_MM=${MM}
            old_DD=${DD}
            old_hh=${hh}
            old_mm=${mm}
            old_sim_len=${sim_len}
            break
         else
            start_diff=$(( $(date -d "${old_hh}:${old_mm}:00 ${old_YYYY}-${old_MM}-${old_DD}" +%s) - $(date -d "${hh}:${mm}:00 ${YYYY}-${MM}-${DD}" +%s) ))
            end_diff=$(( $(date -d "${old_hh}:${old_mm}:00 ${old_YYYY}-${old_MM}-${old_DD} +${old_sim_len} hours" +%s) - $(date -d "${hh}:${mm}:00 ${YYYY}-${MM}-${DD} +${sim_len} hours" +%s) ))

            if [[ 1 -eq "$(echo "${start_diff} <= 0 && ${end_diff} >= 0" | bc)" ]];    #[[ 1 -eq "$(echo "${start_diff} <= 0" | bc)" ]] && [[ 1 -eq "$(echo "${end_date_diff} >= 0" | bc)" ]];
            then
               old_YYYY=${YYYY}
               old_MM=${MM}
               old_DD=${DD}
               old_hh=${hh}
               old_mm=${mm}
               old_sim_len=${sim_len}
               start_date="${start_date} '${YYYY}-${MM}-${DD}_${hh}:${mm}:00',"
               end_date="${end_date} '$( date -d "${hh}:${mm}:00 ${YYYY}-${MM}-${DD} +${sim_len} hours" +"%Y-%m-%d_%H:%M:%S" )' ,"
               break
            else
               echo "The dates and length of simulation for domain ${i} are incompatible, please retry."
            fi
         fi
      done   
   done
else
   echo "Please enter the start date and time of the simulation."
   while true; do
      echo "Year (YYYY):"
      read ans
      if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [[ ${#ans} == 4 ]];
      then
         YYYY=${ans}
         break
      else
         echo "The format of the year you entered was incorrect, please retry."
      fi
   done
   while true; do
      echo "Month (MM):"
      read ans
      if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [[ ${#ans} == 2 ]] && [ 1 -eq "$(echo "${ans} > 0 && ${ans} <= 12" | bc)" ];
      then
         MM=${ans}
         break
      else
         echo "The format of the month you entered was incorrect, please retry."
      fi
   done
   max_DD=$( date -d "$MM/1 + 1 month - 1 day" "+%d")
   while true; do
      echo "Day (DD):"
      read ans
      if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [[ ${#ans} == 2 ]] && [ 1 -eq "$(echo "${ans} > 0 && ${ans} <= ${max_DD}" | bc)" ];
      then
         DD=${ans}
         break
      else
         echo "The format of the day you entered was incorrect, please retry."
      fi
   done   
   echo "Please enter the start time of the simulation."
   while true; do
      echo "Hour UTC (hh):"
      read ans
      if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [[ ${#ans} == 2 ]] && [ 1 -eq "$(echo "${ans} >= 0 && ${ans} <= 23" | bc)" ];
      then
         hh=${ans}
         break
      else
         echo "The format of the hour you entered was incorrect, please retry."
      fi
   done
   while true; do
      echo "Minute (mm):"
      read ans
      if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [[ ${#ans} == 2 ]] && [ 1 -eq "$(echo "${ans} >= 0 && ${ans} <= 59" | bc)" ];
      then
         mm=${ans}
         break
      else
         echo "The format of the hour you entered was incorrect, please retry."
      fi
   done
   if [ "${i}" == 1 ];
   then
      echo "How long in hours will the simulation be for? Minimum 24 hours and maximum 96 hours."
   else
            echo "How long in hours will the simulation be for? Make sure that simulations in nested domains does not end after its parent domain."
   fi
   while true; do
      echo "Length of simulation (hours):"
      read ans
      if [[ ${ans} =~ ^[+-]?[0-9]+$ ]] && [ 1 -eq "$(echo "${ans} >= 24 && ${ans} <= 96" | bc)" ];
      then
         sim_len=${ans}
         break
      else
         echo "The format of the simulation length you entered was incorrect, please retry."
      fi
   done
   for i in $( seq 1 ${max_dom} )
   do
      if [ "${i}" == 1 ];
      then
         start_date="'${YYYY}-${MM}-${DD}_${hh}:${mm}:00',"
         end_date="'$( date -d "${hh}:${mm}:00 ${YYYY}-${MM}-${DD} +${sim_len} hours" +"%Y-%m-%d_%H:%M:%S" )',"
      else
         start_date="${start_date} '${YYYY}-${MM}-${DD}_${hh}:${mm}:00',"
         end_date="${end_date} '$( date -d "${hh}:${mm}:00 ${YYYY}-${MM}-${DD} +${sim_len} hours" +"%Y-%m-%d_%H:%M:%S" )',"
      fi
   done
fi

echo "&share" >> ${namelist_wps_fil}
echo " wrf_core = '${wrf_core}'," >> ${namelist_wps_fil}
echo " max_dom = ${max_dom}," >> ${namelist_wps_fil}
echo " start_date = ${start_date}" >> ${namelist_wps_fil}
echo " end_date   = ${end_date}" >> ${namelist_wps_fil}
echo " interval_seconds = ${interval_seconds}," >> ${namelist_wps_fil}
echo " io_form_geogrid = ${io_form_geogrid}," >> ${namelist_wps_fil} 
echo "/" >> ${namelist_wps_fil}
echo "" >> ${namelist_wps_fil}

./geogrid_setup.sh ${max_dom} ${namelist_wps_fil}
