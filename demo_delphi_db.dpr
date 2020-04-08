Program demo_delphi_db;

{$APPTYPE CONSOLE}
{$R *.res}

Uses
  System.SysUtils, ADODB, DB, ActiveX;

const
  connectionString = 'Provider=SQLNCLI11.1;Persist Security Info=False;' +
    'Integrated Security=SSPI;User ID=%s;Password=%s;' +
    'Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=delphi;';

var
  name: string;
  password: string;
  dbConnection: TADOConnection;

procedure LogConnecting(name: string);
var
  command: TADOCommand;
begin
  command := TADOCommand.Create(nil);
  try
    command.Parameters.Clear;
    command.Connection := dbConnection;
    command.CommandText :=
      'insert into [dbo].[history] ([username], [logged_at]) values (:username, :loggedAt)';
    command.ParamCheck := False;
    command.Parameters.ParamByName('username').Value := name;
    command.Parameters.ParamByName('loggedAt').Value := DateTimeToStr(Now);
    command.Execute;
  finally
    command.Free;
  end;
end;

procedure Connect(name, password: string);
begin
  dbConnection := TADOConnection.Create(nil);
  dbConnection.LoginPrompt := False;
  dbConnection.connectionString := Format(connectionString, [name, password]);
  dbConnection.Connected := True;

  LogConnecting(name);
end;

procedure Disconnect();
begin
  if dbConnection.Connected then
  begin
    dbConnection.Close;
    dbConnection.Free
  end;
end;

procedure DisplayDepartments();
const
  departmentColumnName = 'department';
  bossColumnName = 'boss';
  amountColumnName = 'amount';
var
  query: TADOQuery;
  departmentName: string;
  bossName: string;
  employeeAmount: string;
begin
  query := TADOQuery.Create(nil);
  try
    query.Connection := dbConnection;
    query.SQL.Add('select d.name as ' + departmentColumnName + ', e2.name as ' +
      bossColumnName + ', count(e.id) as ' + amountColumnName +
      ' from departments d join employees e on e.department_id = d.id' +
      ' join employees e2 on e2.id = d.boss_id group by d.name, e2.name');
    query.Open;

    writeln('Department Boss Amount');

    while not query.Eof do
    begin
      departmentName := query.FieldByName(departmentColumnName).AsString;
      bossName := query.FieldByName(bossColumnName).AsString;
      employeeAmount := query.FieldByName(amountColumnName).AsString;

      writeln(Format('%s %s %s', [Trim(departmentName), Trim(bossName),
        Trim(employeeAmount)]));
      query.Next;
    end;
  finally
    query.Free;
  end;
end;

begin
  CoInitialize(nil);
  try
    try
      writeln('enter your name: ');
      Readln(name);
      writeln('enter password: ');
      Readln(password);

      Connect(name, password);
      DisplayDepartments;
    except
      on e: Exception do
        writeln(e.ClassName, ':', e.Message);
    end;
    Readln;
  finally
    Disconnect;
    CoUninitialize;
  end;

end.
