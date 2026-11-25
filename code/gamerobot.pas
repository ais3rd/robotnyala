{ The player's robot: plays one move at a time, with timing, combos and stop.
  No Castle Game Engine units here, so it can be unit-tested.
  The view listens to OnMoveStart / OnMoveEnd to animate fists and camera. }
unit GameRobot;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

uses GameCommands;

type
  TMoveStartEvent = procedure (Sender: TObject; Move: TRobotCommand) of object;
  TMoveEndEvent = procedure (Sender: TObject) of object;

  TRobot = class
  private
    FQueue: array of TRobotCommand; // moves waiting after the current one (combos)
    FHasCurrent: Boolean;
    FCurrent: TRobotCommand;
    FTimeLeft: Single;
    FOnMoveStart: TMoveStartEvent;
    FOnMoveEnd: TMoveEndEvent;
    procedure StartMove(Move: TRobotCommand);
    procedure EndMove;
    function PopQueue: TRobotCommand;
  public
    { Give the robot a command. Ignored while Busy, except rcStop. }
    procedure Command(Cmd: TRobotCommand);
    procedure Update(SecondsPassed: Single);
    { A timed move is playing or a combo still has moves to play.
      Holding block is not busy. }
    function Busy: Boolean;
    property HasCurrent: Boolean read FHasCurrent;
    property Current: TRobotCommand read FCurrent;
    { Fired for each single move, including each part of a combo. }
    property OnMoveStart: TMoveStartEvent read FOnMoveStart write FOnMoveStart;
    { Fired when the robot returns to idle. }
    property OnMoveEnd: TMoveEndEvent read FOnMoveEnd write FOnMoveEnd;
  end;

{ Seconds a move takes. Block is held (0 = no time limit). }
function MoveDuration(Move: TRobotCommand): Single;
{ Damage a punch does if it lands; 0 for non-punches. }
function MoveDamage(Move: TRobotCommand): Integer;

implementation

function MoveDuration(Move: TRobotCommand): Single;
begin
  case Move of
    rcJab: Result := 0.25;
    rcCross, rcLeftBody, rcRightBody: Result := 0.3;
    rcLeftHook, rcRightHook, rcLeftUppercut, rcRightUppercut: Result := 0.4;
    rcHaymaker: Result := 0.8;
    rcDuck, rcDodgeLeft, rcDodgeRight: Result := 0.5;
    rcForward, rcBack, rcStepLeft, rcStepRight, rcTurnLeft, rcTurnRight: Result := 0.2;
  else
    Result := 0; // rcBlock (held), combos and stop are not single timed moves
  end;
end;

function MoveDamage(Move: TRobotCommand): Integer;
begin
  case Move of
    rcJab, rcLeftBody, rcRightBody: Result := 5;
    rcCross, rcLeftHook, rcRightHook: Result := 10;
    rcLeftUppercut, rcRightUppercut: Result := 15;
    rcHaymaker: Result := 25;
  else
    Result := 0;
  end;
end;

{ TRobot }

procedure TRobot.StartMove(Move: TRobotCommand);
begin
  FCurrent := Move;
  FHasCurrent := True;
  FTimeLeft := MoveDuration(Move);
  if Assigned(FOnMoveStart) then
    FOnMoveStart(Self, Move);
end;

procedure TRobot.EndMove;
begin
  FHasCurrent := False;
  FTimeLeft := 0;
  if Assigned(FOnMoveEnd) then
    FOnMoveEnd(Self);
end;

function TRobot.PopQueue: TRobotCommand;
var
  I: Integer;
begin
  Result := FQueue[0];
  for I := 1 to High(FQueue) do
    FQueue[I - 1] := FQueue[I];
  SetLength(FQueue, Length(FQueue) - 1);
end;

function TRobot.Busy: Boolean;
begin
  Result := (FHasCurrent and (FCurrent <> rcBlock)) or (Length(FQueue) > 0);
end;

procedure TRobot.Command(Cmd: TRobotCommand);
begin
  if Cmd = rcStop then
  begin
    SetLength(FQueue, 0);
    if FHasCurrent then
      EndMove;
    Exit;
  end;

  if Busy then
    Exit;

  case Cmd of
    rcOneTwo:
      begin
        SetLength(FQueue, 1);
        FQueue[0] := rcCross;
        StartMove(rcJab);
      end;
    rcCombo:
      begin
        SetLength(FQueue, 2);
        FQueue[0] := rcCross;
        FQueue[1] := rcLeftHook;
        StartMove(rcJab);
      end;
  else
    StartMove(Cmd);
  end;
end;

procedure TRobot.Update(SecondsPassed: Single);
begin
  if (not FHasCurrent) or (FCurrent = rcBlock) then
    Exit;
  FTimeLeft := FTimeLeft - SecondsPassed;
  if FTimeLeft <= 0 then
  begin
    if Length(FQueue) > 0 then
      StartMove(PopQueue)
    else
      EndMove;
  end;
end;

end.
