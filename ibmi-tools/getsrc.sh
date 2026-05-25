#!/usr/bin/bash

LIB=$1
SRCF=$2
MBR=$3

IFS_DIR="/home/K4293/ifs-work/${LIB}/${SRCF}"

mkdir -p "${IFS_DIR}"

FROMFILE="/QSYS.LIB/${LIB}.LIB/${SRCF}.FILE/${MBR}.MBR"
TOFILE="${IFS_DIR}/${MBR}.rpgle"

echo "=== EXPORT SOURCE ==="
echo "FROM : ${FROMFILE}"
echo "TO   : ${TOFILE}"

system "CPYTOSTMF FROMMBR('${FROMFILE}') \
TOSTMF('${TOFILE}') \
STMFCCSID(1208) \
STMFOPT(*REPLACE)"

if [ $? -ne 0 ]; then
  echo "CPYTOSTMF ERROR"
  exit 1
fi

echo
echo "=== EXPORT COMPLETE ==="
echo "${TOFILE}"