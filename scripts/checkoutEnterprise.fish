#!/usr/bin/env fish
set -l mirror

if test -d /mirror/enterprise.git
  set mirror --reference-if-able /mirror/enterprise.git
end

eval $SCRIPTSDIR/checkoutArangoDB.fish
and cd $INNERWORKDIR/ArangoDB
and git config --global http.postBuffer 524288000
and if test ! -d enterprise/.git
  rm -rf enterprise
end
and if test ! -d enterprise
  echo == (date) == started clone 'enterprise'
  and git clone --progress $mirror ssh://git@github.com/arangodb/enterprise
  and echo == (date) == finished clone 'enterprise'
  and if test -d /mirror/enterprise.git
    cd enterprise
    and git repack -a
  end
end
