unit TestCombat;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

implementation

uses TinyTest, GameCombat;

procedure TestInReach;
begin
  Check(PunchHits(0, 0, 0, 0, -1.4), 'enemy 1.4 m straight ahead is hit');
end;

procedure TestOutOfReach;
begin
  Check(not PunchHits(0, 0, 0, 0, -2.0), 'enemy 2 m ahead is out of reach');
end;

procedure TestOutOfAngle;
begin
  Check(not PunchHits(0, 0, 90, 0, -1.0), 'turned 90 degrees left: miss');
  Check(PunchHits(0, 0, 20, 0, -1.0), 'turned 20 degrees: still within 30');
  Check(PunchHits(0, 0, 90, -1.0, 0), 'turned 90 left, enemy to the left: hit');
end;

procedure TestHitAndKO;
var
  E: TEnemyState;
begin
  E := TEnemyState.Create;
  try
    Check(E.HP = MaxHP, 'starts at full HP');
    E.Hit(25); E.Hit(25); E.Hit(25);
    Check((E.HP = 25) and not E.IsKO, '25 HP left after three hits');
    E.Hit(25);
    Check((E.HP = 0) and E.IsKO, 'KO at 0 HP');
  finally
    E.Free;
  end;
end;

procedure TestNoDamageWhileKO;
var
  E: TEnemyState;
begin
  E := TEnemyState.Create;
  try
    E.Hit(200);
    Check((E.HP = 0) and E.IsKO, 'overkill clamps to 0');
    E.Hit(25);
    Check(E.HP = 0, 'no damage while KO');
    E.Update(1.0);
    E.Update(1.0);
    E.Hit(25);
    Check(E.IsKO, 'still KO after 2 s; hit did not restart anything');
    E.Update(1.1);
    Check((E.HP = MaxHP) and not E.IsKO, 'reset to full HP after 3 s');
  finally
    E.Free;
  end;
end;

procedure TestMoveClamped;
var
  X, Z: Single;
  I: Integer;
begin
  X := 0; Z := 0;
  for I := 1 to 5 do
    ClampedStep(X, Z, 0, -0.5, 0, -2);
  CheckNear(Z, -1.2, 'stops 0.8 m from the enemy');
  CheckNear(X, 0, 'no sideways drift');

  ClampedStep(X, Z, 0, 0.5, 0, -2);
  CheckNear(Z, -0.7, 'can step back away from the enemy');

  X := 0; Z := 0;
  ClampedStep(X, Z, 10, 0, 0, -2);
  CheckNear(X, RoomHalfSize, 'clamped to the room wall');
end;

initialization
  RegisterTest('Combat.TestInReach', TestInReach);
  RegisterTest('Combat.TestOutOfReach', TestOutOfReach);
  RegisterTest('Combat.TestOutOfAngle', TestOutOfAngle);
  RegisterTest('Combat.TestHitAndKO', TestHitAndKO);
  RegisterTest('Combat.TestNoDamageWhileKO', TestNoDamageWhileKO);
  RegisterTest('Combat.TestMoveClamped', TestMoveClamped);
end.
