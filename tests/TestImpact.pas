unit TestImpact;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

implementation

uses TinyTest, GameImpact;

procedure TestFreezeByDamage;
var
  F: TImpactFeel;
begin
  F := TImpactFeel.Create;
  try
    CheckNear(F.Update(0.02), 0.02, 'no hit: time runs normally');
    F.Hit(5, False);                       // jab: 0.03 + 5 * 0.004 = 0.05 s
    CheckNear(F.Update(0.04), 0, 'frozen right after a jab lands');
    CheckNear(F.Update(0.02), 0.01, 'time resumes when the freeze runs out mid-frame');
  finally
    F.Free;
  end;
end;

procedure TestHaymakerFreezesLonger;
var
  F: TImpactFeel;
begin
  F := TImpactFeel.Create;
  try
    F.Hit(25, False);                      // 0.03 + 25 * 0.004 = 0.13 s
    CheckNear(F.Update(0.12), 0, 'still frozen after 0.12 s');
    CheckNear(F.Update(0.02), 0.01, 'then resumes');
  finally
    F.Free;
  end;
end;

procedure TestStreakGrows;
var
  F: TImpactFeel;
begin
  F := TImpactFeel.Create;
  try
    F.Hit(5, False);  F.Update(0.5);
    F.Hit(5, False);  F.Update(0.5);
    Check(F.Streak = 2, 'two hits within the window');
    F.Hit(10, False);                      // (0.03 + 0.04) * 1.5 = 0.105 s
    Check(F.Streak = 3, 'three in a row');
    CheckNear(F.Update(0.1), 0, 'third hit freezes 50% longer');
  finally
    F.Free;
  end;
end;

procedure TestStreakResets;
var
  F: TImpactFeel;
begin
  F := TImpactFeel.Create;
  try
    F.Hit(5, False);  F.Update(1.6);
    F.Hit(5, False);
    Check(F.Streak = 1, 'more than 1.5 s apart starts a new streak');
    F.Update(0.2);
    F.Miss;
    Check(F.Streak = 0, 'a miss ends the streak');
  finally
    F.Free;
  end;
end;

procedure TestKOFreeze;
var
  F: TImpactFeel;
begin
  F := TImpactFeel.Create;
  try
    F.Hit(5, True);
    CheckNear(F.Update(0.3), 0, 'the knockout hit freezes for 0.35 s');
    CheckNear(F.Update(0.1), 0.05, 'then resumes');
  finally
    F.Free;
  end;
end;

procedure TestFlashAndShake;
var
  F: TImpactFeel;
begin
  F := TImpactFeel.Create;
  try
    Check(not F.White and (F.Shake = 0), 'calm before any hit');
    F.Hit(25, False);
    Check(F.White, 'impact frame: white flash on landing');
    CheckNear(F.Shake, 0.1, 'haymaker shake 0.004 * 25 m');
    F.Update(0.07);
    Check(not F.White, 'white flash is over after 0.06 s');
    Check(F.Shake > 0, 'still shaking');
    F.Update(0.5);
    CheckNear(F.Shake, 0, 'shake has faded');
  finally
    F.Free;
  end;
end;

initialization
  RegisterTest('Impact.TestFreezeByDamage', TestFreezeByDamage);
  RegisterTest('Impact.TestHaymakerFreezesLonger', TestHaymakerFreezesLonger);
  RegisterTest('Impact.TestStreakGrows', TestStreakGrows);
  RegisterTest('Impact.TestStreakResets', TestStreakResets);
  RegisterTest('Impact.TestKOFreeze', TestKOFreeze);
  RegisterTest('Impact.TestFlashAndShake', TestFlashAndShake);
end.
