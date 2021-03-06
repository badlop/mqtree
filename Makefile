REBAR=./rebar

all: src

src:
	$(REBAR) get-deps compile

clean:
	$(REBAR) clean

distclean: clean
	rm -f config.status
	rm -f config.log
	rm -rf autom4te.cache
	rm -rf deps
	rm -rf ebin
	rm -rf priv
	rm -f vars.config
	rm -f compile_commands.json
	rm -rf dialyzer

test: all
	mkdir -p .eunit/priv/lib
	cp priv/lib/mqtree.* .eunit/priv/lib/
	$(REBAR) -v skip_deps=true eunit

xref: all
	$(REBAR) skip_deps=true xref

deps := $(wildcard deps/*/ebin)

dialyzer/erlang.plt:
	@mkdir -p dialyzer
	@dialyzer --build_plt --output_plt dialyzer/erlang.plt \
	-o dialyzer/erlang.log --apps kernel stdlib erts; \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

dialyzer/deps.plt:
	@mkdir -p dialyzer
	@dialyzer --build_plt --output_plt dialyzer/deps.plt \
	-o dialyzer/deps.log $(deps); \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

dialyzer/mqtree.plt:
	@mkdir -p dialyzer
	@dialyzer --build_plt --output_plt dialyzer/mqtree.plt \
	-o dialyzer/mqtree.log ebin; \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

erlang_plt: dialyzer/erlang.plt
	@dialyzer --plt dialyzer/erlang.plt --check_plt -o dialyzer/erlang.log; \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

deps_plt: dialyzer/deps.plt
	@dialyzer --plt dialyzer/deps.plt --check_plt -o dialyzer/deps.log; \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

mqtree_plt: dialyzer/mqtree.plt
	@dialyzer --plt dialyzer/mqtree.plt --check_plt -o dialyzer/mqtree.log; \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

dialyzer: erlang_plt deps_plt mqtree_plt
	@dialyzer --plts dialyzer/*.plt --no_check_plt \
	--get_warnings -o dialyzer/error.log ebin; \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

check-syntax:
	gcc -o nul -S ${CHK_SOURCES}

.PHONY: clean src test all dialyzer erlang_plt deps_plt mqtree_plt
