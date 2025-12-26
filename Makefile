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
BIN_DIR = $(PREFIX)/bin
SHARE_DIR = $(PREFIX)/share/vorlang

install: vorlangc
	@echo "📦 Installing Vorlang to $(PREFIX)..."
	mkdir -p $(BIN_DIR)
	mkdir -p $(SHARE_DIR)
	@# Copy binary
	cp vorlangc $(BIN_DIR)/vorlangc
	chmod 755 $(BIN_DIR)/vorlangc
	@# Copy StdLib and Examples
	cp -r stdlib $(SHARE_DIR)/
	cp -r examples $(SHARE_DIR)/
	@# Create 'vorlang' REPL wrapper
	@echo "#!/bin/sh" > $(BIN_DIR)/vorlang
	@echo "export VORLANG_STDLIB=$(SHARE_DIR)/stdlib" >> $(BIN_DIR)/vorlang
	@echo "$(BIN_DIR)/vorlangc repl \"\$$@\"" >> $(BIN_DIR)/vorlang
	chmod +x $(BIN_DIR)/vorlang
	@echo "✅ vorlangc and vorlang (REPL) installed successfully."

uninstall:
	@echo "🗑️  Removing Vorlang from $(PREFIX)..."
	rm -f $(BIN_DIR)/vorlangc
	rm -f $(BIN_DIR)/vorlang
	rm -rf $(SHARE_DIR)
	@echo "✨ Cleaned up."

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
