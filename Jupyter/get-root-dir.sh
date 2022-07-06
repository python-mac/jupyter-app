#!/bin/zsh -l

# I'm not very good with shell, sorry

config="$(jupyter --config-dir)/jupyter_notebook_config.py"

if [ -f "$config" ]; then
    line=$(grep "^c.NotebookApp.notebook_dir" $config | tail -1)

    # if the kine with notebook is found in the config file
    if [ "$line" != "" ]; then
        # find start and quote type
        for (( i=26; i<${#line}; i++ )); do
            ch="${line:$i:1}"

            if [ "$ch" = \" ]; then
                quote=\"
                start=$((i + 1))
                break
            fi

            if [ "$ch" = \' ]; then
                quote=\'
                start=$i
                break
            fi
        done

        # find end
        for (( i=${#line}; i>$start; i-- )); do
            ch="${line:$i:1}"

            if [ "$ch" = "$quote" ]; then
                end=$i
                break
            fi
        done
        
        root=${line:$start:$(($end-$start))}
    else
        root=$HOME
    fi

else 
    root=$HOME
fi

# check for the last '/'
if [ "${root:$((${#root}-1)):1}" = "/" ]; then
    root="${root:0:$((${#root}-1))}"
fi

echo $root
