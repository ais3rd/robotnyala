{ Main view: the first-person robot fight.

  The layout (3D room, enemy, fists, labels, command box) is designed in
  data/gameviewmain.castle-user-interface — open it in the Castle Engine editor.
  The game rules live in GameCommands, GameRobot and GameCombat (unit-tested);
  this unit only connects them to what you see. }
unit GameViewMain;

interface

uses Classes,
  CastleVectors, CastleComponentSerialize,
  CastleUIControls, CastleControls, CastleKeysMouse,
  CastleViewport, CastleTransform, CastleScene,
  GameCommands, GameRobot, GameCombat;

type
  TViewMain = class(TCastleView)
  published
    { Components designed using CGE editor.
      These fields will be automatically initialized at Start. }
    LabelFps: TCastleLabel;
    LabelLast: TCastleLabel;
    LabelKO: TCastleLabel;
    EditCommand: TCastleEdit;
    FistLeft: TCastleImageControl;
    FistRight: TCastleImageControl;
    HPBarBack: TCastleRectangleControl;
    HPBar: TCastleRectangleControl;
    MainViewport: TCastleViewport;
    PlayerCamera: TCastleCamera;
    Enemy: TCastleImageTransform;
  private
    Robot: TRobot;
    EnemyState: TEnemyState;
    { Player on the floor plane; see GameCombat for the meaning of FacingDeg. }
    PlayerX, PlayerZ, FacingDeg: Single;
    { Temporary camera offsets for duck and dodge. }
    EyeDrop, EyeSide: Single;
    FlashTimeLeft: Single;
    FistLeftBase, FistRightBase: TVector2;
    procedure SubmitCommand(const Text: string);
    procedure RobotMoveStart(Sender: TObject; Move: TRobotCommand);
    procedure RobotMoveEnd(Sender: TObject);
    procedure PoseFist(const Fist: TCastleImageControl; const Side, Pose: string;
      const Base: TVector2; const ShiftTowardCenter, ShiftUp: Single);
    procedure PoseLeft(const Pose: string);
    procedure PoseRight(const Pose: string);
    procedure PunchAt(Move: TRobotCommand);
    procedure UpdateCamera;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
  end;

var
  ViewMain: TViewMain;

implementation

uses SysUtils, CastleColors;

const
  EyeHeight = 1.7;
  DuckDrop = 0.5;
  DodgeSide = 0.4;
  HitFlashTime = 0.15;

{ TViewMain ----------------------------------------------------------------- }

constructor TViewMain.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewmain.castle-user-interface';
end;

procedure TViewMain.Start;
begin
  inherited;
  Robot := TRobot.Create;
  Robot.OnMoveStart := {$ifdef FPC}@{$endif}RobotMoveStart;
  Robot.OnMoveEnd := {$ifdef FPC}@{$endif}RobotMoveEnd;
  EnemyState := TEnemyState.Create;

  PlayerX := 0;
  PlayerZ := 0;
  FacingDeg := 0;
  EyeDrop := 0;
  EyeSide := 0;
  FlashTimeLeft := 0;

  { remember where the fists sit in the design, punches move them from there }
  FistLeftBase := FistLeft.Translation;
  FistRightBase := FistRight.Translation;
  PoseLeft('idle');
  PoseRight('idle');

  { all keys go to the command box (Wispr Flow types or pastes there) }
  Container.ForceCaptureInput := EditCommand;
  UpdateCamera;
end;

procedure TViewMain.Stop;
begin
  if Container.ForceCaptureInput = EditCommand then
    Container.ForceCaptureInput := nil;
  FreeAndNil(Robot);
  FreeAndNil(EnemyState);
  inherited;
end;

procedure TViewMain.PoseFist(const Fist: TCastleImageControl; const Side, Pose: string;
  const Base: TVector2; const ShiftTowardCenter, ShiftUp: Single);
var
  Dir: Single;
begin
  Fist.Url := 'castle-data:/images/fist_' + Side + '_' + Pose + '.png';
  if Side = 'left' then Dir := 1 else Dir := -1;
  Fist.Translation := Vector2(Base.X + Dir * ShiftTowardCenter, Base.Y + ShiftUp);
end;

procedure TViewMain.PoseLeft(const Pose: string);
begin
  if Pose = 'punch' then PoseFist(FistLeft, 'left', Pose, FistLeftBase, 180, 60) else
  if Pose = 'body'  then PoseFist(FistLeft, 'left', 'punch', FistLeftBase, 160, -20) else
  if Pose = 'hook'  then PoseFist(FistLeft, 'left', Pose, FistLeftBase, 260, 40) else
  if Pose = 'up'    then PoseFist(FistLeft, 'left', Pose, FistLeftBase, 150, 90) else
  if Pose = 'block' then PoseFist(FistLeft, 'left', Pose, FistLeftBase, 170, 40) else
                         PoseFist(FistLeft, 'left', 'idle', FistLeftBase, 0, 0);
end;

procedure TViewMain.PoseRight(const Pose: string);
begin
  if Pose = 'punch' then PoseFist(FistRight, 'right', Pose, FistRightBase, 180, 60) else
  if Pose = 'body'  then PoseFist(FistRight, 'right', 'punch', FistRightBase, 160, -20) else
  if Pose = 'hook'  then PoseFist(FistRight, 'right', Pose, FistRightBase, 260, 40) else
  if Pose = 'up'    then PoseFist(FistRight, 'right', Pose, FistRightBase, 150, 90) else
  if Pose = 'block' then PoseFist(FistRight, 'right', Pose, FistRightBase, 170, 40) else
                         PoseFist(FistRight, 'right', 'idle', FistRightBase, 0, 0);
