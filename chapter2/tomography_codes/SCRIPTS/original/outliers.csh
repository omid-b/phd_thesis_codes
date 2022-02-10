#!/bin/csh -f

echo 'Enter threshold type: 2 is proportion of error, 4 is percent to keep'
set thtype=($<)
echo 'Enter threshold value, proportion of error or percent'
set thval=($<)

set ds = `ls -F | grep "[0-9][0-9][0-9]_orig/"`
foreach d ($ds)
cd $d
excl_outl << end1
$thtype
$thval
end1
cd ..
end
