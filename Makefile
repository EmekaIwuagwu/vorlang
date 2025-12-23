# Vorlang Compiler Makefile
# OCaml-based implementation

.PHONY: all clean test docs install

# Compiler targets
OCAMLBUILD = ocamlbuild -use-ocamlfind -Is src,src/lexer,src/parser,src/ast,src/semantic,src/codegen,src/vm
SOURCES = src/lexer/lexer.mll src/parser/parser.mly src/lexer/tokens.ml src/parser/parser_util.ml src/ast/ast.ml src/semantic/semantic.ml src/codegen/codegen.ml src/vm/vm.ml src/main.ml
TARGETS = main.native main.byte

# Build the native compiler
all: $(TARGETS)

main.native: $(SOURCES)
	$(OCAMLBUILD) -r -pkg str -pkg menhirLib -pkg unix src/main.native
	mv main.native vorlang.native

main.byte: $(SOURCES)
	$(OCAMLBUILD) -r -pkg str -pkg menhirLib -pkg unix src/main.byte
	mv main.byte vorlang.byte

# Test targets
test:
	$(OCAMLBUILD) -pkg oUnit test.native
	./test.native

# Documentation
docs:
	ocamldoc -html -d docs/api $(SOURCES)

# Install
install: vorlang.native
	cp _build/src/main.native /usr/local/bin/vorlang

# Clean build artifacts
clean:
	$(OCAMLBUILD) -clean
	rm -rf _build
	rm -f vorlang.native vorlang.byte

# Run REPL
repl: vorlang.native
	./_build/src/main.native repl

# Compile a single file
compile: vorlang.native
	./_build/src/main.native compile $(FILE)

# Run a program
run: vorlang.native
	./_build/src/main.native run $(FILE)
