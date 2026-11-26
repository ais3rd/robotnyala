unit TestCamera;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

implementation

uses TinyTest, GameCamera;

procedure TestDirectionBasics;
begin
  Check(SpriteDirection(0, 0, 0, 0, -3) = 0, 'camera in front -> 0');
  Check(SpriteDirection(0, 0, 0, -3, 0) = 2, 'camera at robot''s left -> 2');
  Check(SpriteDirection(0, 0, 0, 0, 3) = 4, 'camera behind -> 4');
  Check(SpriteDirection(0, 0, 0, 3, 0) = 6, 'camera at robot''s right -> 6');
  Check(SpriteDirection(0, 0, 0, -2, -2) = 1, 'front-left diagonal -> 1');
  Check(SpriteDirection(0, 0, 90, 0, -3) = 6, 'robot turned left, camera ahead of the room -> its right');
end;

procedure TestDirectionWraps;
begin
  Check(SpriteDirection(0, 0, 350, 0.5, -3) = 0, 'facing 350, camera ~10 deg off the face -> 0');
end;

procedure TestFacingToward;
begin
  CheckNear(FacingToward(0, -2, 0, 0), 180, 'enemy at -Z faces +Z toward the player');
  CheckNear(FacingToward(0, 0, 0, -2), 0, 'toward -Z is 0');
  CheckNear(FacingToward(0, 0, -1, 0), 90, 'toward -X is 90 (left)');
end;

{ operator stands at ringside beside the robot (its right side), a little toward its own end }
procedure TestOperatorRingside;
var
  X, Z: Single;
begin
  OperatorCamera(0, 0, 0, X, Z);
  CheckNear(X, 5.8, 'facing -Z: on the +X ring side'); CheckNear(Z, 2.03, 'a bit toward its own end');
  OperatorCamera(0, 0, 90, X, Z);
  CheckNear(X, 2.03, 'turned left, x'); CheckNear(Z, -5.8, 'turned left: on the -Z ring side');
end;

procedure TestOperatorDiagonal;
var
  X, Z: Single;
begin
  OperatorCamera(0, 0, 45, X, Z);
  CheckNear(X, 5.8, 'facing a corner: still on the rail, x');
  CheckNear(Z, -2.792, 'facing a corner, z');
end;

procedure TestOperatorMinDistance;
var
  X, Z: Single;
begin
  OperatorCamera(4.5, 0, 0, X, Z);
  CheckNear(X, 6.860, 'robot at the ropes: at least 2.5 m away, x');
  CheckNear(Z, 0.826, 'robot at the ropes, z');
end;

procedure TestThreeQuarter;
var
  X, Z: Single;
begin
  ThreeQuarterCamera(0, 0, 0, 0, -2, X, Z);
  CheckNear(X, 3.536, '3/4 camera x');
  CheckNear(Z, 2.536, '3/4 camera z');
end;

initialization
  RegisterTest('Camera.TestDirectionBasics', TestDirectionBasics);
  RegisterTest('Camera.TestDirectionWraps', TestDirectionWraps);
  RegisterTest('Camera.TestFacingToward', TestFacingToward);
  RegisterTest('Camera.TestOperatorRingside', TestOperatorRingside);
  RegisterTest('Camera.TestOperatorDiagonal', TestOperatorDiagonal);
  RegisterTest('Camera.TestOperatorMinDistance', TestOperatorMinDistance);
  RegisterTest('Camera.TestThreeQuarter', TestThreeQuarter);
end.
