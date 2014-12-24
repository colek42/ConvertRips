GetFileList_ISO(source_dir)
{
	global
	count_ISO := 0
	
	Loop, %source_dir%\*.iso,,1 
	{
	

	
		source = %A_LoopFileLongPath%
			
		; Get Movie Name From Directory
	
		SplitPath, SOURCE,, mv_name
		StringGetPos, mv_name_count, mv_name, \, R1
		mv_name_count ++
		StringTrimLeft, mv_name, mv_name, mv_name_count
	
		IfNotExist, %A_LoopFileDir%\finished.txt ;check if finished file exists
			{
			count_ISO ++
			file_list_iso%count_ISO% := source
			mv_name_iso%count_ISO% := mv_name
			;MsgBox, %source%
			

			}
	}
return
}



GetFileList_VTS(source_dir)
{
	global
	count_VTS := 0

	Loop, %source_dir%\*.*, 2, 1 ; Convert All Video_TS folders in source directory
		{
			If A_LoopFileLongPath contains VIDEO_TS 
				{
				SplitPath, A_LoopFileLongPath,, mv_name
				StringGetPos, mv_name_count, mv_name, \, R1
				mv_name_count ++
				StringTrimLeft, mv_name, mv_name, mv_name_count
	
				source=%A_LoopFileDir%
				
				IfNotExist, %A_LoopFileDir%\finished.txt ;check if finished file exists
					{
					count_VTS ++
					file_list_vts%count_VTS% := source
					mv_name_vts%count_VTS% := mv_name
					;MsgBox, %source%
					}
				}
		}
return
}

GetNumFiles()
{
	global
	numfiles := (count_VTS + count_ISO)
	return
}