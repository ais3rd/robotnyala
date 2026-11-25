unit TestCommands;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

implementation

uses TinyTest, GameCommands;

procedure TestExact;
var
  C: TRobotCommand;
begin
  Check(ParseCommand('jab', C), 'jab parses');
  Check(C = rcJab, 'jab is rcJab');
end;

procedure TestAlias;
var
  C: TRobotCommand;
begin
  Check(ParseCommand('guard', C) and (C = rcBlock), 'guard = block');
  Check(ParseCommand('body shot', C) and (C = rcLeftBody), 'body shot = left body');
  Check(ParseCommand('left jab', C) and (C = rcJab), 'left jab = jab');
  Check(ParseCommand('right straight', C) and (C = rcCross), 'right straight = cross');
end;

procedure TestWisprPunctuation;
var
  C: TRobotCommand;
begin
  Check(ParseCommand('Left hook.', C) and (C = rcLeftHook), 'Left hook. = left hook');
  Check(ParseCommand('  Stop!  ', C) and (C = rcStop), 'Stop! = stop');
  Check(ParseCommand('One, two.', C) and (C = rcOneTwo), 'One, two. = one two');
  Check(ParseCommand('One-two.', C) and (C = rcOneTwo), 'One-two. = one two');
  Check(ParseCommand('Dodge-left!', C) and (C = rcDodgeLeft), 'hyphen separates words');
end;

procedure TestRightIsStep;
var
  C: TRobotCommand;
begin
  Check(ParseCommand('right', C) and (C = rcStepRight), 'right = step right');
  Check(ParseCommand('left', C) and (C = rcStepLeft), 'left = step left');
end;

procedure TestNoFuzzy;
var
  C: TRobotCommand;
begin
  Check(not ParseCommand('jap', C), 'jap is not accepted');
end;

procedure TestNoMulti;
var
  C: TRobotCommand;
begin
  Check(not ParseCommand('jab jab', C), 'jab jab is not accepted');
end;

procedure TestEmptyIgnored;
begin
  Check(CleanCommandText('  . ') = '', 'punctuation-only text cleans to empty');
end;

procedure TestEveryCommandHasName;
var
  C: TRobotCommand;
begin
  for C := Low(TRobotCommand) to High(TRobotCommand) do
    Check(CommandName(C) <> '', 'every command has a display name');
  Check(CommandName(rcLeftHook) = 'LEFT HOOK', 'display name of left hook');
end;

initialization
  RegisterTest('Commands.TestExact', TestExact);
  RegisterTest('Commands.TestAlias', TestAlias);
  RegisterTest('Commands.TestWisprPunctuation', TestWisprPunctuation);
  RegisterTest('Commands.TestRightIsStep', TestRightIsStep);
  RegisterTest('Commands.TestNoFuzzy', TestNoFuzzy);
  RegisterTest('Commands.TestNoMulti', TestNoMulti);
  RegisterTest('Commands.TestEmptyIgnored', TestEmptyIgnored);
  RegisterTest('Commands.TestEveryCommandHasName', TestEveryCommandHasName);
end.
