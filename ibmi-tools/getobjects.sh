#!/usr/bin/bash

LIB=$1

system "DSPOBJD OBJ(${LIB}/*ALL) OBJTYPE(*FILE)"