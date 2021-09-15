
# dependency:
# autohotkey in PATH
# ahk2exe in PATH
# 7z in PATH
# mpress in ahk2exe path

.PHONY: default dist build help
default: dist

DoMiSo.exe:
	ahk2exe.exe /in DoMiSo.ahk /out DoMiSo.exe /icon domiso.ico /mpress 1

dist: DoMiSo.exe
	RMDIR /S /Q dist
	MKDIR dist
	7z a -r DoMiSo.zip .\DoMiSo.exe
	MOVE /Y DoMiSo.zip .\dist
	DEL /Q .\DoMiSo.exe

build: DoMiSo.exe
