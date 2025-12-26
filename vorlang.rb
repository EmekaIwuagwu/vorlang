class Vorlang < Formula
  desc "High-performance Blockchain and Backend DSL"
  homepage "https://github.com/EmekaIwuagwu/vorlang"
  url "https://github.com/EmekaIwuagwu/vorlang/archive/refs/tags/v0.10-super.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # TODO: Update with actual checksum
  license "MIT"

  depends_on "make" => :build
  depends_on "ocaml" => :build
  depends_on "ocamlbuild" => :build
  depends_on "openssl@3"

  def install
    system "make"
    
    # Binary
    bin.install "vorlangc"
    
    # Shared files
    pkgshare.install "stdlib"
    pkgshare.install "examples"

    # Wrapper script for REPL
    (bin/"vorlang").write <<~EOS
      #!/bin/bash
      export VORLANG_STDLIB="#{pkgshare}/stdlib"
      exec "#{bin}/vorlangc" repl "$@"
    EOS
  end

  test do
    system "#{bin}/vorlangc", "version"
    # Basic smoke test in formula
    (testpath/"hello.vorlang").write 'print("hello")'
    assert_match "hello", shell_output("#{bin}/vorlangc run hello.vorlang")
  end
end
