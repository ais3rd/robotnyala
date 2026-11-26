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
  GameCommands, GameRobot, GameCombat, GameEnemyAnim;

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
    EnemyAnim: TEnemyAnimator;
    { Player on the floor plane; see GameCombat for the meaning of FacingDeg. }
    PlayerX, PlayerZ, FacingDeg: Single;
    { Temporary camera offsets for duck and dodge. }
    EyeDrop, EyeSide: Single;
    FlashTimeLeft: Single;
    procedure SubmitCommand(const Text: string);
    procedure RobotMoveStart(Sender: TObject; Move: TRobotCommand);
    procedure RobotMoveEnd(Sender: TObject);
    procedure PoseFist(const Fist: TCastleImageControl; const Side, Pose: string);
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
  EnemyAnim := TEnemyAnimator.Create;
  { the enemy image is a sprite sheet: show one frame-wide slice of it.
    Size and Pivot refer to the whole sheet, so the pivot moves to the middle
    of the first frame to keep the enemy centred on its position. }
  Enemy.RepeatImage := Vector2(1 / EnemyFrameCount, 1);
  Enemy.Pivot := Vector2(0.5 / EnemyFrameCount, 0.5);

  PlayerX := 0;
  PlayerZ := 0;
  FacingDeg := 0;
  EyeDrop := 0;
  EyeSide := 0;
  FlashTimeLeft := 0;

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
  FreeAndNil(EnemyAnim);
  inherited;
end;

{ Each pose is a full-screen image of one arm, rendered from the player's eyes
  by art/player_glitchpop.html: fist_<side>_<pose>.png
  Poses: idle, punch, body, hook, up, block. }
procedure TViewMain.PoseFist(const Fist: TCastleImageControl; const Side, Pose: string);
begin
  Fist.Url := 'castle-data:/images/fist_' + Side + '_' + Pose + '.png';
end;

procedure TViewMain.PoseLeft(const Pose: string);
begin
  PoseFist(FistLeft, 'left', Pose);
end;

procedure TViewMain.PoseRight(const Pose: string);
begin
  PoseFist(FistRight, 'right', Pose);
end;

procedure TViewMain.PunchAt(Move: TRobotCommand);
begin
  if EnemyState.IsKO then
    LabelLast.Caption := CommandName(Move)
  else
  if PunchHits(PlayerX, PlayerZ, FacingDeg, Enemy.Translation.X, Enemy.Translation.Z) then
  begin
    EnemyState.Hit(MoveDamage(Move));
    EnemyAnim.Hit;
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
  EnemyAnim.Update(SecondsPassed, EnemyState.IsKO);
  Enemy.Shift := Vector2(EnemyAnim.Frame / EnemyFrameCount, 0);

  if FlashTimeLeft > 0 then
    FlashTimeLeft := FlashTimeLeft - SecondsPassed;
  if FlashTimeLeft > 0 then
    Enemy.Color := Vector4(1, 0.35, 0.35, 1)
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
