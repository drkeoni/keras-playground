#
# Makefile to simplify common tasks for working with keras playground
#
SHELL:=/bin/bash -o pipefail
VE_DIR:=ve

PKG_NAME:=keras-playground

NOSE_OPTS:=--with-xunit --with-doctest --detailed-errors --xunit-file=tests/nosetests.xml

ACTIVATE:=${VE_DIR}/bin/activate

_:=$(shell mkdir -p logs)

help:
	@echo "  Type make setup to install ${PKG_NAME} into the virtualenv"

#
# 05.11.18 JMS - this recipe had worked for six years, but seems to be running into
# trouble now in my Mac OS X environment.  Switching to python 3.6 best practices
#
#create-ve: FORCE
#	[[ -d ${VE_DIR} ]] || ( \
#	  echo "[INFO] Bootstrap installing virtualenv"	&& \
#	  ./etc/bootstrap_virtualenv.bash && \
#	  py-env0/bin/virtualenv ${VE_DIR} 2>&1 && \
#	  rm -rf py-env0 )

create-ve: FORCE
	[[ -d ${VE_DIR} ]] || ( \
	  echo "[INFO] Bootstrap installing virtualenv"	&& \
          python3 -m venv ${VE_DIR} && \
          . ${ACTIVATE} && \
	  pip install --upgrade pip && \
	  pip install wheel )

setup: logs/setup.log

logs/setup.log: etc/requirements.txt
	. ${ACTIVATE} && pip3 ${PIP_OPTS} install -r $(word 1,$^) 2>&1 | tee "$@.err"
	/bin/mv "$@.err" "$@"

test: FORCE
	( [[ -z "${DEPLOY_MODE}" ]] && echo "[ERROR] Missing DEPLOY_MODE, need to source environment first" ) || \
	  nosetests ${NOSE_OPTS}

cleanest: FORCE
	rm -rf ${VE_DIR}
	rm -f logs/*

rebuild-ve: cleanest create-ve logs/setup.log

.PHONY: FORCE help create-ve setup test cleanest rebuild-ve
