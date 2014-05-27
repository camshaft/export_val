-module(export_val).

-export([parse_transform/2]).
-export([rewrite_body/4]).

parse_transform(Forms, _Opts) ->
  DefVals = get_def_vals(Forms, []),
  ExportedForms = export_vals(Forms, DefVals),
  replace_fns(ExportedForms, DefVals, []).

get_def_vals([], Acc) ->
  Acc;
get_def_vals([{attribute, _, export_val, Funs}|Forms], Acc) ->
  get_def_vals(Forms, [{Fun, 0} || {Fun, 0} <- Funs] ++ Acc);
get_def_vals([_|Forms], Acc) ->
  get_def_vals(Forms, Acc).

export_vals([File,Mod|Forms], DefVals) ->
  [File,Mod] ++ [{attribute,1,export,[Fun]} || Fun <- DefVals] ++ Forms.

replace_fns([], _, Acc) ->
  lists:reverse(Acc);
replace_fns([Fun = {function, Line, Name, Arity, Clauses}|Forms], Vals, Acc) ->
  case lists:member({Name, Arity}, Vals) of
    true ->
      Clauses2 = [rewrite_body(Line, Name, Arity, Body) || Body <- Clauses],
      Fun2 = {function, Line, Name, Arity, Clauses2},
      replace_fns(Forms, Vals, [Fun2|Acc]);
    _ ->
      replace_fns(Forms, Vals, [Fun|Acc])
  end;
replace_fns([Form|Forms], Vals, Acc) ->
  replace_fns(Forms, Vals, [Form|Acc]).

-define(CALL(Line,Module,Fun,Args), {call,Line,{remote,Line,{atom,Line,Module},{atom,Line,Fun}},Args}).

rewrite_body(Line, Name, Arity, {clause, ClauseLine, Args, Guards, Body}) ->
  Hash = integer_to_list(erlang:phash2({Name, Arity, Args, Guards, Body})),
  Mod = list_to_atom("export_val_$$" ++ Hash),
  Val = list_to_atom("EXPORT_VAL_VAL$$" ++ Hash),
  Bin = list_to_atom("EXPORT_VAL_BIN$$" ++ Hash),

  ModDef = cons([
    {tuple,Line,[
      {atom,Line,attribute},
      {integer,Line,1},
      {atom,Line,file},
      {tuple,Line,[{string,Line,[]},{integer,Line,1}]}]},
    {tuple,Line,[
      {atom,Line,attribute},
      {integer,Line,1},
      {atom,Line,module},
      {atom,Line,Mod}]},
    {tuple,Line,[
      {atom,Line,attribute},
      {integer,Line,1},
      {atom,Line,export},
      cons([
        {tuple,Line,[{atom,Line,value},{integer,Line,0}]}
      ])]},
    {tuple,Line,[
      {atom,Line,function},
      {integer,Line,1},
      {atom,Line,value},
      {integer,Line,0},
      cons([
        {tuple,Line,[
          {atom,Line,clause},
          {integer,Line,1},
          {nil,Line},
          {nil,Line},
          cons([
            ?CALL(Line,erl_parse,abstract,[{var,Line,Val}])
          ])
        ]}
      ])]},
    {tuple,Line,[{atom,Line,eof},{integer,Line,1}]}
  ]),

  CreateMod = [
    {match,Line,
      {var,Line,Val},
      {block,Line,Body}},
    {match,Line,
      {tuple,Line,[
        {atom,Line,ok},
        {var,Line,'_'},
        {var,Line,Bin}]},
      ?CALL(Line,compile,forms,[ModDef])},
    ?CALL(Line,code,load_binary, [
      {atom,Line,Mod},
      {string,Line,[]},
      {var,Line,Bin}
    ]),
    {var,Line,Val}
  ],

  TryCatch = [
    {'try',Line,
      [?CALL(Line,Mod,value,[])],
      [],
      [{clause,Line,
        [{tuple,Line,[{var,Line,'_'},{var,Line,'_'},{var,Line,'_'}]}],
        [],
        CreateMod}],
      []
    }
  ],

  {clause, ClauseLine, Args, Guards, TryCatch}.

cons(List) ->
  cons(lists:reverse(List), {nil, 1}).

cons([], Acc) ->
  Acc;
cons([Item|Rest], Acc) ->
  cons(Rest, {cons, 1, Item, Acc}).
