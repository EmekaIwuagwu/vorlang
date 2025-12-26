!include "MUI2.nsh"

Name "Vorlang Compiler"
OutFile "vorlang-setup-v0.10.exe"
InstallDir "C:\Vorlang"
ReuestExecutionLevel admin

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

Section "Install"
    SetOutPath "$INSTDIR\bin"
    File "vorlangc.exe"

    SetOutPath "$INSTDIR\share\stdlib"
    File /r "stdlib\*"

    SetOutPath "$INSTDIR\share\examples"
    File /r "examples\*"

    WriteUninstaller "$INSTDIR\Uninstall.exe"

    # Add to PATH
    EnVar::AddValue "Path" "$INSTDIR\bin"
    EnVar::Set "VORLANG_STDLIB" "$INSTDIR\share\stdlib"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\bin\vorlangc.exe"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir /r "$INSTDIR\share"
    RMDir "$INSTDIR\bin"
    RMDir "$INSTDIR"

    EnVar::DeleteValue "Path" "$INSTDIR\bin"
    EnVar::Delete "VORLANG_STDLIB"
SectionEnd
