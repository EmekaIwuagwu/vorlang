### 🧪 How to Verify the Installer

To ensure the Vorlang installer works correctly on a fresh system, follow these steps:

#### **Linux (Ubuntu 22.04 / Debian 12)**
1.  **Launch a fresh VM/Container.**
2.  **Run the one-liner:**
    ```bash
    curl -fsSL https://raw.githubusercontent.com/EmekaIwuagwu/vorlang/main/install.sh | bash
    ```
3.  **Verify binaries:**
    ```bash
    vorlangc version
    vorlang
    ```
4.  **Security Audit:** Check `/usr/local/share/vorlang` exists and has correct permissions.

#### **Windows (Windows 11)**
1.  **Open PowerShell as Administrator.**
2.  **Execute the script:**
    ```powershell
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/EmekaIwuagwu/vorlang/main/install.ps1" -OutFile "install.ps1"
    .\install.ps1
    ```
3.  **Check Env:** Type `$env:VORLANG_STDLIB` in a new window. It should point to `C:\Vorlang\share\stdlib`.
4.  **Test REPL:** Type `vorlang` and try `print("test")`.

#### **macOS (Homebrew)**
1.  **Copy `vorlang.rb` to a local tap or temporary path.**
2.  **Install:**
    ```bash
    brew install --build-from-source ./vorlang.rb
    ```
3.  **Smoke Test:** Run `vorlangc run examples/test_simple.vorlang`.
