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
	mv main.native vorlangc

main.byte: $(SOURCES)
	$(OCAMLBUILD) -r -pkg str -pkg menhirLib -pkg unix src/main.byte
	mv main.byte vorlangc.byte

# Test targets
test:
	$(OCAMLBUILD) -pkg oUnit test.native
	./test.native

# Documentation
docs:
	ocamldoc -html -d docs/api $(SOURCES)

# Install
install: vorlangc
	cp vorlangc /usr/local/bin/vorlangc

# Clean build artifacts
clean:
	$(OCAMLBUILD) -clean
	rm -rf _build
	rm -f vorlangc vorlangc.byte

# Run REPL
repl: vorlangc
	./vorlangc repl

# Compile a single file
compile: vorlangc
	./vorlangc compile $(FILE)

# Run a program
run: vorlangc
	./vorlangc run $(FILE)
