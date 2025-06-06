/*	Personal hotkeys for general use
 *
 */
#Requires AutoHotkey v2+

+#d::toggletheme()																		; Shift+Win+D = toggle Windows DARK/LIGHT mode
#CapsLock::changeCase()

if FileExist(".\custom.ahk") {
	loop read ".\custom.ahk" {
		k := A_LoopReadLine
		parseHotString(k)
	}
}

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

parseHotString(str)
{
	a := StrX(str,"",2,0,"::",1,2)
	b := StrX(str,"::",0,2,"",0,0)
	Hotstring(a,b)
}

#Include includes\
#Include strx2.ahk
#Include AutoCorrect.ahk
