{ Which column of the Glitchpop sprite sheet (data/images/glitchpop_sheet.png) to show.
  No Castle Game Engine units here, so it can be unit-tested.

  Columns: idle 0..3; then two frames (wind-up, extended) per punch:
  jab 4,5; cross 6,7; left hook 8,9; right hook 10,11; left uppercut 12,13;
  right uppercut 14,15; left body 16,17; right body 18,19; haymaker 20,21;
  then block 22; duck 23; dodge left 24; dodge right 25.
  Rows are the 8 view directions (see GameCamera.SpriteDirection). }
unit GamePlayerAnim;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

uses GameCommands;

const
  PlayerFrameCount = 26;
  PlayerIdleFps = 6;

function PlayerFrame(HasMove: Boolean; Move: TRobotCommand; Elapsed, IdleTime: Single): Integer;

implementation

uses GameRobot;

function PlayerFrame(HasMove: Boolean; Move: TRobotCommand; Elapsed, IdleTime: Single): Integer;
var
  First: Integer;
begin
  First := -1;
  if HasMove then
    case Move of
      rcJab:           First := 4;
      rcCross:         First := 6;
      rcLeftHook:      First := 8;
      rcRightHook:     First := 10;
      rcLeftUppercut:  First := 12;
      rcRightUppercut: First := 14;
      rcLeftBody:      First := 16;
      rcRightBody:     First := 18;
      rcHaymaker:      First := 20;
      rcBlock:         Exit(22);
      rcDuck:          Exit(23);
      rcDodgeLeft:     Exit(24);
      rcDodgeRight:    Exit(25);
    else ;
    end;
  if First < 0 then
    Exit(Trunc(IdleTime * PlayerIdleFps) mod 4);
  if Elapsed < MoveDuration(Move) / 2 then
    Result := First
  else
    Result := First + 1;
end;

end.
