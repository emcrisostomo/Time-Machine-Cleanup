#!/bin/zsh
# -*- coding: utf-8; tab-width: 2; indent-tabs-mode: nil; sh-basic-offset: 2; sh-indentation: 2; -*- vim:fenc=utf-8:et:sw=2:ts=2:sts=2
#
# Copyright (C) 2015, Grey Systems
# All rights reserved.
#
# Unauthorized copy and distribution of this file is strictly prohibited.
#
setopt localoptions
setopt localtraps
unsetopt glob_subst

set -o errexit
set -o nounset

(( ${EUID} == 0 )) || {
  >&2 print -- This command must be executed with super user privileges.
  exit 1
}

CONFIG_FILE=$(dirname $0)/install.conf

[[ -r ${CONFIG_FILE} ]] || {
  >&2 print -- Cannot find ${CONFIG_FILE}.
  exit 2
}

. ${CONFIG_FILE}

INSTALL_DIR_FOUND=0

for p in ${path}
do
  if [[ ${p} == ${INSTALL_DIR} ]]
  then
    INSTALL_DIR_FOUND=1
    break
  fi
done

(( ${INSTALL_DIR_FOUND} > 0 )) || {
  >&2 print -- WARNING: ${INSTALL_DIR} is not part of the path.
}

for script in ${SCRIPTS}
do
  SCRIPT_NAME=${script:t}
  SCRIPT_TGT=${INSTALL_DIR}/${SCRIPT_NAME}

  if [[ -L ${SCRIPT_TGT} ]]
  then
    rm ${SCRIPT_TGT}
  fi
done
