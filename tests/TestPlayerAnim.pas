unit TestPlayerAnim;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

implementation

uses TinyTest, GameCommands, GameRobot, GamePlayerAnim;

procedure TestIdleLoop;
begin
  Check(PlayerFrame(False, rcJab, 0, 0) = 0, 'idle frame 0');
  Check(PlayerFrame(False, rcJab, 0, 0.17) = 1, 'idle frame 1 at 6 fps');
  Check(PlayerFrame(False, rcJab, 0, 0.68) = 0, 'idle loops');
end;

procedure TestPunchPhases;
begin
  Check(PlayerFrame(True, rcJab, 0.05, 0) = 4, 'jab wind-up');
  Check(PlayerFrame(True, rcJab, 0.1, 0) = 5, 'jab strike');
  Check(PlayerFrame(True, rcJab, 0.15, 0) = 6, 'jab impact');
  Check(PlayerFrame(True, rcJab, 0.24, 0) = 7, 'jab recover');
  Check(PlayerFrame(True, rcJab, 0.3, 0) = 7, 'past the end stays on recover');
  Check(PlayerFrame(True, rcRightUppercut, 0.1, 0) = 25, 'right uppercut strike');
  Check(PlayerFrame(True, rcHaymaker, 0.5, 0) = 38, 'haymaker impact');
end;

procedure TestHeldAndSingle;
begin
  Check(PlayerFrame(True, rcBlock, 3.0, 0) = 40, 'block held');
  Check(PlayerFrame(True, rcDuck, 0.1, 0) = 41, 'duck');
  Check(PlayerFrame(True, rcDodgeLeft, 0.1, 0) = 42, 'dodge left');
  Check(PlayerFrame(True, rcDodgeRight, 0.1, 0) = 43, 'dodge right');
end;

procedure TestMovementUsesIdle;
begin
  Check(PlayerFrame(True, rcTurnLeft, 0.1, 0.17) = 1, 'turning shows idle');
  Check(PlayerFrame(True, rcForward, 0.1, 0.17) = 1, 'stepping shows idle');
end;

procedure TestRobotElapsed;
var
  R: TRobot;
begin
  R := TRobot.Create;
  try
    R.Command(rcJab);
    R.Update(0.1);
    CheckNear(R.Elapsed, 0.1, 'elapsed into the jab');
    R.Update(0.2);
    CheckNear(R.Elapsed, 0, 'zero once the move ended');
  finally
    R.Free;
  end;
end;

initialization
  RegisterTest('PlayerAnim.TestIdleLoop', TestIdleLoop);
  RegisterTest('PlayerAnim.TestPunchPhases', TestPunchPhases);
  RegisterTest('PlayerAnim.TestHeldAndSingle', TestHeldAndSingle);
  RegisterTest('PlayerAnim.TestMovementUsesIdle', TestMovementUsesIdle);
  RegisterTest('PlayerAnim.TestRobotElapsed', TestRobotElapsed);
end.
