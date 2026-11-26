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

procedure TestOperatorBehind;
var
  X, Z: Single;
begin
  OperatorCamera(0, 0, 0, X, Z);
  CheckNear(X, 0, 'behind, x'); CheckNear(Z, 5.8, 'behind, on the rail');
  OperatorCamera(0, 0, 90, X, Z);
  CheckNear(X, 5.8, 'turned left: rail on +X'); CheckNear(Z, 0, 'turned left, z');
end;

procedure TestOperatorDiagonal;
var
  X, Z: Single;
begin
  OperatorCamera(0, 0, 45, X, Z);
  CheckNear(X, 5.8, 'diagonal reaches the rail corner, x');
  CheckNear(Z, 5.8, 'diagonal reaches the rail corner, z');
end;

procedure TestOperatorMinDistance;
var
  X, Z: Single;
begin
  OperatorCamera(0, 4.5, 0, X, Z);
  CheckNear(X, 0, 'backed to the ropes, x');
  CheckNear(Z, 7.0, 'backed to the ropes: at least 2.5 m back');
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
  RegisterTest('Camera.TestOperatorBehind', TestOperatorBehind);
  RegisterTest('Camera.TestOperatorDiagonal', TestOperatorDiagonal);
  RegisterTest('Camera.TestOperatorMinDistance', TestOperatorMinDistance);
  RegisterTest('Camera.TestThreeQuarter', TestThreeQuarter);
end.
