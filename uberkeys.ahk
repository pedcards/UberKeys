/*	Personal hotkeys for general use
 *
 */
#Requires AutoHotkey v2+

+#d::toggletheme()																		; Shift+Win+D = toggle Windows DARK/LIGHT mode
#CapsLock::changeCase()

tray()
loadKeys()

;#######################################################################################
toggletheme()
{
	path := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

	try {
		light := (RegRead(path, "AppsUseLightTheme") = 0)								; 1 if starting at dark, 0 if starting at light
		RegWrite(light, "REG_DWORD", path, "AppsUseLightTheme")
		RegWrite(light, "REG_DWORD", path, "SystemUsesLightTheme")
	}
}

changeCase()
{
	capsMenu := Menu()
	capsMenu.Add("&UPPERCASE",doCopy)
	capsMenu.Add("&lowercase",doCopy)
	capsMenu.Add("&Title Case",doCopy)
	capsMenu.Add("&kebab-case",doCopy)
	capsMenu.Add("&snake_case",doCopy)
	capsMenu.Add("&(parentheses)",doCopy)
	capsMenu.Add("&'single quotes'",doCopy)
	capsMenu.Add("&`"double quotes`"",doCopy)
	capsMenu.Show()

	doCopy(fn, *) {
		clipSavedAll := ClipboardAll()
		A_Clipboard := ""

		Send("^c")

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
		Send("^v")
		Sleep(200)
		A_Clipboard := clipSavedAll
	}
}

getDictionary() {
	res := []
	if FileExist(".\custom.ahk") {
		loop read ".\custom.ahk" {
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
		Hotstring(res.a,res.b)
	}
}

parseHotString(str)
{
	RegExMatch(str,"(.*?)::(?!.*::)(.*?)$",&n)
	return {a:n[1],b:n[2]}
}

tray() {
	A_IconTip := "UberKeys"
	tray := A_TrayMenu
	tray.Add()
	tray.Add("UberKeys v" FileGetTime(A_ScriptName),(*)=>{})
	tray.Add("Edit hotstrings",stringEdit)
	tray.Default := "Edit hotstrings"
	tray.ClickCount := 1
}

stringEdit(*) {
	strGUI := Gui(,"UberKeys")
	strGUI.MarginX := 10
	strGUI.MarginY := 10
	strGUI.OnEvent("Close",closeGUI)
	strGUI.SetFont("bold s16")
	strGUI.AddText("w500 Center","Auto-correct Dictionary")
	strGUI.SetFont("Norm s12")
	strLV := strGUI.AddListView("w500 h200 Grid +Hdr -ReadOnly NoSortHdr",["",":Opts:Shortcut","Expansion"])
	strLV.OnEvent("DoubleClick",clickRow)
	strLV.ModifyCol(1,5)
	
	dict := getDictionary()
	for val in dict
	{
		res := parseHotString(val)
		strLV.Add("","",res.a,res.b)
	}

	strGUI.Show

	clickRow(LV,rownum) {
		if (rownum) {
			return
		}
		strLV.Add()
		strLV.Modify(strLV.GetCount(),"Select")
	}

	closeGUI(*) {
		if (lvEdit.Changes.Length)
		{
			res := buildOut()
			FileDelete(".\custom.ahk")
			FileAppend(res,".\custom.ahk")
		}
		loadKeys()
		strGUI.Destroy()
	}

	buildOut() {
		res := ""
		rows := strLV.GetCount() 
		loop rows
		{
			t1 := strLV.GetText(A_Index,2)
			t2 := strLV.GetText(A_Index,3)
			if (t1="")&&(t2="") {
				continue
			} else {
				res .= t1 "::" t2 "`n"
			}
		}
		return res
	}
}

#Include includes\
#Include strx2.ahk
#Include AutoCorrect.ahk
