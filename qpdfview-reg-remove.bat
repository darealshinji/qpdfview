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
ie4uinit -ClearIconCache
ie4uinit -show
