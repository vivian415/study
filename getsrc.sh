#!/usr/bin/bash

LIB=$1
SRCF=$2
MBR=$3

IFSFILE="/QSYS.LIB/${LIB}.LIB/${SRCF}.FILE/${MBR}.MBR"
OUTFILE="/tmp/${MBR}.src"

echo "=== COPY SOURCE ==="
echo "${IFSFILE}"

system "CPYTOSTMF FROMMBR('${IFSFILE}') \
TOSTMF('${OUTFILE}') \
STMFCCSID(1208) \
STMFOPT(*REPLACE)"

if [ $? -ne 0 ]; then
  echo "CPYTOSTMF ERROR"
  exit 1
fi

echo
echo "=== SOURCE HEAD ==="

head -50 "${OUTFILE}"