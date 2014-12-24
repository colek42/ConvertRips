
#include GetFileList.ahk
#include attachconsole.ahk
#include ConsoleSend.ahk


;Initialize Environment and Read Settings.ini file

IfNotExist, settings.ini
	{
	MsgBox, Run Config Tool First!
	ExitApp
	}


DllCall("FreeConsole")
DetectHiddenWindows, On

IniRead, source_dir, settings.ini, settings, source_dir
IniRead, dest_dir, settings.ini, settings, dest_dir
IniRead, query, settings.ini, settings, query
IniRead, hb_path, settings.ini, settings, hb_path
IniRead, hb_priority, settings.ini, settings, hb_priority
IniRead, dest_ext, settings.ini, settings, dest_ext

p_comp := 0

Menu, Tray, Tip, ConvertRips 1.0


; Start GUI / Generated using SmartGUI Creator 4.0

Gui, Font, S10 CDefault, Verdana
Gui, Add, Text, x22 y20 w570 h20 vEn_Name
Gui, Font, S8 CDefault, Verdana
Gui, Add, Edit, ReadOnly BackgroundTrans x22 y40 w570 h20 vEn_Query
Gui, Font, S15 CDefault, Verdana
Gui, Add, Text, x22 y240 w60 h30 , FPS:
Gui, Add, Text, x192 y240 w100 h30 , Avg FPS:
Gui, Add, Text, x402 y240 w80 h30 , ETA:
Gui, Add, Text, x82 y240 w70 h30 +Right vFPS_gui
Gui, Add, Text, x292 y240 w70 h30 +Right vAFPS_gui
Gui, Add, Text, x462 y240 w130 h30 +Right vETA_gui


Gui, Font, S8 CDefault, Verdana
Gui, Add, DropDownList, x452 y65 w140 h110 gP_Priority_gui vP_Priority, Low||BelowNormal|Normal|AboveNormal|High|Realtime

Gui, Add, Button, x452 y95 w140 h30 vShow_console_gui gShowHideConsole
Gui, Add, Button, x452 y165 w140 h30 gStop_Encode, Stop Encode
Gui, Add, Button, x452 y130 w140 h30 gPause_Encode vPause_Encode_gui, Pause Encode
Gui, Add, Button, x452 y200 w140 h30 , Exit ;Do


Gui, Add, Text, x22 y110 w170 h20 vFile_of_File
Gui, Add, Text, x272 y110 w160 h20 +Right vTask_gui
Gui, Add, Progress, A x22 y130 w410 h40 vFile_of_File_prog
Gui, Add, Progress, A x22 y70 w410 h40 vTaskProg

Gui, Font, S8 CDefault, Verdana

Gui, Add, Text, x22 y183 w45 h20 +Right, Source:
Gui, Add, Edit, ReadOnly BackgroundTrans x68 y180 w370 h20 vEn_Source

Gui, Add, Text, x22 y203 w45 h20 +Right, Dest:
Gui, Add, Edit, ReadOnly BackgroundTrans x68 y200 w370 h20 vEn_Dest

Gui, Font, S15 CDefault, Verdana
Gui, Add, Text, BackgroundTrans x32 y76 w80 h30 vTaskProg_b
Gui, Add, Text, BackgroundTrans x32 y136 w80 h30 vEnc_Prog_b


;Tray Menu

Menu("Tray","Nostandard"), Menu("Tray","Add","Restore","GuiShow"), Menu("Tray","Add")
Menu("Tray","Default","Restore"), Menu("Tray","Click",1)
Gui +LastFound +Resize
Gui1 := WinExist()

Gui, Show, x127 y87 h294 w624, ConvertRips 1.0

GuiControl,, show_console_gui, Show Console
GuiControl,, pause_encode_gui, Pause Encode
encode_paused := 0





GuiControl,, EN_Name, Scanning For Files To Encode...

GetFileList_ISO(source_dir)
GetFileList_VTS(source_dir)
numfiles := (count_VTS + count_ISO)
ofFile := 0


