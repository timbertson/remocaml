#!/bin/bash
set -eux
gup all
export LOG_LEVEL=debug
exec ./_build/default/src/cli/remocaml.exe "$@"
