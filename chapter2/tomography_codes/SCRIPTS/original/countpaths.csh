foreach period (`cat list`)
set npaths = `wc -l $period/path_sel`
echo $period $npaths
end
