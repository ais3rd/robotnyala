{ Hit feel: hit-stop (the fight freezes for a moment when a punch lands), an impact
  frame (white flash), screen shake, and a streak that makes consecutive hits heavier.
  No Castle Game Engine units here, so it can be unit-tested. }
unit GameImpact;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

const
  FreezeBase = 0.03;          // seconds of hit-stop for any landed punch...
  FreezePerDamage = 0.004;    // ...plus this per damage point (jab 0.05 s, haymaker 0.13 s)
  KOFreeze = 0.35;            // the knockout hit holds longer
  WhiteTime = 0.06;           // impact frame
  ShakePerDamage = 0.004;     // metres of camera shake per damage point
  ShakeTime = 0.25;           // shake fades out over this
  StreakWindow = 1.5;         // hits closer than this build a streak
  StreakStep = 0.25;          // each extra streak hit adds 25% freeze and shake...
  StreakMaxScale = 2.0;       // ...up to double

type
  TImpactFeel = class
  private
    FFreezeLeft, FWhiteLeft, FShakeLeft, FShakeAmp, FSinceHit: Single;
    FStreak: Integer;
  public
    constructor Create;
    { A punch landed. KO = it was the knockout punch. }
    procedure Hit(Damage: Integer; KO: Boolean);
    { A punch missed: the streak ends. }
    procedure Miss;
    { Advance real time; returns how much game time passes (0 while frozen). }
    function Update(SecondsPassed: Single): Single;
    { Current camera shake amplitude, metres. }
    function Shake: Single;
    { True during the impact frame. }
    function White: Boolean;
    property Streak: Integer read FStreak;
  end;

implementation

constructor TImpactFeel.Create;
begin
  inherited Create;
  FSinceHit := 1e9;
end;

procedure TImpactFeel.Hit(Damage: Integer; KO: Boolean);
var
  Scale: Single;
begin
  if FSinceHit <= StreakWindow then
    Inc(FStreak)
  else
    FStreak := 1;
  FSinceHit := 0;

  Scale := 1 + StreakStep * (FStreak - 1);
  if Scale > StreakMaxScale then Scale := StreakMaxScale;

  FFreezeLeft := (FreezeBase + FreezePerDamage * Damage) * Scale;
  if KO and (FFreezeLeft < KOFreeze) then
    FFreezeLeft := KOFreeze;
  FWhiteLeft := WhiteTime;
  FShakeAmp := ShakePerDamage * Damage * Scale;
  FShakeLeft := ShakeTime;
end;

procedure TImpactFeel.Miss;
begin
  FStreak := 0;
  FSinceHit := 1e9;
end;

function TImpactFeel.Update(SecondsPassed: Single): Single;
begin
  FSinceHit := FSinceHit + SecondsPassed;
  FWhiteLeft := FWhiteLeft - SecondsPassed;
  FShakeLeft := FShakeLeft - SecondsPassed;
  if FFreezeLeft >= SecondsPassed then
  begin
    FFreezeLeft := FFreezeLeft - SecondsPassed;
    Result := 0;
  end else
  begin
    Result := SecondsPassed - FFreezeLeft;
    FFreezeLeft := 0;
  end;
end;

function TImpactFeel.Shake: Single;
begin
  if FShakeLeft <= 0 then
    Result := 0
  else
    Result := FShakeAmp * FShakeLeft / ShakeTime;
end;

function TImpactFeel.White: Boolean;
begin
  Result := FWhiteLeft > 0;
end;

end.
