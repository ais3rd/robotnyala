{ Which frame of the Glitchpop sprite sheet (data/images/glitchpop_sheet*.png) to show.
  No Castle Game Engine units here, so it can be unit-tested.

  Frames: idle 0..3; then 4 per punch (wind-up, strike, impact, recover), in the order
  jab, cross, left hook, right hook, left uppercut, right uppercut, left body, right body,
  haymaker (4..39); then block 40, duck 41, dodge left 42, dodge right 43.
  The sheet layout (direction rows, wrapped blocks) is GameCamera.SheetCell. }
unit GamePlayerAnim;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

uses GameCommands;

const
  PlayerFrameCount = 44;
  PlayerIdleFps = 6;

function PlayerFrame(HasMove: Boolean; Move: TRobotCommand; Elapsed, IdleTime: Single): Integer;

implementation

uses GameRobot;

function PlayerFrame(HasMove: Boolean; Move: TRobotCommand; Elapsed, IdleTime: Single): Integer;
var
  Phase: Integer;
begin
  if HasMove then
    case Move of
      rcJab..rcHaymaker:   // punches are the first 9 commands, in sheet order
        begin
          Phase := Trunc(Elapsed / MoveDuration(Move) * 4);
          if Phase > 3 then Phase := 3;
          Exit(4 + Ord(Move) * 4 + Phase);
        end;
      rcBlock:      Exit(40);
      rcDuck:       Exit(41);
      rcDodgeLeft:  Exit(42);
      rcDodgeRight: Exit(43);
    else ;
    end;
  Result := Trunc(IdleTime * PlayerIdleFps) mod 4;
end;

end.
