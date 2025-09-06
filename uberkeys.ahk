/*	Personal hotkeys for general use
 *
 */
#SingleInstance Force
#Requires AutoHotkey v2+

tray()
dPath := findDictionary()
loadKeys()

#CapsLock::changeCase()

;#######################################################################################
changeCase()
{
	CaretGetPos(&mX,&mY)
	capsMenu := Menu()
	capsMenu.Add("&UPPERCASE",doCopy)
	capsMenu.Add("&lowercase",doCopy)
	capsMenu.Add("&Title Case",doCopy)
	capsMenu.Add("&kebab-case",doCopy)
	capsMenu.Add("&snake_case",doCopy)
	capsMenu.Add("&(parentheses)",doCopy)
	capsMenu.Add("&'single quotes'",doCopy)
	capsMenu.Add("&`"double quotes`"",doCopy)
	try capsMenu.Show(mX,mY)
	catch {
		capsMenu.Show()
	}

	doCopy(fn, *) {
		clipSavedAll := ClipboardAll()
		A_Clipboard := ""

		SendInput("^c")

		if (!ClipWait(2)) {
			A_Clipboard := clipSavedAll
			return
		}

		copied := A_Clipboard

		if (!StrLen(copied)) {
			A_Clipboard := clipSavedAll
			return
		}

		fn := RegExReplace(fn,"[&`'`"()]")
		switch (fn) {
			case "UPPERCASE":
				copied := StrUpper(copied)
			case "lowercase":
				copied := StrLower(copied)
			case "Title Case":
				copied := StrTitle(copied)
			case "kebab-case":
				copied := RegExReplace(copied,"[ _]","-")
			case "snake_case":
				copied := RegExReplace(copied,"[ -]","_")
			case "single quotes":
				copied := Chr(39) . copied . Chr(39)
			case "double quotes":
				copied := Chr(34) . copied . Chr(34)
			case "parentheses":
				copied := "(" . copied . ")"
		}

		A_Clipboard := copied
		ClipWait(0.5)
		SendInput("^v")
		Sleep(200)
		A_Clipboard := clipSavedAll
	}
}

findDictionary() {
	fname := "uberkeys-custom"
	paths := ["C:\Users\" A_UserName "\OneDrive - SCH"									; array of potential paths to dictionary
			, "C:\Users\" A_UserName "\OneDrive"
			, A_ScriptDir]
	if InStr(A_ScriptDir,"AhkProjects") {
		paths := [A_ScriptDir]
	}

	dgui := Gui(,"Store auto-correct dictionary")
	dgui.SetFont("s12")
	dgui.AddText(,"Select path to store auto-correct dictionary:")
	dbut := []
	for path in paths
	{
		check := path "\" fname
		if FileExist(check) {															; path to dictionary already exists
			return check
		}

		dbut.Push(A_Index)
		if !FileExist(path) {															; path does not exist
			continue
		}
		dbut[A_Index] := dgui.AddButton(,path)
		dbut[A_Index].OnEvent("Click",res:=dbutpress)
	}
	dgui.Show

	WinWaitClose("Store auto-correct dictionary")
	dgui.Destroy
	return res "\" fname

	dbutpress(x,*) {
		res := x.text
		dgui.Submit
	}
}

getDictionary() {
	res := []
	if FileExist(dPath) {
		loop read dPath {
			res.Push(A_LoopReadLine)
		}
	}
	return res
}

loadKeys() {
	dict := getDictionary()
	for val in dict
	{
		res := parseHotString(val)
		res.a := RegExReplace(res.a,"[xX]")
		Hotstring("::" res.b,res.c,false)
		Hotstring(res.a res.b,res.c,true)
	}
}

parseHotString(str)
{
	RegExMatch(str,"^(:.*?:)(.*?)::(.*?)$",&n)
	return {a:n[1],b:n[2],c:n[3]}
}

tray() {
	A_IconTip := "UberKeys"
	tray := A_TrayMenu
	tray.Delete()
	tray.Add("UberKeys v" FileGetTime(A_ScriptName),(*)=>{})
	tray.Add()
	tray.Add("Edit hotstrings",stringEdit)
	tray.Add("Suspend functions",toggleSuspend)
	tray.Add("Quit",quit)
	tray.Default := "Edit hotstrings"
	
	toggleSuspend(*) {
		if (A_IsSuspended) {
			tray.Rename("Enable functions","Suspend functions")
			tray.Uncheck("Suspend functions")
			Suspend(0)
		} else {
			tray.Rename("Suspend functions","Enable functions")
			tray.Check("Enable functions")
			Suspend(1)
		}
	}

	quit(*) {
		ExitApp
	}
}

