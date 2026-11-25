{ Unit tests for the game rules (no Castle Game Engine needed).
  Delphi: open this .dpr and press F9.
  Free Pascal: see the Tests section of README.md. }
program robotnyala_tests;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}
{$APPTYPE CONSOLE}

uses
  TinyTest in 'TinyTest.pas',
  GameCommands in '..\code\gamecommands.pas',
  GameRobot in '..\code\gamerobot.pas',
  GameCombat in '..\code\gamecombat.pas',
  TestCommands in 'TestCommands.pas',
  TestRobot in 'TestRobot.pas',
  TestCombat in 'TestCombat.pas';

begin
  ExitCode := RunAllTests;
  {$ifndef FPC}
  if DebugHook <> 0 then
  begin
    Write('Press Enter to close...');
    ReadLn;
  end;
  {$endif}
end.