end;

procedure TViewMain.PunchAt(Move: TRobotCommand);
begin
  if EnemyState.IsKO then
    LabelLast.Caption := CommandName(Move)
  else
  if PunchHits(PlayerX, PlayerZ, FacingDeg, Enemy.Translation.X, Enemy.Translation.Z) then
  begin
    EnemyState.Hit(MoveDamage(Move));
    FlashTimeLeft := HitFlashTime;
    LabelLast.Caption := CommandName(Move) + ' - HIT!';
  end else
    LabelLast.Caption := CommandName(Move) + ' - miss';
end;

procedure TViewMain.RobotMoveStart(Sender: TObject; Move: TRobotCommand);
var
  FX, FZ: Single;
begin
  { fists }
  case Move of
    rcJab:           begin PoseLeft('punch'); PoseRight('idle'); end;
    rcLeftBody:      begin PoseLeft('body');  PoseRight('idle'); end;
    rcLeftHook:      begin PoseLeft('hook');  PoseRight('idle'); end;
    rcLeftUppercut:  begin PoseLeft('up');    PoseRight('idle'); end;
    rcCross:         begin PoseLeft('idle');  PoseRight('punch'); end;
    rcRightBody:     begin PoseLeft('idle');  PoseRight('body'); end;
    rcRightHook,
    rcHaymaker:      begin PoseLeft('idle');  PoseRight('hook'); end;
    rcRightUppercut: begin PoseLeft('idle');  PoseRight('up'); end;
    rcBlock:         begin PoseLeft('block'); PoseRight('block'); end;
  else
    PoseLeft('idle');
    PoseRight('idle');
  end;

  if MoveDamage(Move) > 0 then
    PunchAt(Move);

  { body and camera. Right of the facing direction (FX, FZ) is (-FZ, FX). }
  FacingVector(FacingDeg, FX, FZ);
  case Move of
    rcForward:   ClampedStep(PlayerX, PlayerZ,  FX * StepSize,  FZ * StepSize, Enemy.Translation.X, Enemy.Translation.Z);
    rcBack:      ClampedStep(PlayerX, PlayerZ, -FX * StepSize, -FZ * StepSize, Enemy.Translation.X, Enemy.Translation.Z);
    rcStepLeft:  ClampedStep(PlayerX, PlayerZ,  FZ * StepSize, -FX * StepSize, Enemy.Translation.X, Enemy.Translation.Z);
    rcStepRight: ClampedStep(PlayerX, PlayerZ, -FZ * StepSize,  FX * StepSize, Enemy.Translation.X, Enemy.Translation.Z);
    rcTurnLeft:  FacingDeg := FacingDeg + TurnStepDeg;
    rcTurnRight: FacingDeg := FacingDeg - TurnStepDeg;
    rcDuck:      EyeDrop := DuckDrop;
    rcDodgeLeft: EyeSide := -DodgeSide;
    rcDodgeRight: EyeSide := DodgeSide;
  else ;
  end;
end;

procedure TViewMain.RobotMoveEnd(Sender: TObject);
begin
  EyeDrop := 0;
  EyeSide := 0;
  PoseLeft('idle');
  PoseRight('idle');
end;

procedure TViewMain.UpdateCamera;
var
  FX, FZ: Single;
begin
  FacingVector(FacingDeg, FX, FZ);
  PlayerCamera.SetView(
    Vector3(PlayerX - FZ * EyeSide, EyeHeight - EyeDrop, PlayerZ + FX * EyeSide),
    Vector3(FX, 0, FZ),
    Vector3(0, 1, 0));
end;

procedure TViewMain.SubmitCommand(const Text: string);
var
  Cmd: TRobotCommand;
begin
  if CleanCommandText(Text) = '' then
    Exit;
  if not ParseCommand(Text, Cmd) then
  begin
    LabelLast.Caption := 'Didn''t understand: ' + Trim(Text);
    Exit;
  end;
  if Robot.Busy and (Cmd <> rcStop) then
  begin
    LabelLast.Caption := CommandName(Cmd) + ' (ignored: still moving)';
    Exit;
  end;
  LabelLast.Caption := CommandName(Cmd);
  Robot.Command(Cmd); // punches overwrite the caption with HIT / miss
end;

procedure TViewMain.Update(const SecondsPassed: Single; var HandleInput: Boolean);
begin
  inherited;
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;

  Robot.Update(SecondsPassed);
  EnemyState.Update(SecondsPassed);

  if FlashTimeLeft > 0 then
    FlashTimeLeft := FlashTimeLeft - SecondsPassed;
  if FlashTimeLeft > 0 then
    Enemy.Color := Vector4(1, 0.35, 0.35, 1)
  else
  if EnemyState.IsKO then
    Enemy.Color := Vector4(0.45, 0.45, 0.45, 1)
  else
    Enemy.Color := White;

  HPBar.Width := HPBarBack.Width * EnemyState.HP / MaxHP;
  LabelKO.Exists := EnemyState.IsKO;

  UpdateCamera;
end;

function TViewMain.Press(const Event: TInputPressRelease): Boolean;
begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  { The command box doesn't handle Enter, so it reaches us: submit. }
  if Event.IsKey(keyEnter) then
  begin
    SubmitCommand(EditCommand.Text);
    EditCommand.Text := '';
    Exit(true);
  end;
end;

end.
