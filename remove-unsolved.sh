#!/bin/bash

# find -name "*.qsub" | while read line; do
#     dir=$(dirname $line)
#     name=$(basename $line .qsub)
#     plan=$name.*.plan.1
#     ! ls $dir/$plan &>/dev/null && {
#         # ./set1-lisp-compatible-mp-3-1-1107-rg-fa4c8e-2016-01-19-01-29/pipesworld-tankage/p31.mp-3-1-1107-rg.14400.2000000.out
#         echo "*/$(basename $dir)/${name%%.*}*"
#     }
# done


# ./set1-lisp-compatible-mp-3-1-1107-rg-fa4c8e-2016-01-19-01-29/pipesworld-tankage/p31.mp-3-1-1107-rg.14400.2000000.out.plan.1

per-dir-problem (){
    find $1 -name "*.qsub" | while read line ; do
        domain=$(basename $(dirname $line))
        problem=$(basename $line | cut -d. -f1)
        echo $domain/$problem
    done | sort
}

per-dir (){
    echo investigating: $1 >&2
    find $1 -name "*.plan.1" | while read line ; do
        domain=$(basename $(dirname $line))
        problem=$(basename $line | cut -d. -f1)
        echo $domain/$problem
    done | sort
}
export -f per-dir

# SHELL=$(type -p bash) parallel par-dir ::: $@

rec (){
    case $# in
        2) comm -1 -2 <(per-dir $1) <(per-dir $2) ;;
        1) per-dir $1 ;;
        0) echo ;;
        *)
            # $# >= 3
            half=$(($#/2))                                  # 5 -> 2
            args1="$f $(echo $@ | cut -d' ' -f1-$half)"     # -f1-2
            args2="$(echo $@ | cut -d' ' -f$((half+1))-)"    # -f3-
            comm -1 -2 <(rec $args1) <(rec $args2) ;;
    esac
}
export -f rec

[ -z $1 ] && {
    echo remove-unsolved.sh [DIRECTORIES...]
    exit 1
}

comm -1 -3 <(rec $@) <(per-dir-problem $1) | while read line ; do echo "*/$line*" ; done