stringEdit(*) {
	if WinExist("UberKeys","Auto-correct Dictionary") {
		return
	}
	strGUI := Gui(,"UberKeys")
	strGUI.MarginX := 10
	strGUI.MarginY := 10
	strGUI.OnEvent("Close",closeGUI)
	strGUI.SetFont("bold s16")
	strGUI.AddText("w600 Center","Auto-correct Dictionary")
	strGUI.SetFont("Norm s12")
	strLV := strGUI.AddListView("w600 h300 Grid +Hdr -ReadOnly BackgroundC0C0C0 NoSortHdr",["","Opts","Shortcut","Expansion"])
	strLV.OnEvent("DoubleClick",clickRow)
	strLV.ModifyCol(1,5)
	strLV.ModifyCol(2,"Center")
	strLV.ModifyCol(3,120)
	strLV.ModifyCol(4,430)
	
	dict := getDictionary()
	for val in dict
	{
		res := parseHotString(val)
		strLV.Add("",""
			,res.a
			,res.b
			,res.c
		)
	}
	strLV.Add("")

	strGUI.Show

	HotIfWinActive("UberKeys","Auto-correct Dictionary")
		Hotkey "+Up",moveRow
		Hotkey "+Down",moveRow
		Hotkey "Esc",closeGUI
	HotIfWinActive

	moveRow(dir) {
		if !(row := strLV.GetNext()) {
			return
		}
		if (strLV.GetText(row,2)="") {
			return
		}

		Switch dir
		{
		Case "+Up":
			if (row=1) {
				return
			}
			swapRows(row-1)
			strLV.Modify(row,"-Select")
			strLV.Modify(row-1,"Select")

		Case "+Down":
			if (row=strLV.GetCount()) {
				return
			}
			if (strLV.GetText(row+1,2)="") {
				return
			}
			swapRows(row)
			strLV.Modify(row,"-Select")
			strLV.Modify(row+1,"Select")
		}

		return
	}
	swapRows(row1) {
		loop strLV.GetCount("Col")
		{
			col := A_Index
			txt1 := strLV.GetText(row1,col)
			txt2 := strLV.GetText(row1+1,col)
			strLV.Modify(row1, "Col" col, txt2)
			strLV.Modify(row1+1, "Col" col, txt1)
		}
	}

	clickRow(LV,rownum) {
		strGUI.Hide()

		if (rownum) {
			res := editRow(strLV.GetText(rownum,2),strLV.GetText(rownum,3),strLV.GetText(rownum,4))
		} else {
			res := editRow("::","","")
		}

		strGUI.Show()

		if (res="X") {
			strLV.Delete(rownum)
			return
		}
		if (res="") {																	; no changes
			return
		}
		if (rownum) {																	; replace prior values
			strLV.Modify(rownum,"","",res[1],res[2],res[3])
		} else {																		; add new row with values
			strLV.Add("","",res[1],res[2],res[3])
		}
		saveKeys()
		loadKeys()
	}

	editRow(textOpt,textStr,textRep) {
		Suspend(1)
		rowGUI := Gui("AlwaysOnTop","UberKeys Row Edit")
		rowGUI.SetFont("s12 bold")
		rowGUI.delete := false
		rowGUI.closed := false
		opt := []
		
		rowGUI.AddText("","Options")
		rowGUI.SetFont("norm s8")
		rowGUI.AddButton("yp","info").OnEvent("Click",infoBtn)
		rowGUI.SetFont("s10")
		opt.Endchar := rowGUI.AddCheckbox("xs section","End Char not required")
		opt.Immediate := rowGUI.AddCheckbox("","Replace immediately")
		opt.Backspacing := rowGUI.AddCheckbox("","Don't backspace")
		opt.CaseSensitive := rowGUI.AddCheckbox("ys xs+250","Case sensitive")
		opt.OmitEnding := rowGUI.AddCheckbox("","Omit ending char")
		optParse(textOpt)

		rowGUI.SetFont("s12 bold")
		rowGUI.AddText("xm w250","`nHotstring")
		box1 := rowGUI.AddEdit("w500",textStr)
		
		rowGUI.AddText("","`nReplacement")
		box2 := rowGUI.AddEdit("w500 r3 +Wrap",textRep)
		
		btnSubmit := rowGUI.AddButton("","Submit")
		btnSubmit.OnEvent("Click",rowSubmit)

		btnDelete := rowGUI.AddButton("yP x150","Delete")
		btnDelete.OnEvent("Click",rowDelete)

		rowGUI.OnEvent("Close",rowClose)
		rowGUI.Show()

		WinWaitClose("UberKeys Row Edit")
		Suspend(0)
		if WinExist("Option info") {
			WinClose("Option info")
		}
		optParse(opt)
		if (rowGUI.delete=true) {
			return "X"
		}
		if (rowGUI.closed=true) {
			return ""
		}
		if (opt.res=textOpt)&&(box1.Value=textStr)&&(box2.Value=textRep) {				; no changes, returns blank
			return ""
		} else {
			return [opt.res,box1.Value,box2.Value]
		}

		infoBtn(*) {
			if WinExist("Option info") {
				return
			}
			rowGUI.GetPos(&guiX,&guiY,&guiW,&guiH)
			infoWin := Gui()
			infoWin.Title := "Option info"
			infoWin.MarginX := 20
			infoWin.MarginY := 20
			infoWin.SetFont("s10")
			infoWin.AddText("+Wrap w350"
				, "End Char not required - Do not require ending character (e.g. [space], [.], or [enter]) to trigger.`n`n"
				. "Replace immediately - Trigger immediately following last char, even within another word.`n`n"
				. "Don't backspace - Will not erase preceding hotstring.`n`n"
				. "Case sensitive - Hotstsring must match case.`n`n"
				. "Omit ending char - Ignore ending character."
			)
			infoWin.Show("x" guiX+guiW+260 " y" guiY)
		}

		optParse(var,*) {
			if IsObject(var) {
				res := ""
				if (opt.Endchar.Value=true) {
					res .= "*"
				}
				if (opt.Immediate.Value=true) {
					res .= "?"
				}
				if (opt.Backspacing.Value=true) {
					res .="b0"
				}
				if (opt.CaseSensitive.Value=true) {
					res .= "C"
				}
				if (opt.OmitEnding.Value=true) {
					res .= "O"
				}
				opt.res := ":" res ":"
			} else {
				if InStr(var,"*") {
					opt.Endchar.Value := true
				}
				if InStr(var,"?") {
					opt.Immediate.Value := true
				}
				if InStr(var,"b0") {
					opt.Backspacing.Value := true
				}
				if InStr(var,"C") {
					opt.CaseSensitive.Value := true
				}
				if InStr(var,"O") {
					opt.OmitEnding.Value := true
				}
			}
		}

		rowSubmit(*) {
			val1 := box1.Value
			val2 := box2.Value
			if ((val1=""))||(val2="") {													; either hotstring or replacement are blank, continue editing
				rowGUI.Hide
				MsgBox("Missing value"
					. "`nHotstring - " val1
					. "`nReplacement - " val2
					,"ERROR","IconX")
				rowGUI.Show
				return
			}
			rowGUI.Submit
			return
		}
		rowClose(*) {																; on [x] restore original values
			box1.Value := textStr
			box2.Value := textRep
			rowGUI.closed := true
		}

		rowDelete(*) {
			ok := MsgBox("Are you sure you want to delete this hotkey?","Confirmation","OKCancel IconX 0x1000")
			if (ok="OK") {
				rowGUI.delete := true
				rowGUI.Submit
				return
			} else {
				rowGUI.Show
				return
			}
		}
	}

	closeGUI(*) {
		saveKeys()
		loadKeys()
		strGUI.Destroy()
	}

	saveKeys() {
		res := buildOut()
		if (res="") {
			return
		}
		try FileDelete(dPath)
		FileAppend(res,dPath)
	}

	buildOut() {
		res := ""
		rows := strLV.GetCount() 
		loop rows
		{
			t1 := strLV.GetText(A_Index,2)
			t2 := strLV.GetText(A_Index,3)
			t3 := strLV.GetText(A_Index,4)
			if (t2="")&&(t3="") {
				continue
			} 
			res .= t1 t2 "::" t3 "`n"
		}
		return res
	}
}

#Include includes\
#Include strx2.ahk
#Include AutoCorrect.ahk
