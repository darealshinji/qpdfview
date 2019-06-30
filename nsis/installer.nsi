!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "FileAssociation.nsh"

!define APPNAME "qpdfview"
!define COMPANYNAME "Adam Reichold"
!define DESCRIPTION "qpdfview is a tabbed document viewer"
!define GUID "{CBFA73BF-684B-4CD2-9B7A-D1E4B500A6B1}"
!define LICENSE "COPYING.txt"

# define to create an installer for the 64 bit version
;!define ARCH_X64

!define VERSIONMAJOR 0
!define VERSIONMINOR 4
!define VERSIONBUILD 18
;!define VERSIONBETA "beta1"
!define DISPLAYVERSION "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}${VERSIONBETA}"

!define HELPURL "https://answers.launchpad.net/qpdfview" ;"Support Information" link
!define UPDATEURL "https://launchpad.net/qpdfview" ;"Product Updates" link
!define ABOUTURL "https://launchpad.net/qpdfview" ;"Publisher" link
!define ARP "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"

RequestExecutionLevel admin ;Require admin rights on NT6+ (When UAC is turned on)

!ifdef ARCH_X64
!define ARCH "x64"
!define DISPLAYARCH " (x64)"
InstallDir "$PROGRAMFILES64\${APPNAME}"
!else
!define ARCH "x86"
!define DISPLAYARCH ""
InstallDir "$PROGRAMFILES\${APPNAME}"
!endif

# zlib|bzip2|lzma
SetCompressor lzma

Name "${APPNAME}"
Icon "${APPNAME}_win32.ico"
LicenseData "${LICENSE}"
OutFile "${APPNAME}-installer-${ARCH}.exe"

Page license
Page directory
Page instfiles

!macro VerifyUserIsAdmin
	UserInfo::GetAccountType
	pop $0
	${If} $0 != "admin" ;Require admin rights on NT4+
		MessageBox MB_OK|MB_ICONSTOP "Administrator rights required!"
		SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
		Quit
	${EndIf}
!macroend

!macro BadPathsCheck
	# Prevent the uninstaller from accidentally deleting important
	# system directories if $INSTDIR wasn't set correctly.
	StrCpy $R0 $INSTDIR "" -2
	StrCmp $R0 ":\" bad
	StrCpy $R0 $INSTDIR "" -14
	StrCmp $R0 "\Program Files" bad
	StrCpy $R0 $INSTDIR "" -8
	StrCmp $R0 "\Windows" bad
	StrCpy $R0 $INSTDIR "" -6
	StrCmp $R0 "\WinNT" bad
	StrCpy $R0 $INSTDIR "" -9
	StrCmp $R0 "\system32" bad
	StrCpy $R0 $INSTDIR "" -8
	StrCmp $R0 "\Desktop" bad
	StrCpy $R0 $INSTDIR "" -23
	StrCmp $R0 "\Documents and Settings" bad
	StrCpy $R0 $INSTDIR "" -13
	StrCmp $R0 "\My Documents" bad done
	bad:
		MessageBox MB_OK|MB_ICONSTOP "Install path invalid!"
		Abort
	done:
!macroend

Function .onInit
	SetShellVarContext all
	!insertmacro VerifyUserIsAdmin

	# Check for a running instance
	System::Call 'kernel32::CreateMutex(i 0, i 0, t "${APPNAME}-installer-${GUID}") ?e'
	Pop $R0
	StrCmp $R0 0 +3
		MessageBox MB_OK|MB_ICONSTOP "The installer is already running."
		Abort
FunctionEnd

Section "install"
	SetOutPath $INSTDIR
	File "/oname=${APPNAME}.exe" "${APPNAME}-${ARCH}.exe"
	File "${LICENSE}"
	File "THIRDPARTY.txt"
	WriteUninstaller "$INSTDIR\uninstall.exe"

	# Start Menu
	CreateShortCut "$SMPROGRAMS\${APPNAME}.lnk" "$INSTDIR\${APPNAME}.exe" "" ""

	# Desktop
	;CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${APPNAME}.exe" "" ""

	# File Associations
	${registerExtension} "$INSTDIR\${APPNAME}.exe" ".pdf"  "PDF Document"
	${registerExtension} "$INSTDIR\${APPNAME}.exe" ".ps"   "PS Document"
	${registerExtension} "$INSTDIR\${APPNAME}.exe" ".eps"  "EPS Document"
	${registerExtension} "$INSTDIR\${APPNAME}.exe" ".djvu" "DJVU Document"
	${registerExtension} "$INSTDIR\${APPNAME}.exe" ".djv"  "DJVU Document"

	# Registry information for add/remove programs
	WriteRegStr HKLM "${ARP}" "DisplayName" "${APPNAME} ${DISPLAYVERSION}${DISPLAYARCH}"
	WriteRegStr HKLM "${ARP}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "${ARP}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegStr HKLM "${ARP}" "InstallLocation" "$\"$INSTDIR$\""
	WriteRegStr HKLM "${ARP}" "DisplayIcon" "$\"$INSTDIR\${APPNAME}.exe$\",0"
	WriteRegStr HKLM "${ARP}" "Publisher" "${COMPANYNAME}"
	WriteRegStr HKLM "${ARP}" "HelpLink" "${HELPURL}"
	WriteRegStr HKLM "${ARP}" "URLUpdateInfo" "${UPDATEURL}"
	WriteRegStr HKLM "${ARP}" "URLInfoAbout" "${ABOUTURL}"
	WriteRegStr HKLM "${ARP}" "DisplayVersion" "${DISPLAYVERSION}"
	WriteRegDWORD HKLM "${ARP}" "VersionMajor" ${VERSIONMAJOR}
	WriteRegDWORD HKLM "${ARP}" "VersionMinor" ${VERSIONMINOR}
	WriteRegDWORD HKLM "${ARP}" "NoModify" 1
	WriteRegDWORD HKLM "${ARP}" "NoRepair" 1

	# Compute and set EstimatedSize
	${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
	IntFmt $0 "0x%08X" $0
	WriteRegDWORD HKLM "${ARP}" "EstimatedSize" $0
SectionEnd

# Uninstaller

UninstPage uninstConfirm
UninstPage instfiles

Function un.onInit
	SetShellVarContext all
	!insertmacro VerifyUserIsAdmin
	!insertmacro BadPathsCheck
FunctionEnd

Section "uninstall"
	Delete "$SMPROGRAMS\${APPNAME}.lnk"
	;Delete "$DESKTOP\${APPNAME}.lnk"
	Delete "$INSTDIR\${APPNAME}.exe"
	Delete "$INSTDIR\COPYING.txt"
	Delete "$INSTDIR\THIRDPARTY.txt"

	# Always delete uninstaller as the last action
	Delete "$INSTDIR\uninstall.exe"
	RMDir "$INSTDIR"

	# Remove File Associations
	# Note: setting .pdf doesn't work correctly on Windows 10
	${unregisterExtension} ".pdf"  "PDF Document"
	${unregisterExtension} ".ps"   "PS Document"
	${unregisterExtension} ".eps"  "EPS Document"
	${unregisterExtension} ".djvu" "DJVU Document"
	${unregisterExtension} ".djv"  "DJVU Document"

	# Remove uninstaller information from the registry
	DeleteRegKey HKLM "${ARP}"
SectionEnd

