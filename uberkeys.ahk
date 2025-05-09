/*	Personal hotkeys for general use
 *
 */
#Requires AutoHotkey v2+

+#d::toggletheme()																		; Shift+Win+D = toggle Windows DARK/LIGHT mode


;#######################################################################################
toggletheme()
{
	path := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
	lightApps := "AppsUseLightTheme"
	lightSystem := "SystemUsesLightTheme"

	try {
		if (RegRead(path, lightApps) = 0) {
			RegWrite(1, "REG_DWORD", path, lightApps)
			RegWrite(1, "REG_DWORD", path, lightSystem)
		} else {
			RegWrite(0, "REG_DWORD", path, lightApps)
			RegWrite(0, "REG_DWORD", path, lightSystem)
		}
	}
}

#Include includes\
#Include AutoCorrect.ahk
