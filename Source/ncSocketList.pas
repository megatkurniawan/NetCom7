unit ncSocketList;

/// ////////////////////////////////////////////////////////////////////////////
//
// TSocketList
// Written by Demos Bill, Tue 21/10/2004
//
// SocketList, the equivalent of TStringList
// but for the type of TSocket handles
//
/// ////////////////////////////////////////////////////////////////////////////

interface

uses System.Classes, System.SysUtils, System.RTLConsts, ncLines;

type
  TSocketItem = record
    FSocketHandle: TSocketHandle;
    FLine: TncLine;
  end;

  PSocketItem = ^TSocketItem;

  TSocketItemList = array of TSocketItem;
  PSocketItemList = ^TSocketItemList;

  TSocketList = class(TPersistent)
  private
    FList: TSocketItemList;
    FCount: Integer;
    FCapacity: Integer;
    function GetSocketHandle(Index: Integer): TSocketHandle; register;
    function GetLine(Index: Integer): TncLine; register;
    procedure PutLine(Index: Integer; aLine: TncLine);
    procedure SetCapacity(aNewCapacity: Integer);
  protected
    procedure Insert(aIndex: Integer; const aSocketHandle: TSocketHandle; aLine: TncLine);
    procedure Grow;
    class function CompareSockets(const aSocketHandle1, aSocketHandle2: TSocketHandle): Integer; inline; static;
  public
    destructor Destroy; override;

    function Add(const aSocketHandle: TSocketHandle; aLine: TncLine): Integer;
    procedure Clear;
    procedure Delete(aIndex: Integer); register;
    function Find(const aSocketHandle: TSocketHandle; var aIndex: Integer): Boolean; register;
    function IndexOf(const aSocketHandle: TSocketHandle): Integer; register;

    property Count: Integer read FCount;
    property SocketHandles[index: Integer]: TSocketHandle read GetSocketHandle; default;
    property Lines[index: Integer]: TncLine read GetLine write PutLine;
  end;

implementation

resourcestring
  SDuplicateSocketHandle = 'Socket handle list does not allow duplicates';

  { TSocketList }

destructor TSocketList.Destroy;
begin
  inherited Destroy;
  FCount := 0;
  SetCapacity(0);
end;

function TSocketList.Add(const aSocketHandle: TSocketHandle; aLine: TncLine): Integer;
begin
  if Find(aSocketHandle, Result) then
    raise Exception.Create(SDuplicateSocketHandle);
  Insert(Result, aSocketHandle, aLine);
end;

procedure TSocketList.Clear;
begin
  if FCount <> 0 then
  begin
    FCount := 0;
    SetCapacity(0);
  end;
end;

procedure TSocketList.Delete(aIndex: Integer);
begin
  if (aIndex < 0) or (aIndex >= FCount) then
    raise Exception.Create(Format(SListIndexError, [aIndex]));

  Dec(FCount);
  if aIndex < FCount then
    System.Move(FList[aIndex + 1], FList[aIndex], (FCount - aIndex) * SizeOf(TSocketItem));
end;

// Binary Searching

function TSocketList.Find(const aSocketHandle: TSocketHandle; var aIndex: Integer): Boolean;
var
  Low, High, Mid, Comparison: Integer;
begin
  Result := False;
  Low := 0;
  High := FCount - 1;
  while Low <= High do
  begin
    Mid := (Low + High) shr 1;
    Comparison := CompareSockets(FList[Mid].FSocketHandle, aSocketHandle);
    if Comparison < 0 then
      Low := Mid + 1
    else
    begin
      High := Mid - 1;
      if Comparison = 0 then
      begin
        Result := True;
        Low := Mid;
      end;
    end;
  end;
  aIndex := Low;
end;

procedure TSocketList.Grow;
var
  Delta: Integer;
begin
  if FCapacity > 64 then
    Delta := FCapacity div 4
  else if FCapacity > 8 then
    Delta := 16
  else
    Delta := 4;
  SetCapacity(FCapacity + Delta);
end;

function TSocketList.IndexOf(const aSocketHandle: TSocketHandle): Integer;
begin
  if not Find(aSocketHandle, Result) then
    Result := -1;
end;

procedure TSocketList.Insert(aIndex: Integer; const aSocketHandle: TSocketHandle; aLine: TncLine);
begin
  if FCount = FCapacity then
    Grow;
  if aIndex < FCount then
    System.Move(FList[aIndex], FList[aIndex + 1], (FCount - aIndex) * SizeOf(TSocketItem));
  with FList[aIndex] do
  begin
    FSocketHandle := aSocketHandle;
    FLine := aLine;
  end;
  Inc(FCount);
end;

class function TSocketList.CompareSockets(const aSocketHandle1, aSocketHandle2: TSocketHandle): Integer;
begin
  Result := aSocketHandle1 - aSocketHandle2;
end;

function TSocketList.GetSocketHandle(Index: Integer): TSocketHandle;
begin
  if (index < 0) or (index >= FCount) then
    raise Exception.Create(Format(SListIndexError, [index]));
  Result := FList[index].FSocketHandle;
end;

function TSocketList.GetLine(Index: Integer): TncLine;
begin
  if (index < 0) or (index >= FCount) then
    raise Exception.Create(Format(SListIndexError, [index]));
  Result := FList[index].FLine;
end;

procedure TSocketList.PutLine(Index: Integer; aLine: TncLine);
begin
  if (index < 0) or (index >= FCount) then
    raise Exception.Create(Format(SListIndexError, [index]));
  FList[index].FLine := aLine;
end;

procedure TSocketList.SetCapacity(aNewCapacity: Integer);
begin
  if aNewCapacity < FCount then
    raise Exception.Create(Format(SListCapacityError, [aNewCapacity]));
  if aNewCapacity <> FCapacity then
  begin
    SetLength(FList, aNewCapacity);
    FCapacity := aNewCapacity;
  end;
end;

end.
