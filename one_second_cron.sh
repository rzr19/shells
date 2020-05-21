#!/bin/bash

i=0

until [ $i -eq 60 ]; do
  sleep 1
  /bin/find /nfs/path/to/move/from -type f -name "*?????*"  -exec mv '{}' /nfs/path/to/move/to \;
  ((i=i+1))
done