;Loop Through ISO Files
loopcount := 0
Loop, %count_ISO%
{
   sleep, 3000
   While encode_running = 1 
	{	
		sleep 500
		Gosub, updateGui
		Process, Exist, handbrakecli.exe
		If !ErrorLevel
			{
				encode_running := 0
				FormatTime, TimeStringStop
				FileAppend, %loop_name% Has Finished Encoding - The finished file is located at %loop_dest% `n Start: %TimeStringStart% / Finish: %TimeStringStop% `n File Size: %filesize% MB `n Query Used: %query%, %source_dir%\%loop_name%\finished.txt
				sleep 3000
			}
		
	}
   loopcount++
   loop_source := file_list_ISO%loopcount%
   loop_name := mv_name_ISO%loopcount%
   loop_dest = %dest_dir%\%loop_name%\%loop_name%.%dest_ext%
   FileCreateDir, %dest_dir%\%loop_name%
      encode_running :=0
   		FileRead, query_txt, %loop_source%\%loop_name%\query.txt
		If ErrorLevel = 0
			{
			query := query_txt
			}	
   encode(loop_source, loop_dest, hb_path, query)
}

;Loop Through VTS Files
loopcount := 0
Loop, %count_VTS%
{   
   sleep, 3000
   While encode_running = 1 
	{	
		sleep 500
		Gosub, updateGui
		Process, Exist, handbrakecli.exe
		If !ErrorLevel
			{
				encode_running := 0
				FormatTime, TimeStringStop
				FileAppend, %loop_name% Has Finished Encoding - The finished file is located at %loop_dest% `n Start: %TimeStringStart% / Finish: %TimeStringStop% `n File Size: %filesize% MB `n Query Used: %query%, %source_dir%\%loop_name%\finished.txt
				TrayTip, Encode Finished!, %loop_name% Has Finished Encoding!, 10, 1]
				sleep 3000
			}
		
	}	
   loopcount++
   loop_source := file_list_VTS%loopcount%
   loop_name := mv_name_VTS%loopcount%
   loop_dest = %dest_dir%\%loop_name%\%loop_name%.%dest_ext%
   FileCreateDir, %dest_dir%\%loop_name%
   encode_running :=0
   		FileRead, query_txt, %loop_source%\%loop_name%\query.txt
		If ErrorLevel = 0
			{
			query := query_txt
			}		
   encode(loop_source, loop_dest, hb_path, query)
}


;Encodce

