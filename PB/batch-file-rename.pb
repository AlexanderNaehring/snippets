; batch file rename

path$ = PathRequester("Select Path", "\\nas\private\private\p\A N\14-03-30\")

If path$ = ""
  End
EndIf

Debug "scan "+path$


dir = ExamineDirectory(#PB_Any, path$, "")

If Not dir
  End
EndIf

While NextDirectoryEntry(dir)
  entry$ = DirectoryEntryName(dir)
  
  If DirectoryEntryType(dir) = #PB_DirectoryEntry_File
    old$ = entry$
    new$ = entry$
    
    new$ = ReplaceString(new$, ".jpeg", ".jpg", #PB_String_NoCase)
    new$ = RemoveString(new$, "IMG-20", #PB_String_NoCase)
    new$ = RemoveString(new$, "IMG_20", #PB_String_NoCase)
    new$ = RemoveString(new$, "VID-20", #PB_String_NoCase)
    new$ = RemoveString(new$, "VID_20", #PB_String_NoCase)
    
    If new$ = old$
      Continue
    EndIf
    
    
    old$ = path$ + old$
    new$ = path$ + new$
    
    If Not RenameFile(old$, new$)
      i = 1
      Repeat
        new$ = GetPathPart(new$) + GetFilePart(new$, #PB_FileSystem_NoExtension) + "-" + Str(i) + "." + GetExtensionPart(new$)
        i + 1
      Until RenameFile(old$, new$)
    EndIf
    
    Debug "{"+GetFilePart(old$)+"} -> {"+GetFilePart(new$)+"}"
  EndIf
  
Wend

FinishDirectory(dir)
Debug "end"
End

; IDE Options = PureBasic 5.30 (Windows - x64)
; CursorPosition = 2
; EnableUnicode
; EnableXP