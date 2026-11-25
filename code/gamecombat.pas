{ Combat rules on the floor plane: does a punch land, enemy HP and KO,
  and moving without walking through the enemy or the walls.
  No Castle Game Engine units here, so it can be unit-tested.

  Positions are (X, Z) on the floor. FacingDeg: 0 = looking toward -Z,
  positive = turned left (counter-clockwise seen from above). }
unit GameCombat;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

const
  Reach = 1.5;            // metres
  HitAngleDeg = 30;       // enemy must be within this angle of where we face
  MaxHP = 100;
  KOResetTime = 3.0;      // seconds the KO lasts before the fight resets
  StepSize = 0.5;         // metres per forward/back/side step
  TurnStepDeg = 15;
  MinEnemyDistance = 0.8; // can't walk closer than this to the enemy
  RoomHalfSize = 4.5;     // walls are at +-5 m; keep 0.5 m away from them

type
  TEnemyState = class
  private
    FHP: Integer;
    FIsKO: Boolean;
    FKOTimeLeft: Single;
  public
    constructor Create;
    { Lose HP. No effect while KO. Reaching 0 HP starts the KO. }
    procedure Hit(Damage: Integer);
    { Counts down the KO, then resets to full HP. }
    procedure Update(SecondsPassed: Single);
    property HP: Integer read FHP;
    property IsKO: Boolean read FIsKO;
  end;

{ Direction you look along when facing FacingDeg (unit vector on the floor). }
procedure FacingVector(FacingDeg: Single; out FX, FZ: Single);

{ True if the enemy at (EX, EZ) is within Reach and within HitAngleDeg
  of the direction the player at (PX, PZ) faces. }
function PunchHits(PX, PZ, FacingDeg, EX, EZ: Single): Boolean;

{ Move the player by (DX, DZ) but stop MinEnemyDistance from the enemy
  and stay inside the room. }
procedure ClampedStep(var PX, PZ: Single; DX, DZ, EX, EZ: Single);

implementation

uses Math;

{ Own clamp for Single: Math.EnsureRange/Max with mixed literal types can be
  an ambiguous overload in Delphi. }
function ClampF(Value, Lo, Hi: Single): Single;
begin
  if Value < Lo then Result := Lo else
  if Value > Hi then Result := Hi else
    Result := Value;
end;

procedure FacingVector(FacingDeg: Single; out FX, FZ: Single);
var
  A: Single;
begin
  A := DegToRad(FacingDeg);
  FX := -Sin(A);
  FZ := -Cos(A);
end;

function PunchHits(PX, PZ, FacingDeg, EX, EZ: Single): Boolean;
var
  DX, DZ, Dist, FX, FZ: Single;
begin
  DX := EX - PX;
  DZ := EZ - PZ;
  Dist := Sqrt(DX * DX + DZ * DZ);
  if Dist > Reach then
    Exit(False);
  if Dist < 1e-4 then
    Exit(True);
  FacingVector(FacingDeg, FX, FZ);
  Result := (FX * DX + FZ * DZ) / Dist >= Cos(DegToRad(HitAngleDeg)) - 1e-6;
end;

procedure ClampedStep(var PX, PZ: Single; DX, DZ, EX, EZ: Single);
var
  NX, NZ, RX, RZ, A, B, C, Disc, T, MinSq: Single;
begin
  NX := PX + DX;
  NZ := PZ + DZ;
  MinSq := MinEnemyDistance * MinEnemyDistance;

  if Sqr(NX - EX) + Sqr(NZ - EZ) < MinSq then
  begin
    RX := PX - EX;
    RZ := PZ - EZ;
    C := RX * RX + RZ * RZ - MinSq;
    if C < 1e-6 then
    begin
      { already at (or inside) the minimum distance: don't move closer }
      NX := PX;
      NZ := PZ;
    end else
    begin
      { walk along the step only until we're exactly MinEnemyDistance away }
      A := DX * DX + DZ * DZ;
      B := 2 * (DX * RX + DZ * RZ);
      Disc := B * B - 4 * A * C;
      if Disc < 0 then Disc := 0;
      T := ClampF((-B - Sqrt(Disc)) / (2 * A), 0, 1);
      NX := PX + T * DX;
      NZ := PZ + T * DZ;
    end;
  end;

  PX := ClampF(NX, -RoomHalfSize, RoomHalfSize);
  PZ := ClampF(NZ, -RoomHalfSize, RoomHalfSize);
end;

{ TEnemyState }

constructor TEnemyState.Create;
begin
  inherited Create;
  FHP := MaxHP;
end;

procedure TEnemyState.Hit(Damage: Integer);
begin
  if FIsKO or (Damage <= 0) then
    Exit;
  FHP := FHP - Damage;
  if FHP < 0 then FHP := 0;
  if FHP = 0 then
  begin
    FIsKO := True;
    FKOTimeLeft := KOResetTime;
  end;
end;

procedure TEnemyState.Update(SecondsPassed: Single);
begin
  if not FIsKO then
    Exit;
  FKOTimeLeft := FKOTimeLeft - SecondsPassed;
  if FKOTimeLeft <= 0 then
  begin
    FIsKO := False;
    FHP := MaxHP;
  end;
end;

end.
