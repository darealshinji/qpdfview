set qpdfview=D:\\tools\\qpdfview\\qpdfview-x64.exe
reg delete HKCU\Software\Classes\.djvu /f
reg delete HKCU\Software\Classes\.eps /f
reg delete HKCU\Software\Classes\.pdf /f
reg delete HKCU\Software\Classes\.ps /f
reg delete HKCU\Software\Classes\qpdfview.djvu /f
reg delete HKCU\Software\Classes\qpdfview.eps /f
reg delete HKCU\Software\Classes\qpdfview.pdf /f
reg delete HKCU\Software\Classes\qpdfview.ps /f
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.djvu /f
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.eps /f
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf /f
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps /f
reg add HKCU\Software\Classes\.djvu /d "qpdfview.djvu"
reg add HKCU\Software\Classes\.eps /d "qpdfview.eps"
reg add HKCU\Software\Classes\.pdf /d "qpdfview.pdf"
reg add HKCU\Software\Classes\.ps /d "qpdfview.ps"
reg add HKCU\Software\Classes\qpdfview.djvu /d "DjVu Document"
reg add HKCU\Software\Classes\qpdfview.eps /d "Encapsulated PostScript Document"
reg add HKCU\Software\Classes\qpdfview.pdf /d "Portable Document Format"
reg add HKCU\Software\Classes\qpdfview.ps /d "PostScript Document"
reg add HKCU\Software\Classes\qpdfview.djvu\DefaultIcon /d "\"%qpdfview%\",0"
reg add HKCU\Software\Classes\qpdfview.eps\DefaultIcon /d "\"%qpdfview%\",0"
reg add HKCU\Software\Classes\qpdfview.pdf\DefaultIcon /d "\"%qpdfview%\",0"
reg add HKCU\Software\Classes\qpdfview.ps\DefaultIcon /d "\"%qpdfview%\",0"
reg add HKCU\Software\Classes\qpdfview.djvu\shell\open\command /d "\"%qpdfview%\" \"%%1\""
reg add HKCU\Software\Classes\qpdfview.eps\shell\open\command /d "\"%qpdfview%\" \"%%1\""
reg add HKCU\Software\Classes\qpdfview.pdf\shell\open\command /d "\"%qpdfview%\" \"%%1\""
reg add HKCU\Software\Classes\qpdfview.ps\shell\open\command /d "\"%qpdfview%\" \"%%1\""
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.djvu\UserChoice /v "ProgId" /d "qpdfview.djvu"
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.eps\UserChoice /v "ProgId" /d "qpdfview.eps"
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice /v "ProgId" /d "qpdfview.pdf"
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps\UserChoice /v "ProgId" /d "qpdfview.ps"
ie4uinit -ClearIconCache
ie4uinit -show
