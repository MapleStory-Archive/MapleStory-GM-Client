unit MapleMap;

interface

uses
  Types, Generics.Collections, Generics.Defaults, WZDirectory, WZIMGFile, Global,
  SysUtils, StrUtils, Bass, BassHandler, WZArchive;

type
  TFadeScreen = record
    AlphaCounter, AValue: Integer;
    DoFade: Boolean;
  end;

  TMapNameRec = record
    ID: string;
    MapName: string;
    StreetName: string;
  end;

  TMap = record
    class var
      MapNameList: TDictionary<string, TMapNameRec>;
      Info: TDictionary<string, Variant>;
      SaveMap: Boolean;
      SaveMapID: string;
      FadeScreen: TFadeScreen;
      ReLoad: Boolean;
      FirstLoad: Boolean;
      BgmPath: string;
      Left, Top, Right, Bottom, SaveMapBottom: Integer;
      OffsetY: Integer;
      ID: string;
      ImgFile: TWZIMGEntry;
      BgmList: TList<string>;
      ShowTile: Boolean;
      ShowObj: Boolean;
      ShowBack: Boolean;
      ShowFront: Boolean;
      ShowNPC: Boolean;
      ShowMob: Boolean;
      ShowPortal: Boolean;
      ShowMobName: Boolean;
      ShowID: Boolean;
      ShowPortalInfo: Boolean;
      ShowMobInfo: Boolean;
      ShowChar: Boolean;
      ShowFPS: Boolean;
      ShowFoothold: Boolean;
      ShowMusic: Boolean;
      ShowUI: Boolean;
      ShowMiniMap: Boolean;
      ShowNpcName: Boolean;
      ShowNpcChat: Boolean;
      ShowScrollingBar: Boolean;
      ActiveBass: TBassHandler;
      WzMobCount: Integer;
      Has002Wz: Boolean;
      HasMiniMap: Boolean;
      MiniMapEntry: TWZIMGEntry;
      MiniMapWidth, MiniMapHeight: Integer;
      ScrollingMessage: string;
    class procedure PlayMusic; static;
    class procedure LoadMap(ID: string); static;
  end;

implementation

uses
  MainUnit, Mob2, MapBack, MapPortal, Npc, MapTile, MapObj, MapleCharacter,
  Footholds, LadderRopes, MobInfo, NameTag, Boss, Skill, MapleCharacterEx,
  Android, minimap, WZUtils, UI.StatusBar3.MainBar, UI.StatusBar3.Chat,UI.StatusBar, UI.Utils,
  Graphics;

class procedure TMap.LoadMap(ID: string);
var
  Iter: TWZIMGEntry;
  I, Bottom2: Integer;
