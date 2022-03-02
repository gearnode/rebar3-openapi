%% Copyright (c) 2022 Exograd SAS.
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
%% SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
%% IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(rebar3_openapi_generate).

-export([init/1, do/1, format_error/1]).

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
  Provider =
    providers:create([{name, generate},
                      {namespace, openapi},
                      {module, ?MODULE},
                      {bare, true},
                      {deps, [{default, app_discovery}]},
                      {opts, []},
                      {example,
                       "rebar3 openapi generate"},
                      {short_desc,
                       "Generate files based on OpenAPI v3 specification."},
                      {desc,
                       "Generate files based on OpenAPI v3 specification."}]),
  {ok, rebar_state:add_provider(State, Provider)}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
  Config = rebar_state:get(State, openapi, []),

  SpecificationFile =
    case maps:find(specification_file, Config) of
      {ok, Value} ->
        Value;
      error ->
        rebar_utils:abort("openapi error: missing specification_file configuration key", [])
    end,

  PackageName =
    case maps:find(package_name, Config) of
      {ok, V1} when is_list(V1) ->
        iolist_to_binary(V1);
      {ok, V2} when is_binary(V2) ->
        V2;
      {ok, _} ->
        rebar_utils:abort("openapi error: invalid package_name configuration key", []);
      _ ->
        rebar_utils:abort("openapi error: missing package_name configuration key", [])
    end,

  OutputDir = maps:get(output_dir, Config, "src"),
  Options = #{language => erlang,
              generator => client,
              default_host => maps:get(default_host, Config, <<>>),
              package_name => PackageName},

  case openapi:generate(SpecificationFile, OutputDir, Options) of
    ok ->
      {ok, State};
    {error, Reason} ->
      rebar_utils:abort("openapi error: ~p~n", [Reason])
  end.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
  io_lib:format("~p", [Reason]).
