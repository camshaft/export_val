-module(export_val_test).
-compile({parse_transform,export_val}).

-include_lib("eunit/include/eunit.hrl").

-export_val([get/0]).

get() ->
  ok = application:ensure_started(crypto),
  ok = application:ensure_started(asn1),
  ok = application:ensure_started(public_key),
  ok = application:ensure_started(ssl),
  ok = application:ensure_started(inets),
  {ok, Res} = httpc:request("https://google.com"),
  Res.

get_test() ->
  {First, Value} = timer:tc(fun get/0),
  ?assert(First > 1000),
  {Second, Value} = timer:tc(fun get/0),
  ?assert(Second < 5),
  {Third, Value} = timer:tc(fun get/0),
  ?assert(Third < 5).
