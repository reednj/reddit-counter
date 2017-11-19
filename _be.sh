#!/bin/bash

# loads rbenv and runs the script with
# bundle execs

export RBENV_ROOT="${HOME}/.rbenv"

if [ -d "${RBENV_ROOT}" ]; then
  export PATH="${RBENV_ROOT}/bin:${PATH}"
  eval "$(rbenv init -)"
fi

bundle exec ruby "$@"
