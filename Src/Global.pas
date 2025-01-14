unit Global;

interface

uses
  Windows, SysUtils, StrUtils, PXT.Sprites, WZArchive, Generics.Collections,
  WZIMGFile, WZDirectory, Classes, Math, BassHandler, AsphyreKeyboard, Tools,
  System.Types, ACtrlEngine, PXT.Types, PXT.Graphics, PXT.Canvas;

type
  TGameMode = (gmPlay, gmView);

  TTimers = class
  private
    class var
      TimerList: TDictionary<string, Integer>;
  public
    class procedure AddTimer(Name: string);
    class procedure DoTick(Interval: Integer; TimerName: string; Proc: TProc);
    class procedure Create; overload;
  end;

var
  WzList: TObjectList<TWZArchive>;
  //list 64 bit Character wz files
  WzList2:TDictionary<string,string>;
  ItemWzList:TDictionary<string,string>;
  ItemWZListA:TObjectList<TWZArchive>;
  Is64Bit: Boolean;
  WzPath: string;
  FDevice: TDevice;
  GameDevice2: TDevice;
  GameDevice3: TDevice;
  DisplaySize: TPoint2i;
  GameFont: TTextRenderer;
  GameCanvas: TGameCanvas;
  AvatarPanelTexture: TTexture;
  IsKMS: Boolean;
  UIEngine: TControlEngine = nil;
  SpriteEngine: TSpriteEngine;
  BackEngine: array[0..1] of TSpriteEngine;
  Keyboard: TAsphyreKeyboard;
  GameMode: TGameMode;
  Sounds: TObjectList<TBassHandler>;
  Damage: Integer;
  NewPosition, CurrentPosition, SpriteEngineVelX: Double;
  NewPositionY, CurrentPositionY, SpriteEngineVelY: Double;
  CharData, Data: TDictionary<string, Variant>;
  EquipData, WzData: TObjectDictionary<string, TWZIMGEntry>;
  Images: TDictionary<TWZIMGEntry, TTexture>;
  EquipImages: TDictionary<TWZIMGEntry, TTexture>;

function LeftPad(Value: Integer; Length: integer = 8): string;

function IsNumber(AStr: string): Boolean;

procedure PlaySounds(Img, Path: string);

function TrimS(Stemp: string): string;

function IDToInt(ID: string): string;

function Add7(Name: string): string;

function Add9(Name: string): string;

implementation

uses
  WzUtils;

var
  CosTable256: array[0..255] of Double;

function LeftPad(Value: Integer; Length: integer = 8): string;
begin
  Result := RightStr(StringOfChar('0', Length) + Value.ToString, Length);
end;

function IsNumber(AStr: string): Boolean;
var
  Value: Double;
  Code: Integer;
begin
  Val(AStr, Value, Code);
  Result := Code = 0;
end;

class procedure TTimers.AddTimer(Name: string);
begin
  TimerList.Add(Name, 0);
end;

class procedure TTimers.Create;
begin
  TimerList := TDictionary<string, Integer>.Create;
end;

class procedure TTimers.DoTick(Interval: Integer; TimerName: string; Proc: TProc);
begin
  if GetTickcount - TimerList[TimerName] > Interval then
  begin
    Proc;
    TimerList[TimerName] := GetTickcount;
  end;
end;

procedure PlaySounds(Img, Path: string);
var
  NewSound: TBassHandler;
  Entry: TWZIMGEntry;
begin
  Entry := GetImgFile('Sound/' + Img + '.img').Root.Get(Path);
  if Entry = nil then
    Exit;

  if Entry.DataType = mdtUOL then
  begin
    Entry := TWZIMGEntry(Entry.Parent).Get(Entry.Data);
    if Entry.DataType = mdtUOL then
      Entry := TWZIMGEntry(Entry.Parent).Get(Entry.Data);
  end;
  var WZ: TWzarchive;
  for var I in WzList do
  begin
    if LeftStr(i.PathName,5)='Sound' then
    begin
     if I.GetImgFile(Img + '.img') <> nil then
     begin
       WZ := I;
       break;
     end;
    end;
  end;
  NewSound := TBassHandler.Create(WZ.Reader.Stream, Entry.Sound.Offset, Entry.Sound.DataLength);
  NewSound.Play;
  Sounds.Add(NewSound);
end;

function IDToInt(ID: string): string;
var
  S: Integer;
begin
  S := ID.ToInteger;
  Result := S.ToString;
end;

function TrimS(Stemp: string): string;
const
  Remove =[' ', '.', '/', #13, #10];
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Stemp) do
  begin
    if not (Stemp[I] in Remove) then
      Result := Result + Stemp[I];
  end;
end;

function Add7(Name: string): string;
begin
  case Length(Name) of
    4:
      Result := '000' + Name;
    5:
      Result := '00' + Name;
    6:
      Result := '0' + Name;
    7:
      Result := Name;
  end;
end;

function Add9(Name: string): string;
begin
  case Length(Name) of
    1:
      Result := '00000000' + Name;
    5:
      Result := '0000' + Name;
    7:
      Result := '00' + Name;
    9:
      Result := Name;
  end;
end;

initialization
  TTimers.Create;
  Sounds := TObjectList<TBassHandler>.Create;
  WzData := TObjectDictionary<string, TWZIMGEntry>.Create;
  EquipData := TObjectDictionary<string, TWZIMGEntry>.Create;
  CharData := TDictionary<string, Variant>.Create;
  Data := TDictionary<string, Variant>.Create;


finalization
  TTimers.TimerList.Free;

end.

