FROM bitwalker/alpine-elixir:1.14 as build

COPY config config
COPY lib lib
COPY priv priv
COPY mix.exs mix.exs
COPY mix.lock mix.lock

RUN export MIX_ENV=prod && \
    mix deps.get && \
    mix release

RUN mkdir /export && \
    cp -r _build/prod/rel/beabadoobee/ /export

FROM bitwalker/alpine-elixir:1.14

RUN mkdir -p /opt/app
COPY --from=build /export/ /opt/app

USER default

CMD ["sh", "-c", "beabadoobee/bin/beabadoobee eval \"Beabadoobee.migrate\" && beabadoobee/bin/beabadoobee start"]