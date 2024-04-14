{
  Export selected quest scenes for Starfield
  Apply to quest record(s)
}
unit ExportSceneMap;

var
  slExport: TStringList;
  jsonSceneList: string;

//============================================================================
function GetSafeString(str: string): string;
begin
  Result := StringReplace(str, '"', '\"', [rfReplaceAll]);
end;

//============================================================================
function Initialize: integer;
begin
  slExport := TStringList.Create;
  jsonSceneList := '[';
end;

//============================================================================
procedure ExportScene(scene: IInterface);
var
  i, j: integer;
  signature, formId, editorId, notes, actionType, topic, playerTopic, playerResponse: string;
  jsonScene, jsonAction, jsonActions, jsonPlayerDialogue, jsonPlayerDialogues: string;
  actions, dialogueList: IwbContainer;
  recordHeader, currentAction, currentPlayerDialogue, dialogue: IwbElement;
begin
  jsonScene := '{';

  recordHeader := ElementByName(scene, 'Record Header');
  actions := ElementByName(scene, 'Actions');

  signature := GetElementEditValues(recordHeader, 'Signature');
  formId := GetElementEditValues(recordHeader, 'FormID');
  editorId := GetElementEditValues(scene, 'EDID - Editor ID');
  notes := GetElementEditValues(scene, 'NNAM - Notes');

  jsonScene := jsonScene + '"signature": "' + GetSafeString(signature) + '",';
  jsonScene := jsonScene + '"formId": "' + GetSafeString(formId) + '",';
  jsonScene := jsonScene + '"editorId": "' + GetSafeString(editorId) + '",';
  jsonScene := jsonScene + '"notes": "' + GetSafeString(notes) + '",';

  // reading Responses
  for i := 0 to Pred(ElementCount(actions)) do begin
    jsonAction := '{';

    currentAction := ElementByIndex(actions, i);
    actionType := GetElementEditValues(currentAction, 'ANAM - Type');
  
    jsonAction := jsonAction + '"type": "' + GetSafeString(actionType) + '",';

    if (actionType = 'Dialogue') then
    begin
      dialogue := ElementByName(currentAction, 'Dialogue');
      topic := GetElementEditValues(dialogue, 'DATA - Topic');

      jsonAction := jsonAction + '"topic": "' + GetSafeString(topic) + '"';
    end;

    if (actionType = 'Player Dialogue') then
    begin
      dialogue := ElementByName(currentAction, 'Player Dialogue');
      dialogueList := ElementByName(dialogue, 'Dialogue List');
      jsonPlayerDialogues := '';

      for j := 0 to Pred(ElementCount(dialogueList)) do begin
        jsonPlayerDialogue := '{';

        currentPlayerDialogue := ElementByIndex(dialogueList, j);
        playerTopic := GetElementEditValues(currentPlayerDialogue, 'ESCE - Player Choice');
        playerResponse := GetElementEditValues(currentPlayerDialogue, 'ESCS - NPC Response');

        jsonPlayerDialogue := jsonPlayerDialogue + '"topic": "' + GetSafeString(playerTopic) + '",';
        jsonPlayerDialogue := jsonPlayerDialogue + '"response": "' + GetSafeString(playerResponse) + '"},';

        jsonPlayerDialogues := jsonPlayerDialogues + jsonPlayerDialogue;
      end;

      jsonAction := jsonAction + '"dialogues": [' + jsonPlayerDialogues + ']';
    end;

    jsonAction := jsonAction + '}';

    if (i <> ElementCount(actions) - 1) then
        jsonAction := jsonAction + ',';

    jsonActions := jsonActions + jsonAction;    
  end;

  jsonScene := jsonScene + '"actions": [' + jsonActions + ']},';
  jsonSceneList := jsonSceneList + jsonScene;
end;

//============================================================================
function Process(e: IInterface): integer;
var
  s: string;
  sl: TStringList;
begin
  if (Signature(e) = 'SCEN') then
    ExportScene(e);
end;

//============================================================================
function Finalize: integer;
var
  dlgSave: TSaveDialog;
  ExportFileName: string;
begin
  AddMessage('Finalize');

  dlgSave := TSaveDialog.Create(nil);
  jsonSceneList := jsonSceneList + ']';
    try
      dlgSave.Options := dlgSave.Options + [ofOverwritePrompt];
      dlgSave.Filter := 'JSON (*.json)|*.json';
      dlgSave.InitialDir := ScriptsPath;
      dlgSave.FileName := 'starfield_scenes.json';
      if dlgSave.Execute then begin
        ExportFileName := dlgSave.FileName;
        AddMessage('Saving ' + ExportFileName);
        AddMessage('JSON: ' + jsonSceneList);
        slExport.Insert(0, jsonSceneList);
        slExport.SaveToFile(ExportFileName);
      end;
    finally
      dlgSave.Free;
    end;
  slExport.Free;
end;

end.
