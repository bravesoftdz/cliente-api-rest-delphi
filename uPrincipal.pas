unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.JSON, REST.Client, IPPeerClient, REST.Types, Datasnap.DBClient,
  Data.DB, Vcl.StdCtrls, Vcl.Buttons, Vcl.Grids, Vcl.DBGrids,
  Data.Bind.Components, Data.Bind.ObjectScope, REST.Authenticator.Basic;

type
  TfrmPrincipal = class(TForm)
    DBGrid1: TDBGrid;
    BitBtn1: TBitBtn;
    ClientDataSet: TClientDataSet;
    DataSource: TDataSource;
    HTTPBasicAuthenticator: THTTPBasicAuthenticator;
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }

    // Objetos necess�rio para a comunica��o com a API
    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;
    FRESTResponse: TRESTResponse;

    // Objeto para receber o JSON de retorno
    FJSON: TJSONObject;

    procedure InicializarObjetos;
    procedure EnviarRequisicao;
    procedure LiberarObjetos;
    function ConsultarDadosApiDrIndustrial: olevariant;
    function ProcessarRetorno: olevariant;
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

{ TForm1 }

procedure TfrmPrincipal.BitBtn1Click(Sender: TObject);
begin
  ClientDataSet.Data := ConsultarDadosApiDrIndustrial;
end;

function TfrmPrincipal.ConsultarDadosApiDrIndustrial: olevariant;
begin
  InicializarObjetos;
  EnviarRequisicao;
  result := ProcessarRetorno;
  LiberarObjetos;
end;

procedure TfrmPrincipal.EnviarRequisicao;
begin
  // Configura os par�metros da requisi��o
  // aqui pratim eu digo qual recurso eu quero consumir da minha API Rest, no caso ai o recurso 'coletores'
  FRESTRequest.Resource := 'coletores';

  // Executa a requisi��o
  FRESTRequest.Execute;

  FRESTRequest.GetFullRequestURL();

  // Recebe o retorno em JSON e o atribui ao objeto FJSON
  FJSON.Parse(TEncoding.ASCII.GetBytes(FRESTResponse.JSONValue.ToString), 0);
end;

procedure TfrmPrincipal.InicializarObjetos;
begin
  // Cria o objeto da classe TRESTClient
  // aqui pratim � a URL principal da API Rest
  FRESTClient := TRESTClient.Create('192.168.0.154:8081/');

  // Pratim aqui � um tipo de autoriza��o basic do HTTP tem outros tipos de autentica��o como o JWT que � baseado em tokens, depois estuda sobre "oauth2"
  // Tem que ver se a API que tu vai consumir precisar de autentica��o se n�o precisar n�o precisa dessa linha
  FRESTClient.Authenticator := HTTPBasicAuthenticator;

  // Cria o objeto da classe TRESTResponse
  FRESTResponse := TRESTResponse.Create(nil);

  // Cria e configura o objeto da classe TRESTRequest
  FRESTRequest := TRESTRequest.Create(nil);
  FRESTRequest.Client := FRESTClient;
  FRESTRequest.Response := FRESTResponse;
  // aqui prato � o m�todo que vai executar POST, GET, PUT, DELETE no caso ele vai usar o GET
  // estuda sobre os verbos HTTP
  FRESTRequest.Method := rmGET;

  // Cria o objeto para manipular o JSON
  FJSON := TJSONObject.Create;
end;

procedure TfrmPrincipal.LiberarObjetos;
begin
  FRESTRequest.Free;
  FRESTResponse.Free;
  FRESTClient.Free;
end;

function TfrmPrincipal.ProcessarRetorno: olevariant;
var
  DataSetRetorno: TClientDataSet;
  JSONValue: TJSONValue;
  JSONObject: TJSONObject;
begin
  DataSetRetorno := TClientDataSet.Create(nil);
  try
    // Define as colunas
    DataSetRetorno.FieldDefs.Add('codigo', Data.DB.ftInteger);
    DataSetRetorno.FieldDefs.Add('nome', Data.DB.ftString, 40);
    DataSetRetorno.CreateDataSet;

    // Percorre o JSON, lendo os valores das chaves
    for JSONValue in FRESTResponse.JSONValue as TJSONArray do
    begin
      JSONObject := JSONValue as TJSONObject;

      DataSetRetorno.AppendRecord([
        JSONObject.GetValue('codigo').Value,
        JSONObject.GetValue('nome').Value
      ]);
    end;

    result := DataSetRetorno.Data;
  finally
    DataSetRetorno.Free;
  end;
end;

end.