
if A_IsCompiled
debug:=0
Else
debug:=1
debugHotkey:=0

#SingleInstance force
SetWorkingDir %A_ScriptDir%

#Include lib/midi_data.ahk
#Include lib/Music.ahk
#Include menu.ahk

; 谱面内容
sheet_content:=""
; 显示内容
plain_content:=""

isBtn2Playing:=0

_Instrument:=10

baseOffset := [0,2,4,5,7,9,11]

Notes := new NotePlayer()
Notes.Instrument(_Instrument)
if debug
{
	MsgBox, 0x41030,ATTENTION,You are running DEBUG version of the program!!!
}
#Include gui.ahk
Gui, Submit, NoHide
sheet_content:=editer
Gosub resolution
Notes.Start()
Return

titleMove:
PostMessage 0xA1, 2
Return

#Include menu_label.ahk

; 管理员权限下，无法直接使用拖入文件的功能，改由文件选择器调用此方法
GuiDropFiles(GuiHwnd, FileArray, CtrlHwnd, X, Y) {
	global hEdit1, editer, plain_content, sheet_content
	if FileArray.MaxIndex() > 1
	{
		MsgBox, 0x41010, ERROR, More than 1 file detected.
		Return
	}
	if CtrlHwnd+0=hEdit1+0
	{
		FileGetSize, size, % FileArray[1], K
		if size >= 64
		{
			MsgBox, 0x41010, ERROR, The file is too LARGE.
			Return
		}
		f:=FileOpen(FileArray[1], "r")
		GuiControl, -ReadOnly -Disabled, editer
		f.Seek(0)
		plain_content:=f.Read()
		sheet_content:=plain_content
		f.Close()
		ControlSetText,, % plain_content, ahk_id %hEdit1%
	}
}

func_btn_try_stop:
	Notes.Reset()
	isBtn2Playing:=0
	btn2update()
Return

func_btn_try:
if(!isBtn2Playing)
{
	Gui, Submit, NoHide
	sheet_content:=editer
	Gosub resolution
	; Clipboard:=output
	Notes.Start()
	isBtn2Playing:=1
	btn2update()
}
Else
{
	Gosub, func_btn_try_stop
}
Return

func_btn_file:
Thread, NoTimers
FileSelectFile, select_file, 1, , Title, DoMiSo Sheet (*.txt)
Thread, NoTimers, false
if select_file
{
	GuiDropFiles(0, [select_file], hEdit1, 0, 0)
}
Return

func_btn_exit:
Exit:
ExitApp

winMove:
PostMessage, 0xA1, 2
Return

resolution:
parse_content:=sheet_content

output:=""
Notes.Reset()
Notes.Instrument(_Instrument)
base:=60
beatTime:=Round(60000/80)
Loop, Parse, parse_content, `n,`r%A_Space%%A_Tab%	;逐行解析
{
	chord:=0	;重置和弦标记
	chordTime:=0	;重置和弦长度
	
	If(RegExMatch(A_LoopField,"i)(?:b|B)(?:p|P)(?:m|M)=(\d+)",o))	;解析bpm标记
	{
		If(o1>0 And o1<480)
		beatTime:=Round(60000/o1)
	}
;~ 	MsgBox, % NoteData
	If(RegExMatch(A_LoopField,"i)1=([A-G]\d?\d?\#?|b?)",p))	;解析调号标记
	{
		If(RegExMatch(NoteData,"(\d\d?\d?)\s" p1 "\s",q))
		base:=q1
	}
	
	If(RegExMatch(A_LoopField,"i)rollback=(\d+\.?\d*)",r))	;解析rollback标记
	{
;~ 		MsgBox, % "rollback=" r1 "`nOffset=" Notes.Offset
		If(r1*beatTime<=Notes.Offset)
		{
			Notes.Delay(-r1*beatTime)
			output.="Notes.Delay(" -r1*beatTime ")`n"
		}
		Else
		{
			Notes.Offset:=0
			output.="Notes.Offset:=0`n"
		}
	}
	
	/*
	tune1:音阶
	tune2:音符
	tune3:升降调
	tune4:本音长
	tune5:延音长
	*/
	
	currentLine:=A_LoopField
	Loop, Parse, currentLine, %A_Space%%A_Tab%
	{
		If(RegExMatch(A_LoopField,"iS)^(\-*|\+*)([0-7])(\#|b)?(\/*)((?:(?:\-\/*)|(?:\.))*)\s?$",tune))	;解析音符
		{
			noteTime:=beatTime
			
			If(tune1!="")	;解析八度偏移量
			{
				If InStr(tune1, "-")
				offs:=-StrLen(tune1)
				Else If InStr(tune1, "+")
				offs:=StrLen(tune1)
				Else offs:=0
			}
			Else offs:=0
			
			noteTune:=base+baseOffset[tune2+0]+offs*12	;解析基本音
			
			If(tune3!="")	;解析升降调
			{
				If InStr(tune3, "#"){
					noteTune+=1
				}
				Else If InStr(tune3, "b"){
					noteTune-=1
				}
			}
			
;~ 			If(tune4!="")	;解析基本音符长度
			If(1)
			{
				noteTime:=beatTime>>StrLen(tune4)
				timeIncrement:=noteTime
			}
			
			If(tune5!="")	;解析延音长度
			{
				RegExMatch(tune5,"((?:\-\/*)|(?:\.))((?:\-\/*)|(?:\.))?((?:\-\/*)|(?:\.))?((?:\-\/*)|(?:\.))?((?:\-\/*)|(?:\.))?((?:\-\/*)|(?:\.))?((?:\-\/*)|(?:\.))?((?:\-\/*)|(?:\.))?((?:\-\/*)|(?:\.))?",tmp)
				Loop
				{
					If(tmp%A_Index%!="")
					{
						If InStr(tmp%A_Index%,".")
						{
;~ 							MsgBox, % noteTime "`n" timeIncrement
							timeIncrement:=timeIncrement>>1
;~ 							MsgBox, % timeIncrement
							noteTime+=timeIncrement
						}
						Else
						{
							timeIncrement:=beatTime>>(StrLen(tmp%A_Index%)-1)
							noteTime+=timeIncrement
						}
					}
					Else
					Break
				}
			}
			If(noteTune>0 or chord=1)
			{
				If(!chord)
				{
					Notes.Note(noteTune,noteTime,50).Delay(noteTime)
					output.="Notes.Note(" noteTune "," noteTime ",50).Delay(" noteTime ")`n"
				}
				Else If(noteTune>0)
				{
					Notes.Note(noteTune,noteTime,50)
					chordTime:=noteTime>chordTime ? noteTime : chordTime
					output.="Notes.Note(" noteTune "," noteTime ",50)`n"
				}
			}
			Else
			{
				Notes.Delay(noteTime)
				output.="Notes.Delay(" noteTime ")`n"
			}
		}
		If(RegExMatch(A_LoopField,"iS)(\(|\))",mark))	;解析括号
		{
			If(mark1="(" And chord=0)
			{
				chord:=1
				chordTime:=0
			}
			Else If(mark1=")" And chord=1)
			{
				Notes.Delay(chordTime)
				chord:=0
				output.="Notes.Delay(" chordTime ")`n"
			}
		}
	}
}
Return

Author:
run, https://github.com/Nigh
Return

donate:
Run, https://ko-fi.com/xianii
Return

GuiClose:
ExitApp

#If debugHotkey
F5::ExitApp
F6::Reload
#If
