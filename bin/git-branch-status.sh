#!/bin/bash
# hosted at   https://gist.github.com/Mark-Booth/5058384
# forked from https://gist.github.com/lth2h/4177524 @ ae184f1 by mark.booth
# forked from https://gist.github.com/jehiah/1288596 @ e357c1e by lth2h
# ideas from https://github.com/kortina/bakpak/blob/master/bin/git-branches-vs-origin-master

# this prints out some branch status
# (similar to the '... ahead' info you get from git status)
 
# example:
# $ git branch-status -a
# dns_check (ahead 1) | (behind 112) origin/master
# master (ahead 2) | (behind 0) origin/master
# $ git branch-status
# master (ahead 2) | (behind 0) origin/master

OPTIONS='hamvb:s:lru:'
usage="$(basename "$0") ["$OPTIONS"] -- Summarise status of branch(es)
Where:
    -h          shows this help text
    -a          shows all local branches, not just the current one
    -m          shows branch(es) with respect to origin/master
    -v          verbose, show output even if counts are zero
    -b BRANCH   shows branch(es) with respect to a given branch
    -s FROM/TO  shows branch(es) with respect to a branch substitution
                Note: Any branches which don't match FROM will be ignored
    -l          shows only when the left/local side is ahead (push needed)
    -r          shows only when the right/remote side is ahead (pull needed)
    -u UPSTREAM selects an upstream other than origin for -b and -m options
For example
    $(basename "$0") -am             # Show all branches which are ahead
                                      # of or behind their origin/master.
    $(basename "$0") -b 8.38-hotfix  # Show each repo whose checked out
                                      # branch is behind the hotfix branch.
    $(basename "$0") -s 8.34/8.36    # Show all 8.34 branches which are
                                      # ahead of or behind their 8.38 remote.
"

while getopts $OPTIONS option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    a) filter=refs/heads
       ;;
    m) upstreambranch=master
       ;;
    v) verbose=true
       ;;
    b) upstreambranch=$OPTARG
       ;;
    s) remotesubstitute=$OPTARG
       ;;
    l) aheadonly=true
       ;;
    r) behindonly=true
       ;;
    u) upstream=$OPTARG
       ;;
    :) echo "Option -$OPTARG requires an argument." >&2
       echo "$usage" >&2
       exit 1
       ;;
    ?) printf "Invalid option: -$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

[ $filter ] || filter=$(git symbolic-ref -q HEAD)
[ $upstream ] || upstream=origin

git for-each-ref --format="%(refname:short) %(upstream:short)" $filter | \
while read local remote
do
    if [ $remotesubstitute ] ; then
        remote=$(echo $remote | sed "s/${remotesubstitute}/")
    elif [ $upstreambranch ] ; then
        remote=$upstream/$upstreambranch
    fi
    [ "$remote" ] || continue
    [ "$(git ls-remote . $remote)" ] || continue
    DELTAS=$(git rev-list --left-right ${local}...${remote} --)
    LEFT_AHEAD=$(echo "$DELTAS" | grep -c '^<')
    RIGHT_AHEAD=$(echo "$DELTAS" | grep -c '^>')
    if [ -z $aheadonly ] && [ -z $behindonly ] ; then
        if [ $LEFT_AHEAD -gt 0 ] || [ $RIGHT_AHEAD -gt 0 ] || [ $verbose ] ; then
            echo "$local (ahead $LEFT_AHEAD) | (behind $RIGHT_AHEAD) $remote"
        fi
    elif [ $aheadonly ] ; then
        if [ $LEFT_AHEAD -gt 0 ] || [ $verbose ] ; then
            echo "$local (ahead $LEFT_AHEAD) | $remote"
        fi
    elif [ $behindonly ] ; then
        if [ $RIGHT_AHEAD -gt 0 ] || [ $verbose ] ; then
            echo "$local | (behind $RIGHT_AHEAD) $remote"
        fi
    else
         printf "Specifying both -l and -r makes no sense" >&2
         echo "$usage" >&2
         exit 1
    fi
done
