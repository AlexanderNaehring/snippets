; make json pretty
EnableExplicit


Global NewList files$()
Global i
Global tmp$

For i = 1 To CountProgramParameters()
  tmp$ = ProgramParameter()
  If tmp$ And FileSize(tmp$) > 0
    AddElement(files$())
    files$() = tmp$
  EndIf
Next

tmp$ = GetClipboardText()
If tmp$ And FileSize(tmp$) > 0
  AddElement(files$())
  files$() = tmp$
EndIf

If ListSize(files$()) = 0
  tmp$ = OpenFileRequester("Select JSON Files", "", "JSON Files|*.json", 0, #PB_Requester_MultiSelection)
  While tmp$
    If tmp$ And FileSize(tmp$) > 0
      AddElement(files$())
      files$() = tmp$
    EndIf
    tmp$ = NextSelectedFileName() 
  Wend 
EndIf


If ListSize(files$()) = 0
  End
EndIf


ForEach files$()
  Global json
  Global file$
  json = LoadJSON(#PB_Any, files$())
  If json
    file$ = GetPathPart(files$()) + GetFilePart(files$(), #PB_FileSystem_NoExtension) + "_pretty.json"
    SaveJSON(json, file$, #PB_JSON_PrettyPrint)
    FreeJSON(json)
  EndIf
Next
