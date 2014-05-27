PROJECT = export_val

include erlang.mk

ebin/%.beam: test/%.erl
	@erlc -pa ebin -o ebin $<

eunit: app ebin/export_val_test.beam
	@erl \
	  -noshell \
	  -pa ebin \
	  -eval "eunit:test($(PROJECT)_test, [verbose])" \
	  -s init stop

.PHONY: eunit
