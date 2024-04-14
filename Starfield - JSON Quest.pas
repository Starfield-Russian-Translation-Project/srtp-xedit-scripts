{
  Export selected quests data for Starfield
  Apply to quest record(s)
}
unit ExportQuestsMap;

var
  slExport: TStringList;
  jsonQuestList: string;

//============================================================================
function GetSafeString(str: string): string;
begin
  Result := StringReplace(str, '"', '\"', [rfReplaceAll]);
end;

//============================================================================
function Initialize: integer;
begin
  slExport := TStringList.Create;
  jsonQuestList := '[';
end;

//============================================================================
procedure ExportQuest(quest: IInterface);
var
  i, j: integer;
  jsonStages, jsonObjectives, jsonAliases, jsonLogEntries: string;
  jsonQuest, jsonStage, jsonLogEntry, jsonObjective, jsonAlias: string;
  signature, formId, editorId, fullname, questType, stageIndex, note, cnam, displayText, flag, aliasName, actor: string;
  stages, objectives, aliases: IwbContainer;
  recordHeader, currentStage, indx, logEntries, currentLogEntry, currentObjective, currentAlias, uniqueActor: IwbElement;
begin
  jsonQuest := '{';

  recordHeader := ElementByName(quest, 'Record Header');

  signature := GetElementEditValues(recordHeader, 'Signature');
  formId := GetElementEditValues(recordHeader, 'FormID');
  editorId := GetElementEditValues(quest, 'EDID - Editor ID');
  fullname := GetElementEditValues(quest, 'FULL - Name');
  questType := GetElementEditValues(quest, 'QTYP - Quest Type');

  jsonQuest := jsonQuest + '"signature": "' + GetSafeString(signature) + '",';
  jsonQuest := jsonQuest + '"formId": "' + GetSafeString(formId) + '",';
  jsonQuest := jsonQuest + '"editorId": "' + GetSafeString(editorId) + '",';
  jsonQuest := jsonQuest + '"fullname": "' + GetSafeString(fullname) + '",';
  jsonQuest := jsonQuest + '"questType": "' + GetSafeString(questType) + '",';

  stages := ElementByName(quest, 'Stages');
  objectives := ElementByName(quest, 'Objectives');
  aliases := ElementByName(quest, 'Aliases');

  // reading Stages
  for i := 0 to Pred(ElementCount(stages)) do begin
    jsonStage := '{';
    jsonLogEntries := '';

    currentStage := ElementByIndex(stages, i);
    indx := ElementByName(currentStage, 'INDX - Stage Index');
    logEntries := ElementByName(currentStage, 'Log Entries');
    stageIndex := GetElementEditValues(indx, 'Stage Index');

    jsonStage := jsonStage + '"stageIndex": "' + GetSafeString(stageIndex) + '",';

    // reading Log Entries
    for j := 0 to Pred(ElementCount(logEntries)) do begin
      jsonLogEntry := '{';

      currentLogEntry := ElementByIndex(logEntries, j);
      note := GetElementEditValues(currentLogEntry, 'NAM2 - Note');
      cnam := GetElementEditValues(currentLogEntry, 'CNAM - Log Entry');

      jsonLogEntry := jsonLogEntry + '"note": "' + GetSafeString(note) + '",';
      jsonLogEntry := jsonLogEntry + '"cnam": "' + GetSafeString(cnam) + '"';
      jsonLogEntry := jsonLogEntry + '}';

      if (j <> ElementCount(logEntries) - 1) then
        jsonLogEntry := jsonLogEntry + ',';

      jsonLogEntries := jsonLogEntries + jsonLogEntry;
    end;

    jsonStage := jsonStage + '"logEntries": [' + jsonLogEntries + ']}';

    if (i <> ElementCount(stages) - 1) then
        jsonStage := jsonStage + ',';
    
    jsonStages := jsonStages + jsonStage;
  end;

  jsonQuest := jsonQuest + '"stages": [' + jsonStages + '],';

  // reading Objectives
  for i := 0 to Pred(ElementCount(objectives)) do begin
    currentObjective := ElementByIndex(objectives, i);
    displayText := GetElementEditValues(currentObjective, 'NNAM - Display Text');

    jsonObjective := '{"displayText": "' + GetSafeString(displayText) + '"}';

    if (i <> ElementCount(objectives) - 1) then
        jsonObjective := jsonObjective + ',';

    jsonObjectives := jsonObjectives + jsonObjective;
  end;

  jsonQuest := jsonQuest + '"objectives": [' + jsonObjectives + '],';

  // reading Aliases
  for i := 0 to Pred(ElementCount(aliases)) do begin
    jsonAlias := '{';

    currentAlias := ElementByIndex(aliases, i);
    aliasName := GetElementEditValues(currentAlias, 'ALID - Alias Name');
    flag := GetElementEditValues(currentAlias, 'FNAM - Flags');
    uniqueActor := ElementByName(currentAlias, 'Unique Actor');
    actor := GetElementEditValues(uniqueActor, 'ALUA - Unique Actor');

    jsonAlias := jsonAlias + '"aliasName": "' + GetSafeString(aliasName) + '",';
    jsonAlias := jsonAlias + '"flag": "' + GetSafeString(flag) + '",';
    jsonAlias := jsonAlias + '"actor": "' + GetSafeString(actor) + '"}';

    if (i <> ElementCount(aliases) - 1) then
        jsonAlias := jsonAlias + ',';

    jsonAliases := jsonAliases + jsonAlias;    
  end;

  jsonQuest := jsonQuest + '"aliases": [' + jsonAliases + ']';
  jsonQuestList := jsonQuestList + jsonQuest + '},';
end;

//============================================================================
function Process(e: IInterface): integer;
var
  s: string;
  sl: TStringList;
begin
  if (Signature(e) = 'QUST') then
    ExportQuest(e);
end;

//============================================================================
function Finalize: integer;
var
  dlgSave: TSaveDialog;
  ExportFileName: string;
begin
  AddMessage('Finalize');

  dlgSave := TSaveDialog.Create(nil);
  jsonQuestList := jsonQuestList + ']';
    try
      dlgSave.Options := dlgSave.Options + [ofOverwritePrompt];
      dlgSave.Filter := 'JSON (*.json)|*.json';
      dlgSave.InitialDir := ScriptsPath;
      dlgSave.FileName := 'starfield_quests.json';
      if dlgSave.Execute then begin
        ExportFileName := dlgSave.FileName;
        AddMessage('Saving ' + ExportFileName);
        AddMessage('JSON: ' + jsonQuestList);
        slExport.Insert(0, jsonQuestList);
        slExport.SaveToFile(ExportFileName);
      end;
    finally
      dlgSave.Free;
    end;
  slExport.Free;
end;

end.
