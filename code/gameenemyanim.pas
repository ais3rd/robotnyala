{ Which frame of the enemy sprite sheet to show (data/images/enemy_sheet*.png).
  No Castle Game Engine units here, so it can be unit-tested.

  Frame order (rendered by art/enemy_boxer07.html?export):
    0..3   idle bounce (loops)
    4..6   KO: stagger, knees buckle, slumped down (holds on 6)
    7..24  hit reactions, 2 frames each (full, half recovered), one per punch:
           jab, cross, left hook, right hook, left uppercut, right uppercut,
           left body, right body, haymaker }
unit GameEnemyAnim;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

uses GameCommands;

const
  EnemyFrameCount = 25;
  IdleFps = 6;
  HitTime = 0.3;          // whole hit reaction
  HitFirstFrameTime = 0.12;
  KOFrameTime = 0.18;     // per KO frame before holding the last one

type
  TEnemyAnimator = class
  private
    FTime: Single;        // drives the idle loop
    FHitLeft: Single;
    FHitFirst: Integer;   // first frame of the current reaction
    FKOTime: Single;      // < 0 when not KO
  public
    constructor Create;
    { Start the reaction to the punch that landed. Ignored while KO. }
    procedure Hit(Punch: TRobotCommand);
    procedure Update(SecondsPassed: Single; IsKO: Boolean);
    { 0-based frame index in the sheet. }
    function Frame: Integer;
  end;

implementation

constructor TEnemyAnimator.Create;
begin
  inherited Create;
  FKOTime := -1;
end;

procedure TEnemyAnimator.Hit(Punch: TRobotCommand);
begin
  if FKOTime >= 0 then
    Exit;
  { punches are the first 9 commands, in reaction order }
  if Punch > rcHaymaker then
    Exit;
  FHitFirst := 7 + Ord(Punch) * 2;
  FHitLeft := HitTime;
end;

procedure TEnemyAnimator.Update(SecondsPassed: Single; IsKO: Boolean);
begin
  FTime := FTime + SecondsPassed;
  if IsKO then
  begin
    if FKOTime < 0 then
      FKOTime := 0;
    FKOTime := FKOTime + SecondsPassed;
    FHitLeft := 0;
  end else
  begin
    FKOTime := -1;
    if FHitLeft > 0 then
      FHitLeft := FHitLeft - SecondsPassed;
  end;
end;

function TEnemyAnimator.Frame: Integer;
var
  K: Integer;
begin
  if FKOTime >= 0 then
  begin
    K := Trunc(FKOTime / KOFrameTime);
    if K > 2 then K := 2;
    Result := 4 + K;
  end else
  if FHitLeft > 0 then
  begin
    if FHitLeft > HitTime - HitFirstFrameTime then
      Result := FHitFirst
    else
      Result := FHitFirst + 1;
  end else
    Result := Trunc(FTime * IdleFps) mod 4;
end;

end.
