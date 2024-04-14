{
  Export selected dialogues for Starfield
  Apply to quest record(s)
}
unit ExportSceneMap;

var
  slExport: TStringList;
  jsonDialogueList: string;

//============================================================================
function GetSafeString(str: string): string;
begin
  Result := StringReplace(str, '"', '\"', [rfReplaceAll]);
end;

//============================================================================
function Initialize: integer;
begin
  slExport := TStringList.Create;
  jsonDialogueList := '[';
end;

//============================================================================
procedure ExportDialogue(dialogue: IInterface);
var
  i, j: integer;
  topic, signature, formId, editorId, emotion, wem, text, scriptNotes, edits, voiceType: string;
  jsonDialogue, jsonResponses, jsonResponse, jsonVoiceTypes: string;
  responses, voiceTypes: IwbContainer;
  recordHeader, responseData, currentResponse, currentTrot: IwbElement;
  voiceTypeRecord: IwbMainRecord;
  mainFile: IwbFile;
begin
  jsonDialogue := '{';

  AddMessage('BaseName: ' + BaseName(dialogue));

  mainFile := GetFile(dialogue);

  recordHeader := ElementByName(dialogue, 'Record Header');
  responses := ElementByName(dialogue, 'Responses');

  topic := GetElementEditValues(dialogue, 'Topic');
  signature := GetElementEditValues(recordHeader, 'Signature');
  formId := GetElementEditValues(recordHeader, 'FormID');
  editorId := GetElementEditValues(dialogue, 'EDID - Editor ID');

  jsonDialogue := jsonDialogue + '"topic": "' + GetSafeString(topic) + '",';
  jsonDialogue := jsonDialogue + '"signature": "' + GetSafeString(signature) + '",';
  jsonDialogue := jsonDialogue + '"formId": "' + GetSafeString(formId) + '",';
  jsonDialogue := jsonDialogue + '"editorId": "' + GetSafeString(editorId) + '",';

  // reading Responses
  for i := 0 to Pred(ElementCount(responses)) do begin
    jsonResponse := '{';

    currentResponse := ElementByIndex(responses, i);
    responseData := ElementByName(currentResponse, 'TRDA - Response Data');
    emotion := GetElementEditValues(responseData, 'Emotion');
    wem := GetElementEditValues(responseData, 'WEM File');
    text := GetElementEditValues(currentResponse, 'NAM1 - Response Text');
    scriptNotes := GetElementEditValues(currentResponse, 'NAM2 - Script Notes');
    edits := GetElementEditValues(currentResponse, 'NAM3 - Edits');

    jsonResponse := jsonResponse + '"emotion": "' + GetSafeString(emotion) + '",';
    jsonResponse := jsonResponse + '"wem": "' + GetSafeString(wem) + '",';
    jsonResponse := jsonResponse + '"text": "' + GetSafeString(text) + '",';
    jsonResponse := jsonResponse + '"scriptNotes": "' + GetSafeString(scriptNotes) + '",';
    jsonResponse := jsonResponse + '"edits": "' + GetSafeString(edits) + '",';

    voiceTypes := ElementByName(currentResponse, 'Unknown');
    jsonVoiceTypes := '';

    // reading Voice Types
    for j := 0 to Pred(ElementCount(voiceTypes)) do begin
      currentTrot := ElementByIndex(voiceTypes, j);
      voiceType := GetElementEditValues(currentTrot, 'Unknown');

      jsonVoiceTypes := jsonVoiceTypes + '"' + GetSafeString(voiceType) + '"';

      if (j <> ElementCount(voiceTypes) - 1) then
        jsonVoiceTypes := jsonVoiceTypes + ',';
    end;

    jsonResponse := jsonResponse + '"voiceTypes": [' + jsonVoiceTypes + ']}';

    if (i <> ElementCount(responses) - 1) then
        jsonResponse := jsonResponse + ',';

    jsonResponses := jsonResponses + jsonResponse;    
  end;

  jsonDialogue := jsonDialogue + '"responses": [' + jsonResponses + ']},';
  jsonDialogueList := jsonDialogueList + jsonDialogue;
end;

//============================================================================
function Process(e: IInterface): integer;
var
  s: string;
  sl: TStringList;
begin
  if (Signature(e) = 'INFO') then
    ExportDialogue(e);
end;

//============================================================================
function Finalize: integer;
var
  dlgSave: TSaveDialog;
  s, json, ExportFileName: string;
begin
  AddMessage('Finalize');

  jsonDialogueList := jsonDialogueList + ']';
  dlgSave := TSaveDialog.Create(nil);
  try
    dlgSave.Options := dlgSave.Options + [ofOverwritePrompt];
    dlgSave.Filter := 'JSON (*.json)|*.json';
    dlgSave.InitialDir := ScriptsPath;
    dlgSave.FileName := 'starfield_dialogues.json';

    if dlgSave.Execute then 
    begin
      ExportFileName := dlgSave.FileName;
      AddMessage('Saving ' + ExportFileName);
      AddMessage('JSON: ' + jsonDialogueList);
      slExport.Insert(0, jsonDialogueList);
      slExport.SaveToFile(ExportFileName);
    end;

  finally
    dlgSave.Free;
  end; 

  slExport.Free;
end;
end.
