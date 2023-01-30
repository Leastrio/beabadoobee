#!/bin/sh

export MIX_ENV=prod

mix deps.get

mix ecto.create
mix ecto.migrate

mix release --force --overwrite

_build/prod/rel/beabadoobee/bin/beabadoobee daemon

echo "Background process started !"