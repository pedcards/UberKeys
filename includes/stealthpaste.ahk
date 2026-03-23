
StealthPaste(text) {
    ; --- 1) backup clipboard (all formats) ---
    temp_clipboard := ClipboardAll()  ; preserves images/HTML too

    ; --- 2) read & (if needed) disable clipboard history ---
    state := _GetClipboardHistoryState()  ; {UserEnabled: Bool, PolicyAllowed: Bool}
    changedHistory := false
    try {
        if (state.PolicyAllowed && state.UserEnabled) {
            _SetClipboardHistory(0)       ; disable per-user toggle
            changedHistory := true
            Sleep 120                      ; give Windows a moment to apply
        }

        ; --- 3) load & paste ---
        A_Clipboard := text
        ; Wait until clipboard has data (don’t require a “change”): more robust.
        ClipWait(0.5, false)
        Send "^v"
        Sleep 60                          ; ensure target app finishes paste
    } finally {
        ; --- 4) always restore clipboard and history ---
        try {
            A_Clipboard := temp_clipboard
        } catch {
            ; ignore (rare: clipboard locked by another app)
        }
        temp_clipboard := ""              ; free memory

        if (changedHistory) {
            _SetClipboardHistory(1)
            Sleep 80
        }
    }
}

_GetClipboardHistoryState() {
    st := { UserEnabled: false, PolicyAllowed: true }

    ; User toggle (per-user)
    try {
        st.UserEnabled := (RegRead("HKCU\\Software\\Microsoft\\Clipboard", "EnableClipboardHistory") = 1)
    } catch {
        st.UserEnabled := false
    }

    ; Policy (machine) – if present and 0, history is disallowed regardless of user toggle
    try {
        st.PolicyAllowed := (RegRead("HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\System", "AllowClipboardHistory") != 0)
    } catch {
        st.PolicyAllowed := true  ; no policy => allowed
    }
    return st
}

_SetClipboardHistory(onOff) {
    ; onOff: 0 = Off, 1 = On (per-user toggle)
    RegWrite onOff, "REG_DWORD", "HKCU\\Software\\Microsoft\\Clipboard", "EnableClipboardHistory"
}
