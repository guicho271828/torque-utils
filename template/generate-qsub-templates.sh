#!/bin/bash

# Generate lots of qsub scripts statically

. $WORLD_HOME/util/util.sh

run=true
random=false
name=noname
root=results
while getopts ":R:n:s:r:" opt
do
    case ${opt} in
        R)  # random
            howmany=${OPTARG}
            random=true ;;
        r)  root=${OPTARG} ;;
        n)  name=${OPTARG} ;;
        s)  probset=${OPTARG} ;;
        \?) OPT_ERROR=1; break ;;
        * ) echo "unsupported option $opt" ;;
    esac
done

shift $(($OPTIND - 1))
bin=$(readlink -ef $1)
shift
args="$bin $@"

if [[ ( $1 == "" ) || $OPT_ERROR ]]
then
    cat >&2 <<EOF
usage: ./generate-qsub-templates.sh
           [-r resource]
           [-R howmany]
           [-s problemset]
           [-n name]
           args
EOF
    exit 1
fi

expdir-name (){
    pushd $1 >/dev/null
    echo -n "$(basename $(pwd))-"
    echo -n "$(basename $(git symbolic-ref HEAD))-"
    echo -n "$name-"
    echo -n "$(git --no-pager log -1 --pretty=oneline | head -c6)-"
    date +"%Y-%m-%d-%H-%M-%S"
    popd >/dev/null
}

probdir=sets/$probset
mkdir -p $root
expdir=$root/$(expdir-name $probdir)

find $probdir -name "*.pddl" -or -name "*.macro.*" | while read src ; do
    dest=$expdir${src##$probdir}
    mkdir -p $(dirname $dest)
    ln -s ../../../$src $dest
done

# git archive \
#     --format=tar \
#     --remote=$probdir \
#     --prefix=$expdir/ HEAD | tar xf - || exit 1

if $random
then
    problems=$(find $expdir -regex ".*/p[0-9]*.pddl" | sort -R | head -n $howmany)
else
    problems=$(find $expdir -regex ".*/p[0-9]*.pddl" )
fi

main (){
    for problem in $problems
    do
        problem=$PWD/$problem
        dir=$(dirname $problem)
        probname=$(basename $problem .pddl)
        outname="$probname.$name"
        qsub=${problem%.pddl}.$name.qsub
        render $args > $qsub
        chmod +x $qsub
    done
}

render (){
    if [[ -e $dir/domain.pddl ]]
    then
        domain=$dir/domain.pddl
    else
        domain=$dir/$probname-domain.pddl
    fi
    domname=$(basename $domain .pddl)
    template=$(dirname $(readlink -ef $0))/template.qsub
    cat <<EOF
#!/bin/bash
outname=$outname
dir=$dir
problem=$problem
probname=$probname
domain=$domain
domname=$domname
args="$*"
. $template
EOF
}

main
