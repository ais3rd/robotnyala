{ Operator-style cameras and which of the 8 sprite directions to show.
  No Castle Game Engine units here, so it can be unit-tested.
  Same floor convention as GameCombat: FacingDeg 0 = looking toward -Z, positive = turned left. }
unit GameCamera;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

const
  RailHalfSize = 5.8;          // operator walks a rail just outside the ropes (ropes at 5 m)
  OperatorMinDistance = 2.5;
  ArenaHalfSize = 8.0;
  ThreeQuarterDistance = 5.0;

{ 0 = camera in front (sees the face), 2 = at the robot's left, 4 = behind, 6 = at its right. }
function SpriteDirection(RobotX, RobotZ, RobotFacingDeg, CamX, CamZ: Single): Integer;
{ Facing (degrees, 0..360) that looks from one point toward another. }
function FacingToward(FromX, FromZ, ToX, ToZ: Single): Single;
{ Behind the robot's back, on the rail outside the ropes (at least OperatorMinDistance away). }
procedure OperatorCamera(PX, PZ, FacingDeg: Single; out CX, CZ: Single);
{ Diagonal behind-right of the robot, looking at the midpoint of both robots. }
procedure ThreeQuarterCamera(PX, PZ, FacingDeg, EX, EZ: Single; out CX, CZ: Single);

implementation

uses Math, GameCombat;

function Clamp(Value, Lo, Hi: Single): Single;
begin
  if Value < Lo then Result := Lo else
  if Value > Hi then Result := Hi else
    Result := Value;
end;

function Wrap360(A: Single): Single;
begin
  Result := A - 360 * Floor(A / 360);
end;

{ inverse of FacingVector: (X, Z) = (-sin, -cos) }
function AngleOf(X, Z: Single): Single;
begin
  Result := RadToDeg(ArcTan2(-X, -Z));
end;

function SpriteDirection(RobotX, RobotZ, RobotFacingDeg, CamX, CamZ: Single): Integer;
begin
  Result := Round(Wrap360(AngleOf(CamX - RobotX, CamZ - RobotZ) - RobotFacingDeg) / 45) mod 8;
end;

function FacingToward(FromX, FromZ, ToX, ToZ: Single): Single;
begin
  Result := Wrap360(AngleOf(ToX - FromX, ToZ - FromZ));
end;

{ distance along a step D (one axis) from P until the rail at +-RailHalfSize }
function RailT(P, D: Single): Single;
begin
  if D > 1e-6 then Result := (RailHalfSize - P) / D else
  if D < -1e-6 then Result := (-RailHalfSize - P) / D else
    Result := 1e9;
end;

procedure OperatorCamera(PX, PZ, FacingDeg: Single; out CX, CZ: Single);
var
  FX, FZ, DX, DZ, T, TZ: Single;
begin
  FacingVector(FacingDeg, FX, FZ);
  DX := -FX;
  DZ := -FZ;
  T := RailT(PX, DX);
  TZ := RailT(PZ, DZ);
  if TZ < T then T := TZ;
  if T < OperatorMinDistance then
    T := OperatorMinDistance;
  CX := Clamp(PX + DX * T, -ArenaHalfSize, ArenaHalfSize);
  CZ := Clamp(PZ + DZ * T, -ArenaHalfSize, ArenaHalfSize);
end;

procedure ThreeQuarterCamera(PX, PZ, FacingDeg, EX, EZ: Single; out CX, CZ: Single);
var
  FX, FZ, DX, DZ, Len: Single;
begin
  FacingVector(FacingDeg, FX, FZ);
  { halfway between "behind" (-F) and "right" (-FZ, FX) }
  DX := -FX - FZ;
  DZ := -FZ + FX;
  Len := Sqrt(DX * DX + DZ * DZ);
  CX := Clamp((PX + EX) / 2 + DX / Len * ThreeQuarterDistance, -ArenaHalfSize, ArenaHalfSize);
  CZ := Clamp((PZ + EZ) / 2 + DZ / Len * ThreeQuarterDistance, -ArenaHalfSize, ArenaHalfSize);
end;

end.