Encode(source_a, dest_a, hb_path, query)
{
global

DllCall("FreeConsole")
ofFile ++
FileDelete, %A_temp%\chapters.csv
encode_running := 1
FormatTime, TimeStringStart

Run, % hb_path . " -i """ . source_a . """ -o """ . dest_a . """ " . query . " -L",, hide, HB_PID
Process, Priority, %HB_PID%, %hb_priority% ; Runs handbrakeCLI and sets priority
win_hide_var := 1
GuiControl,, show_console_gui, Show Console
WinWait, ahk_pid %HB_PID%
Process, Exist, handbrakecli.exe  ; Need to get window name this way to work with 64bit Windows7
pid := ErrorLevel
	
	GuiControl,, En_query, %query%
	GuiControl,, En_Source, %source_a%
	GuiControl,, En_Dest, %dest_a%


AttachConsole(pid)  ;  Runs Attach Console Function 


w := 80, h := 20
DllCall("SetConsoleWindowInfo","uint",hConOut,"int",1,"int64*", w-1 <<32 | h-1 <<48 )  ;Sets Console Window Size
DllCall("SetConsoleScreenBufferSize","uint",hConOut,"uint", w | h <<16 )  ;Sets Console Buffer Size
WinShow, ahk_pid %pid%
DisableCloseButton()
WinHide, ahk_pid %PID%




Return
}


UpdateGui:

    File_of_File_int := (ofFile / numfiles) * 100
	StringTrimRight, File_of_File_int , File_of_File_int , 4
	GuiControl,, File_of_File_prog, %File_of_File_int%

	GuiControl,, File_of_File, Encode %ofFile% \ %numfiles%
	GuiControl,, Enc_Prog_b,  %File_of_File_int%`% 

	GuiControl,, TaskProg, %p_comp%
	GuiControl,, TaskProg_b, %p_comp%`% 
	Menu, Tray, Tip, Encoding %loop_name% - %p_comp%`% Complete (%offile%\%numfiles%) 
   
   
   text := GetConsoleText()
    If text = %prevText%
      Return
    prevText := text   
  
   
   StringGetPos, p_comp_L, text, Encoding: task, R1
	if ErrorLevel = 1 
		{
		GuiControl,, TaskProg, 0
		GuiControl, , EN_Name, Scanning %loop_source% For Titles...
		return 
		}
	
			
	p_comp_L := p_comp_L+28
    StringMid, p_comp, text, %p_comp_L%, 5 , L
   
   StringGetPos, task_L, text, Encoding: task, R1
    task_L := task_L+16
    StringMid, task, text, %task_L%, 1 , L
   
   StringGetPos, tasks_L, text, Encoding: task, R1
    tasks_L := tasks_L+21
    StringMid, tasks, text, %tasks_L%, 1 , L

	GuiControl,, EN_Name, Encoding %loop_name% with following Handbrake String:
	GuiControl,, task_gui, Task %task% \ %tasks%

   StringGetPos, fps_L, text, `% (, R1
    fps_L := fps_L+7
    StringMid, fps, text, %fps_L%, 4 , L
		
		if fps is not float
			{
			GuiControl,, ETA_gui, Unk
	        GuiControl,, FPS_gui, N/A
	        GuiControl,, aFPS_gui, N/A
			return
			}
			
		
   
   StringGetPos, afps_L, text, avg, R1
    afps_L := afps_L+8
    StringMid, afps, text, %afps_L%, 4 , L
   
   StringGetPos, ETA_L, text, ETA, R1
    ETA_L := ETA_L+13
    StringMid, ETA, text, %ETA_L%, 9 , L
   

	GuiControl,, ETA_gui, %ETA%
	GuiControl,, FPS_gui, %fps%
	GuiControl,, aFPS_gui, %afps%
	GuiControl,, TaskProg, % p_comp
	GuiControl,, TaskProg_b, %p_comp%`%
return


OnMessage( "0x112", "WM_SYSCOMMAND" )  ;Minimize to Tray
Return

WM_SYSCOMMAND( wParam, lParam, Msg, hWnd ) {  ;Minimize to Tray
  Global R
  If (A_Gui && wParam=0xF020) {
    MinimizeGuiToTray( R, hWnd )
    Return 0
}}

MinimizeGuiToTray( ByRef R, hGui ) { ; www.autohotkey.com/forum/viewtopic.php?p=214612#214612 Minimize to trade
  WinGetPos, X0,Y0,W0,H0, % "ahk_id " (Tray:=WinExist("ahk_class Shell_TrayWnd"))
  ControlGetPos, X1,Y1,W1,H1, TrayNotifyWnd1,ahk_id %Tray%
  SW:=A_ScreenWidth,SH:=A_ScreenHeight,X:=SW-W1,Y:=SH-H1,P:=((Y0>(SH/3))?("B"):(X0>(SW/3))
  ? ("R"):((X0<(SW/3))&&(H0<(SH/3)))?("T"):("L")),((P="L")?(X:=X1+W0):(P="T")?(Y:=Y1+H0):)
  VarSetCapacity(R,32,0), DllCall( "GetWindowRect",UInt,hGui,UInt,&R)
  NumPut(X,R,16), NumPut(Y,R,20), DllCall("RtlMoveMemory",UInt,&R+24,UInt,&R+16,UInt,8 )
  DllCall("DrawAnimatedRects", UInt,hGui, Int,3, UInt,&R, UInt,&R+16 )
  WinHide, ahk_id %hGui%
}

Menu( MenuName, Cmd, P3="", P4="", P5="" ) {   ;Minimize to Tray
  Menu, %MenuName%, %Cmd%, %P3%, %P4%, %P5%
Return errorLevel
}

GuiShow: ;Minimize to Tray
{	
	DllCall("DrawAnimatedRects", UInt,Gui1, Int,3, UInt,&R+16, UInt,&R )
	Gui, Show
	return
}

ShowHideConsole:
{

If win_hide_var = 1
	{
	WinShow, ahk_pid %pid%
	GuiControl,, show_console_gui, Hide Console
	win_hide_var := 0
    WinWait, ahk_pid %pid%
	DisableCloseButton()
	return
	}
If win_hide_var = 0
	{
	WinHide, ahk_pid %pid%
	GuiControl,, show_console_gui, Show Console
	win_hide_var := 1
	return
	}
}


P_Priority_gui:
	{
	Gui, Submit
	Process, priority, %PID%, %P_Priority%
	GoSub GuiShow
	MsgBox, Priority Now %P_Priority%
	return
	}	

Pause_Encode:
{
if encode_paused = 0
	{
	DllCall("FreeConsole")
	ConsoleSend("p `r")
	GuiControl,, pause_encode_gui, Resume Encode
	encode_paused := 1
	AttachConsole(pid)
	return
	}
	
if encode_paused = 1
	{
	DllCall("FreeConsole")
	ConsoleSend("r `r")
	GuiControl,, pause_encode_gui, Pause Encode
	encode_paused := 0
	AttachConsole(pid)
	return
	}
}

Stop_Encode:
{
	DllCall("FreeConsole")
	ConsoleSend("q `r")
	AttachConsole(pid)
	return
}


ButtonExit:
MsgBox, 4, Exit ConvertRips?, Are You Sure You Want To Exit?  This Will Terminate Any Encodes!, 15  ; 5-second timeout.
IfMsgBox, No
    Return  ; User pressed the "No" button.
IfMsgBox, Timeout
    Return ; i.e. Assume "No" if it timed out.
; Otherwise, continue:



DllCall("FreeConsole")
WinKill, ahk_pid %pid%
Sleep 500
FileDelete, %A_temp%\chapters.csv
ExitApp

DisableCloseButton(hWnd="") {
 If hWnd=
    hWnd:=WinExist("A")
 hSysMenu:=DllCall("GetSystemMenu","Int",hWnd,"Int",FALSE)
 nCnt:=DllCall("GetMenuItemCount","Int",hSysMenu)
 DllCall("RemoveMenu","Int",hSysMenu,"UInt",nCnt-1,"Uint","0x400")
 DllCall("RemoveMenu","Int",hSysMenu,"UInt",nCnt-2,"Uint","0x400")
 DllCall("DrawMenuBar","Int",hWnd)
Return ""
}