begin
  for I := 0 to SpriteEngine.Count - 1 do
    if SpriteEngine.Items[I].Tag <> 1 then
      SpriteEngine.Items[I].Dead;

  for I := 0 to PlayerExList.Count - 1 do
  begin
    if PlayerExList[I] <> nil then
    begin
      PlayerExList[I].RemoveSprites;
      PlayerExList[I].Dead;
      PlayerExList[I] := nil;
    end;
  end;
  PlayerExList.Clear;

  TMob.Moblist.Clear;
  TMob.SummonedList.Clear;
  TNpc.SummonedList.Clear;
  // LoadMob.Clear;
  TMap.Info.Clear;
  WzData.Clear;
  //GameTargets.RemoveAll;
  // SpriteEngine.Clear;
  BackEngine[0].Clear;
  BackEngine[1].Clear;
  for var n in Images.Keys do
    images[n].Free;

  Images.Clear;
  TMap.ImgFile := GetImgFile('Map/Map/Map' + LeftStr(ID, 1) + '/' + ID + '.img').Root;
  for Iter in TMap.ImgFile.Child['info'].Children do
    TMap.Info.Add(Iter.Name, Iter.Data);

  TMap.Info.Add('MapWidth', TMap.ImgFile.Get('miniMap/width', '0'));
  TMap.Info.Add('MapHeight', TMap.ImgFile.Get('miniMap/height', '0'));
  TMap.Info.Add('centerX', TMap.ImgFile.Get('miniMap/centerX', DisplaySize.X / 2));
  TMap.Info.Add('centerY', TMap.ImgFile.Get('miniMap/centerY', DisplaySize.Y / 2));
  TFootholdTree.CreateFHs;
  TLadderRope.Create;
  TMapPortal.Create;
  TMapObj.Create;
  TMapTile.Create;
  if TMap.Info.ContainsKey('VRLeft') then
  begin
    SpriteEngine.WorldX := TMap.Info['VRLeft'];
    SpriteEngine.WorldY := TMap.Info['VRBottom']; // - DisplaySize.y;
    TMap.Left := TMap.Info['VRLeft'];
    TMap.Bottom := TMap.Info['VRBottom']+15;
    if TMap.ImgFile.Get('miniMap') <> nil then
    begin
      Bottom2 := -TMap.Info['centerY'] + TMap.Info['MapHeight'] - 55;
      if (TMap.Bottom < Bottom2-100)  then
        TMap.Bottom := Bottom2;
    end;
    TMap.Top := TMap.Info['VRTop'];
    TMap.Right := TMap.Info['VRRight'];
    TMap.Info.AddOrSetValue('MapWidth', Abs(TMap.Left) + Abs(TMap.Right));
  end
  else
  begin
    TMap.Left := TFootholdTree.MinX1.First;
    TMap.Bottom := -TMap.Info['centerY'] + TMap.Info['MapHeight'] - 55;
    TMap.SaveMapBottom := TMap.Bottom - 55;
    TMap.Top := -TMap.Info['centerY'] + 50;
    TMap.Right := TFootholdTree.MaxX2.Last;
    TMap.Info.AddOrSetValue('MapWidth', Abs(TMap.Left) + Abs(TMap.Right));
    SpriteEngine.WorldX := TMap.Left;
    SpriteEngine.WorldY := TMap.Bottom;
  end;
  TMob.CreateMapMobs;

  DropBoss;
  TNpc.Create;
  TNPC.ReDrawTarget := True;
  if not TMap.FirstLoad then
  begin
    TMobInfo.Create;
    Player.SpawnNew;
    FDevice.BeginScene;
   // TLabelRingTag.Create('01112101');
    TNameTag.Create('SuperGM');
    FDevice.EndScene;

    if UIVersion = 3 then
    begin
      TStatusBar3MainBar.CreateUI;
      AMiniMap := TMiniMap.Create(UIEngine.Root);
      with AMiniMap do
      begin
        Width := TMap.MiniMapWidth + 125;
        Height := TMap.MiniMapHeight + 40;
        Left := 150 + 1000;
        Top := 150 + 1000;
      end;
      CreateUIStatusBar3Chat;
      DumpData(GetImgEntry('UI/Basic.img/Cursor/2'), UIData, UIImages);
      DumpData(GetImgEntry('UI/Basic.img/Cursor/0'), UIData, UIImages);
      DumpData(GetImgEntry('UI/Basic.img/Cursor/12'), UIData, UIImages);
      DumpData(GetImgEntry('UI/Basic.img/Cursor/67'), UIData, UIImages);
    end;
    if UIVersion = 1 then
    begin
     TStatusBar.CreateUI;
      AMiniMap := TMiniMap.Create(UIEngine.Root);
      with AMiniMap do
      begin
        Width := TMap.MiniMapWidth + 125;
        Height := TMap.MiniMapHeight + 40;
        Left := 150 + 1000;
        Top := 150 + 1000;
      end;
      DumpData(GetImgEntry('UI/Basic.img/Cursor/0'), UIData, UIImages);
      DumpData(GetImgEntry('UI/Basic.img/Cursor/12'), UIData, UIImages);
    end;

    SpriteEngine.Move(1);
  end;
  if ReLoad then
  begin
    var Entry: TWZIMGEntry;
    var Bmp: TBitmap;
    var MapID: string;
    var LeftNum := LeftStr(ID, 1);
    Entry := GetImgEntry('Map/Map/Map' + LeftNum + '/' + ID + '.img/info/link');
    if Entry = nil then
      MapID := ID
    else
      MapID := Entry.Data;

    LeftNum := LeftStr(MapID, 1);
    Entry := GetImgEntry('Map/Map/Map' + LeftNum + '/' + MapID + '.img/miniMap');
    if Entry = nil then
      Exit;

    if Entry <> nil then
    begin
      TMap.HasMiniMap := True;
      if (Entry.Get('canvas/_outlink') <> nil) then
      begin
        var Data: string := Entry.Get('canvas/_outlink').Data;
        TMap.MiniMapEntry := GetImgEntry(Data);
        Bmp := GetImgEntry(Data).Canvas.DumpBmp;
      end
      else
      begin
        TMap.MiniMapEntry := Entry.Get('canvas');
        Bmp := Entry.Get2('canvas').Canvas.DumpBmp;
      end;

      MiniMapWidth := Bmp.Width;
      MiniMapHeight := Bmp.Height;
      Bmp.Free;
    end;

  end;
 // if UIVersion = 3 then
   AMiniMap.ReDraw;
  //TNameTag.Create('SuperGM');

  TMap.FirstLoad := True;
  TMapBack.Create;
  // CreateReactor;
  TMap.PlayMusic;
  TMapBack.ResetPos := True;
  TMobInfo.ReDrawTarget;
  TSkill.PlayEnded := True;
