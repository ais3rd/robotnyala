unit TestRobot;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

implementation

uses TinyTest, GameCommands, GameRobot;

type
  { Records what the robot reports through its events. }
  TRecorder = class
    Started: array of TRobotCommand;
    EndCount: Integer;
    procedure MoveStart(Sender: TObject; Move: TRobotCommand);
    procedure MoveEnd(Sender: TObject);
  end;

procedure TRecorder.MoveStart(Sender: TObject; Move: TRobotCommand);
begin
  SetLength(Started, Length(Started) + 1);
  Started[High(Started)] := Move;
end;

procedure TRecorder.MoveEnd(Sender: TObject);
begin
  Inc(EndCount);
end;

var
  Robot: TRobot;
  Rec: TRecorder;

procedure Setup;
begin
  Robot.Free;
  Rec.Free;
  Robot := TRobot.Create;
  Rec := TRecorder.Create;
  Robot.OnMoveStart := Rec.MoveStart;
  Robot.OnMoveEnd := Rec.MoveEnd;
end;

procedure TestSingleMove;
begin
  Setup;
  Robot.Command(rcJab);
  Check((Length(Rec.Started) = 1) and (Rec.Started[0] = rcJab), 'jab started');
  Check(Robot.Busy, 'busy during jab');
  Robot.Update(0.26);
  Check(not Robot.Busy, 'not busy after 0.26 s');
  Check(Rec.EndCount = 1, 'OnMoveEnd fired once');
end;

procedure TestIgnoredWhileBusy;
begin
  Setup;
  Robot.Command(rcJab);
  Robot.Command(rcHaymaker);
  Check(Length(Rec.Started) = 1, 'only one move started');
  Check(Rec.Started[0] = rcJab, 'it was the jab');
end;

procedure TestComboSequence;
begin
  Setup;
  Robot.Command(rcCombo);
  Robot.Update(0.26);
  Robot.Update(0.31);
  Check(Length(Rec.Started) = 3, 'three moves started');
  Check((Rec.Started[0] = rcJab) and (Rec.Started[1] = rcCross) and
    (Rec.Started[2] = rcLeftHook), 'jab, cross, left hook in order');
  Robot.Update(0.41);
  Check(not Robot.Busy, 'combo finished');
  Check(Rec.EndCount = 1, 'OnMoveEnd fired once, at the end of the combo');
end;

procedure TestOneTwo;
begin
  Setup;
  Robot.Command(rcOneTwo);
  Robot.Update(0.26);
  Check((Length(Rec.Started) = 2) and (Rec.Started[0] = rcJab) and
    (Rec.Started[1] = rcCross), 'one two = jab, cross');
end;

procedure TestStopCancelsCombo;
begin
  Setup;
  Robot.Command(rcCombo);
  Robot.Command(rcStop);
  Check(not Robot.Busy, 'not busy after stop');
  Robot.Update(1.0);
  Check(Length(Rec.Started) = 1, 'no further moves after stop');
  Check(Rec.EndCount = 1, 'stop ends the move');
end;

procedure TestBlockHeld;
begin
  Setup;
  Robot.Command(rcBlock);
  Robot.Update(5.0);
  Check(Robot.HasCurrent and (Robot.Current = rcBlock), 'still blocking after 5 s');
  Check(not Robot.Busy, 'blocking is not busy');
  Robot.Command(rcJab);
  Check(Robot.Current = rcJab, 'jab replaces block');
end;

procedure TestValues;
begin
  CheckNear(MoveDuration(rcJab), 0.25, 'jab duration');
  CheckNear(MoveDuration(rcHaymaker), 0.8, 'haymaker duration');
  CheckNear(MoveDuration(rcLeftHook), 0.4, 'hook duration');
  CheckNear(MoveDuration(rcDuck), 0.5, 'duck duration');
  Check(MoveDamage(rcJab) = 5, 'jab damage');
  Check(MoveDamage(rcCross) = 10, 'cross damage');
  Check(MoveDamage(rcRightUppercut) = 15, 'uppercut damage');
  Check(MoveDamage(rcHaymaker) = 25, 'haymaker damage');
  Check(MoveDamage(rcForward) = 0, 'movement does no damage');
end;

initialization
  RegisterTest('Robot.TestSingleMove', TestSingleMove);
  RegisterTest('Robot.TestIgnoredWhileBusy', TestIgnoredWhileBusy);
  RegisterTest('Robot.TestComboSequence', TestComboSequence);
  RegisterTest('Robot.TestOneTwo', TestOneTwo);
  RegisterTest('Robot.TestStopCancelsCombo', TestStopCancelsCombo);
  RegisterTest('Robot.TestBlockHeld', TestBlockHeld);
  RegisterTest('Robot.TestValues', TestValues);
finalization
  Robot.Free;
  Rec.Free;
end.
