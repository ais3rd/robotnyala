unit TestEnemyAnim;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

implementation

uses TinyTest, GameEnemyAnim;

procedure TestIdleCycles;
var
  A: TEnemyAnimator;
begin
  A := TEnemyAnimator.Create;
  try
    Check(A.Frame = 0, 'starts on idle frame 0');
    A.Update(0.17, False);
    Check(A.Frame = 1, 'idle frame 1 after 1/6 s');
    A.Update(0.17, False);
    A.Update(0.17, False);
    Check(A.Frame = 3, 'idle frame 3');
    A.Update(0.17, False);
    Check(A.Frame = 0, 'idle loops back to 0');
  finally
    A.Free;
  end;
end;

procedure TestHitFrames;
var
  A: TEnemyAnimator;
begin
  A := TEnemyAnimator.Create;
  try
    A.Hit;
    Check(A.Frame = 4, 'hit starts on frame 4');
    A.Update(0.13, False);
    Check(A.Frame = 5, 'then frame 5');
    A.Update(0.2, False);
    Check(A.Frame in [0..3], 'back to idle after the hit');
  finally
    A.Free;
  end;
end;

procedure TestKOSequence;
var
  A: TEnemyAnimator;
begin
  A := TEnemyAnimator.Create;
  try
    A.Hit;                      // the knockout punch also counts as a hit
    A.Update(0.01, True);
    Check(A.Frame = 6, 'KO starts on frame 6 (overrides the hit)');
    A.Update(0.19, True);
    Check(A.Frame = 7, 'then frame 7');
    A.Update(0.19, True);
    Check(A.Frame = 8, 'then frame 8');
    A.Update(5.0, True);
    Check(A.Frame = 8, 'stays down on frame 8');
    A.Update(0.01, False);
    Check(A.Frame in [0..3], 'back to idle when the fight resets');
  finally
    A.Free;
  end;
end;

procedure TestHitIgnoredWhileKO;
var
  A: TEnemyAnimator;
begin
  A := TEnemyAnimator.Create;
  try
    A.Update(1.0, True);
    A.Hit;
    Check(A.Frame = 8, 'hits do not interrupt the KO');
    A.Update(0.01, False);
    Check(A.Frame in [0..3], 'and leave no hit pending after the reset');
  finally
    A.Free;
  end;
end;

initialization
  RegisterTest('EnemyAnim.TestIdleCycles', TestIdleCycles);
  RegisterTest('EnemyAnim.TestHitFrames', TestHitFrames);
  RegisterTest('EnemyAnim.TestKOSequence', TestKOSequence);
  RegisterTest('EnemyAnim.TestHitIgnoredWhileKO', TestHitIgnoredWhileKO);
end.
