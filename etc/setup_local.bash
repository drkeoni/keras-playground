#-*-bash-*-
#
# source this file
#

if [ -z "$BASH" ]; then
	echo "This file requires bash." 1>&2
	return
fi

case $OSTYPE in
darwin*)
  #
  # on OS X requires brew install coreutils
  #
  echo ${BASH_ARGV[0]}
  ROOT=$(dirname $(dirname $(greadlink -f ${BASH_ARGV[0]})))
  ;;
*)
  ROOT=$(dirname $(dirname $(readlink -f ${BASH_ARGV[0]})))
  ;;
esac

VE_DIR=ve

source $ROOT/$VE_DIR/bin/activate

export PYTHONPATH=${ROOT}${PYTHONPATH:+:$PYTHONPATH}
export PATH=$ROOT/bin${PATH:+:$PATH}
export DEPLOY_MODE=local

export PS1='(keras-playground)${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
