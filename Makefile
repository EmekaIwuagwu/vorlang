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

# --- Installation & Uninstallation ---
PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/vorlang

install: vorlangc
	mkdir -p $(BINDIR)
	mkdir -p $(SHAREDIR)
	cp vorlangc $(BINDIR)/vorlangc
	cp -r stdlib $(SHAREDIR)/
	cp -r examples $(SHAREDIR)/
	@echo "#!/bin/sh" > $(BINDIR)/vorlang
	@echo "export VORLANG_STDLIB=$(SHAREDIR)/stdlib" >> $(BINDIR)/vorlang
	@echo "$(BINDIR)/vorlangc repl \"\$$@\"" >> $(BINDIR)/vorlang
	chmod +x $(BINDIR)/vorlang
	@echo "✅ Installed to $(PREFIX)"

uninstall:
	rm -f $(BINDIR)/vorlangc
	rm -f $(BINDIR)/vorlang
	rm -rf $(SHAREDIR)
	@echo "🗑️  Uninstalled from $(PREFIX)"

# --- Packaging ---
VERSION = 1.0.0
maintainer = "Emeka Iwuagwu <emeka@vorlang.org>"

deb: vorlangc
	mkdir -p vorlang-$(VERSION)/DEBIAN
	mkdir -p vorlang-$(VERSION)$(BINDIR)
	mkdir -p vorlang-$(VERSION)$(SHAREDIR)
	cp vorlangc vorlang-$(VERSION)$(BINDIR)/
	cp -r stdlib vorlang-$(VERSION)$(SHAREDIR)/
	cp -r examples vorlang-$(VERSION)$(SHAREDIR)/
	echo "Package: vorlang\nVersion: $(VERSION)\nSection: lang\nPriority: optional\nArchitecture: amd64\nMaintainer: $(maintainer)\nDescription: High-performance Blockchain DSL" > vorlang-$(VERSION)/DEBIAN/control
	dpkg-deb --build vorlang-$(VERSION)
	rm -rf vorlang-$(VERSION)

rpm: vorlangc
	# Requires rpmbuild tools and a .spec file
	if [ -f vorlang.spec ]; then rpmbuild -ba vorlang.spec; else echo "Error: vorlang.spec not found"; exit 1; fi
