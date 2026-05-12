#!/bin/bash
set -e
eval "$(pixi shell-hook -s bash)"
exec jupyterhub-singleuser "$@"
