FROM hexpm/elixir:1.14.4-erlang-25.3-alpine-3.17.2

ARG MIX_ENV
ARG MIX_HOME=/root/.mix

ENV APP_ROOT=/marvin/
ENV MIX_HOME=${MIX_HOME}

RUN if [ "$MIX_ENV" != "" ] ; then export MIX_ENV=${MIX_ENV} ; fi

WORKDIR ${APP_ROOT}

COPY mix.exs mix.lock ${APP_ROOT}

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get

COPY . ${APP_ROOT}

RUN mix compile
