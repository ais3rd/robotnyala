{ Robot voice commands: the list of commands and turning typed/dictated text
  into one command. No Castle Game Engine units here, so it can be unit-tested. }
unit GameCommands;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

type
  TRobotCommand = (
    { punches }
    rcJab, rcCross, rcLeftHook, rcRightHook, rcLeftUppercut, rcRightUppercut,
    rcLeftBody, rcRightBody, rcHaymaker,
    { defense }
    rcBlock, rcDuck, rcDodgeLeft, rcDodgeRight,
    { movement }
    rcForward, rcBack, rcStepLeft, rcStepRight, rcTurnLeft, rcTurnRight,
    { combos }
    rcOneTwo, rcCombo,
    { control }
    rcStop
  );

{ Lowercase, remove punctuation, collapse spaces, trim.
  'Left hook.' -> 'left hook'. }
function CleanCommandText(const S: string): string;

{ Exact match of the cleaned text against a command or one of its aliases.
  One command per text; no misspelling tolerance. }
function ParseCommand(const S: string; out Cmd: TRobotCommand): Boolean;

{ Text to show on screen, e.g. 'LEFT HOOK'. }
function CommandName(Cmd: TRobotCommand): string;

{ Every accepted phrase, joined with '|' (what the speech recognizer listens for). }
function AllPhrases: string;

implementation

uses SysUtils;

type
  TPhrase = record
    Text: string;
    Cmd: TRobotCommand;
  end;

const
  Phrases: array [0..27] of TPhrase = (
    (Text: 'jab';            Cmd: rcJab),
    (Text: 'left jab';       Cmd: rcJab),
    (Text: 'cross';          Cmd: rcCross),
    (Text: 'right straight'; Cmd: rcCross),
    (Text: 'left hook';      Cmd: rcLeftHook),
    (Text: 'right hook';     Cmd: rcRightHook),
    (Text: 'left uppercut';  Cmd: rcLeftUppercut),
    (Text: 'right uppercut'; Cmd: rcRightUppercut),
    (Text: 'left body';      Cmd: rcLeftBody),
    (Text: 'body shot';      Cmd: rcLeftBody),
    (Text: 'right body';     Cmd: rcRightBody),
    (Text: 'haymaker';       Cmd: rcHaymaker),
    (Text: 'block';          Cmd: rcBlock),
    (Text: 'guard';          Cmd: rcBlock),
    (Text: 'duck';           Cmd: rcDuck),
    (Text: 'dodge left';     Cmd: rcDodgeLeft),
    (Text: 'dodge right';    Cmd: rcDodgeRight),
    (Text: 'forward';        Cmd: rcForward),
    (Text: 'back';           Cmd: rcBack),
    (Text: 'left';           Cmd: rcStepLeft),
    (Text: 'step left';      Cmd: rcStepLeft),
    (Text: 'right';          Cmd: rcStepRight),
    (Text: 'step right';     Cmd: rcStepRight),
    (Text: 'turn left';      Cmd: rcTurnLeft),
    (Text: 'turn right';     Cmd: rcTurnRight),
    (Text: 'one two';        Cmd: rcOneTwo),
    (Text: 'combo';          Cmd: rcCombo),
    (Text: 'stop';           Cmd: rcStop)
  );

  Names: array [TRobotCommand] of string = (
    'JAB', 'CROSS', 'LEFT HOOK', 'RIGHT HOOK', 'LEFT UPPERCUT', 'RIGHT UPPERCUT',
    'LEFT BODY', 'RIGHT BODY', 'HAYMAKER',
    'BLOCK', 'DUCK', 'DODGE LEFT', 'DODGE RIGHT',
    'FORWARD', 'BACK', 'STEP LEFT', 'STEP RIGHT', 'TURN LEFT', 'TURN RIGHT',
    'ONE TWO', 'COMBO',
    'STOP'
  );

function CleanCommandText(const S: string): string;
var
  Lower: string;
  I: Integer;
  PendingSpace: Boolean;
begin
  Lower := LowerCase(S);
  Result := '';
  PendingSpace := False;
  for I := 1 to Length(Lower) do
  begin
    if CharInSet(Lower[I], ['a'..'z', '0'..'9']) then
    begin
      if PendingSpace and (Result <> '') then
        Result := Result + ' ';
      PendingSpace := False;
      Result := Result + Lower[I];
    end else
      { spaces and punctuation both separate words: 'One-two.' -> 'one two' }
      PendingSpace := True;
  end;
end;

function ParseCommand(const S: string; out Cmd: TRobotCommand): Boolean;
var
  Clean: string;
  I: Integer;
begin
  Clean := CleanCommandText(S);
  for I := Low(Phrases) to High(Phrases) do
    if Phrases[I].Text = Clean then
    begin
      Cmd := Phrases[I].Cmd;
      Exit(True);
    end;
  Cmd := rcStop;
  Result := False;
end;

function CommandName(Cmd: TRobotCommand): string;
begin
  Result := Names[Cmd];
end;

function AllPhrases: string;
var
  I: Integer;
begin
  Result := Phrases[Low(Phrases)].Text;
  for I := Low(Phrases) + 1 to High(Phrases) do
    Result := Result + '|' + Phrases[I].Text;
end;

end.
