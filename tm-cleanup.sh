#!/bin/zsh
# -*- coding: utf-8; tab-width: 2; indent-tabs-mode: nil; sh-basic-offset: 2; sh-indentation: 2; -*- vim:fenc=utf-8:et:sw=2:ts=2:sts=2
#
# Copyright (C) 2014, Enrico M. Crisostomo
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
setopt localoptions
setopt localtraps
unsetopt glob_subst

set -o errexit
set -o nounset

PROGNAME=$0

(( ${EUID} == 0 )) || {
  >&2 print -- This command must be executed with super user privileges.
  exit 1
}

command -v tmutil > /dev/null 2>&1 || {
  >&2 print -- Cannot find tmutil.
  exit 1
}

print_usage()
{
  print -- "${PROGNAME}"
  print
  print -- "Usage:"
  print -- "${PROGNAME} [-d days]"
  print
  print -- "Options:"
  print -- " -d         Number of days to keep."
  print -- " -h         Show this help."
  print
  print -- "Report bugs to <enrico.m.crisostomo@gmail.com>."
}

# Define an integer variable to store the deletion threshold.
# Default: 30 days
typeset -i DAYS_TO_KEEP=30

while getopts ":hd:" opt
do
  case $opt in
    h)
      print_usage
      exit 0
      ;;
    d)
      DAYS_TO_KEEP=${OPTARG}
      ;;
    \?)
      >&2 print -- Invalid option -${OPTARG}.
      exit 1
      ;;
    :)
      >&2 print -- Missing argument to -${OPTARG}.
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

(( $# == 0 )) || {
  >&2 print -- No arguments are allowed.
  exit 2
}

(( ${DAYS_TO_KEEP} > 0 )) || {
  >&2 print -- The number of days to keep must be positive.
  exit 2
}

# Get the full list of backups from tmuil
TM_BACKUPS=( "${(ps:\n:)$(tmutil listbackups)}" )

# We are sorting the output of tmutil listbackups because its documentation
# states nowhere that the output is sorted in any way.
TM_BACKUPS_SORTED=( ${(n)TM_BACKUPS} )

# Establish the threshold date before which backups will be deleted
THRESHOLD_DATE=$(date -j -v-${DAYS_TO_KEEP}d +"%Y-%m-%d")

# As a safety precaution, just check that the output format has not changed.
# If it has, let's not proceed.
for i in ${TM_BACKUPS_SORTED}
do
  TM_DATE=$(basename $i)

  if [[ ! ${TM_DATE} =~ "^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}$" ]]
  then
    >&2 print -- Unexpected snapshot name: ${TM_DATE}.
    >&2 print -- Aborting.
    exit 8
  fi
done

for i in ${TM_BACKUPS_SORTED}
do
  TM_DATE=$(basename $i)

  if [[ ${THRESHOLD_DATE} > ${TM_DATE} ]]
  then
    if [[ ${i} != ${TM_BACKUPS_SORTED[-1]} ]]
    then
      print -- ${TM_DATE} will be deleted.
      tmutil delete ${i}
    else
      print -- ${TM_DATE} will not be deleted because it is the latest available Time Machine snapshot.
    fi
  fi
done
