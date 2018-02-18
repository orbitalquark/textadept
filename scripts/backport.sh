#!/bin/sh
# Scintilla backport utility.
# Interactively prompts for patches to backport.

cd ../src/scintilla

tip=`hg log | head -n1 | awk '{print $2}' | cut -d: -f1`
if [ -z "$1" ]; then
  last=`ls -r ../scintilla_backports/*.patch|head -n1|cut -d/ -f3|cut -d_ -f1`
  last=`expr $last + 1`
else
  last=$1
fi
for rev in `seq $last $tip`; do
  # Show revision information.
  echo Revision: $rev
  echo Message : `hg export -r $rev | grep -v "^#" -m1`
  echo Files:
  hg export -r $rev | grep "^diff" | cut -d ' ' -f6 | sed -e 's/^/\t/'
  # Prompt with action.
  read -p "Attempt dry-run patch? [y/n/m/q] " input
  if [ "$input" = "m" ]; then
    # Show more revision information.
    hg export -r $rev
    read -p "Attempt dry-run patch? [y/n/q] " input
  fi;
  case $input in
  y)
    # Apply patch (dry run).
    hg export -r $rev | patch -p1 --dry-run
    read -p "Add patch to backports? [y/n/m/q] " input
    if [ "$input" = "m" ]; then
      # Show more revision information.
      hg export -r $rev
      read -p "Add patch to backports? [y/n/e/q] " input
      while [ "$input" = "e" ]; do
        if [ -z "`ls /tmp/$rev_*.patch 2>/dev/null`" ]; then
          hg export -o "/tmp/%R_%h.patch" $rev
        fi
        ta -n -f /tmp/$rev_*.patch \
          -e "textadept.editing.strip_trailing_spaces=false"
        cat /tmp/$rev_*.patch | patch -p1 --dry-run
        read -p "Add patch to backports? [y/n/e/q] " input
      done
    fi;
    case $input in
      y)
        # Add patch to '../scintilla_backports' and update 'revs' file.
        if [ -z "`ls /tmp/$rev_*.patch 2>/dev/null`" ]; then
          hg export -r $rev | patch -p1
          hg export -o "../scintilla_backports/%R_%h.patch" $rev
        else
          mv /tmp/$rev_*.patch ../scintilla_backports/
        fi
        hash=`hg export -r $rev | grep -m1 "Node" | cut -d ' ' -f4 | head -c12`
        line=`hg export -r $rev | grep -v "^#" -m1`
        echo "$hash $line" >> ../scintilla_backports/revs
        echo "Added ../scintilla_backports/$rev_$hash.patch"
        echo "$hash $line";;
      n)
        rm -f /tmp/$rev_*.patch;;
        # continue to next revision
      *)
        rm -f /tmp/$rev_*.patch
        echo Quitting
        exit 0;;
    esac;;
  n)
    ;; # continue to next revision
  *)
    echo Quitting
    exit 0;;
  esac
  echo -------------------------------------------------------------------------
done