end;

class procedure TMap.PlayMusic;
var
  Entry: TWZIMGEntry;
  BgmIMG, BgmName: string;
  CPos: Integer;
begin
  TMap.BgmPath := TMap.Info['bgm'];
  TMap.BgmPath := StringReplace(TMap.BgmPath, '.img', '', [rfReplaceAll]);
  TMap.BgmList.Add(TMap.BgmPath);

  if TMap.BgmList.Count > 2 then
    TMap.BgmList.Delete(0);
  if TMap.BgmList.Count > 1 then
    if TMap.BgmPath = TMap.BgmList[0] then
      Exit;

  if TMap.BgmPath = 'Bgm20/Subway' then
    TMap.BgmPath := 'Bgm03/Subway';
  // Label3.Caption := '����: ' + TMap.BgmPath;
  CPos := Pos('/', TMap.BgmPath) - 1;
  BgmIMG := LeftStr(TMap.BgmPath, CPos) + '.img';
  BgmName := RightStr(TMap.BgmPath, Length(TMap.BgmPath) - CPos - 1);

  if GetImgFile('Sound/' + BgmIMG) <> nil then
    Entry := GetImgFile('Sound/' + BgmIMG).Root.Child[BgmName]
  else
    Exit;

  var WZ: TWZArchive;
  for var I in WzList do
  begin
    if LeftStr(I.PathName, 5) = 'Sound' then
    begin
      if I.GetImgFile(BgmIMG) <> nil then
      begin
        WZ := I;
        break;
      end;
    end;
  end;

  if Entry.DataType = mdtSound then
  begin
    if Assigned(ActiveBass) then
      FreeAndNil(ActiveBass);
    ActiveBass := TBassHandler.Create(WZ.Reader.Stream, Entry.Sound.Offset, Entry.Sound.DataLength);
    ActiveBass.PlayLoop;
  end;
end;

initialization
  BassInit;
  TMap.MapNameList := TDictionary<string, TMapNameRec>.Create;
  TMap.BgmList := TList<string>.Create;
  TMap.Info := TDictionary<string, Variant>.Create;
  TMap.ShowTile := True;
  TMap.ShowObj := True;
  TMap.ShowBack := True;
  TMap.ShowFront := True;
  TMap.ShowNPC := True;
  TMap.ShowMob := True;
  TMap.ShowPortal := True;
  TMap.ShowChar := True;
  TMap.ShowUI := True;
  TMap.ShowMiniMap := True;
  TMap.ShowNpcName := True;
  TMap.ShowNpcChat := True;
  TMap.ScrollingMessage := 'Welcome to MapleStory GM Client';


finalization
  BassFree;
  TMap.ActiveBass.Free;
  TMap.Info.Free;
  TMap.BgmList.Free;
  TMap.MapNameList.Free;

end.

