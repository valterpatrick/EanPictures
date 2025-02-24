unit uEanPictures;

interface

uses
  IdHTTP, IdGlobal, IdSSLOpenSSL, System.Classes, IdStack, System.SysUtils,
  System.JSON, IdException, DateUtils;

type
  TEanPictures = class
  private
    FStatus: String;
    FStatusDesc: String;
    FGtin: String;
    FNome: String;
    FNCM: String;
    FCodigoCEST: String;
    FEmbalagem: String;
    FQuantEmbalagem: String;
    FMarca: String;
    FCategoria: String;
    FIdCategoria: String;
    FTributacao: String;
    FPeso: String;
    FCaminhoImagem: String;
    FImagem: String;
    FLinkImagem: String;
    FLinkDescProduto: String;
    FLinkDadosProduto: String;
    FURLImagem: String;
    FURLDescProduto: String;
    FURLDadosProduto: String;
    function ApiGtin(Tipo: String): Boolean;
    procedure LimparDados;
  public
    constructor Create(Gtin, CaminhoImg: String);
    property Status: string read FStatus;
    property StatusDesc: string read FStatusDesc;
    property Gtin: string read FGtin;
    property Nome: string read FNome;
    property NCM: string read FNCM;
    property CodigoCEST: string read FCodigoCEST;
    property Embalagem: string read FEmbalagem;
    property QuantEmbalagem: string read FQuantEmbalagem;
    property Marca: string read FMarca;
    property Categoria: string read FCategoria;
    property IdCategoria: string read FIdCategoria;
    property Tributacao: string read FTributacao;
    property Peso: string read FPeso;
    property CaminhoImagem: string read FCaminhoImagem write FCaminhoImagem;
    property Imagem: string read FImagem;
    property LinkImagem: string read FLinkImagem;
    property LinkDescProduto: string read FLinkDescProduto;
    property LinkDadosProduto: string read FLinkDadosProduto;
    function PesquisaImagem: Boolean;
    function PesquisaDescricao: Boolean;
    function PesquisaDadosProduto: Boolean;
    function Pesquisa: Boolean;
  end;

implementation

{ TEanPictures }

function TEanPictures.ApiGtin(Tipo: String): Boolean;
var
  HTTP: TIdHTTP;
  SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
  JSON: TJSONObject;
  ImageStream: TMemoryStream;
  Response: String;
begin
  LimparDados;
  HTTP := TIdHTTP.Create(nil);
  SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  ImageStream := TMemoryStream.Create;
  try
    SSLHandler.SSLOptions.Method := sslvTLSv1_2;
    SSLHandler.SSLOptions.Mode := sslmClient;
    HTTP.IOHandler := SSLHandler;
    HTTP.Request.ContentType := 'application/json';
    HTTP.Request.ContentLength := 0;
    HTTP.Request.Accept := '*/*';
    HTTP.Request.CharSet := 'UTF-8';
    try
      if (Tipo = 'D') or (Tipo = 'T') then
      begin
        FLinkDadosProduto := FURLDadosProduto + FGtin;
        Response := HTTP.Get(FLinkDadosProduto);
        Response := IndyTextEncoding_UTF8.GetString(IndyTextEncoding_OSDefault.GetBytes(Response));
        JSON := TJSONObject.ParseJSONValue(Response) as TJSONObject;
        try
          if (JSON as TJSONObject).GetValue('Status').Value.Trim = '200' then
          begin
            if JSON is TJSONObject then
            begin
              FCategoria := (JSON as TJSONObject).GetValue('Categoria').Value.Trim;
              FCodigoCEST := (JSON as TJSONObject).GetValue('Cest_Codigo').Value.Trim;
              FEmbalagem := (JSON as TJSONObject).GetValue('Embalagem').Value.Trim;
              FIdCategoria := (JSON as TJSONObject).GetValue('id_categoria').Value.Trim;
              FMarca := (JSON as TJSONObject).GetValue('Marca').Value.Trim;
              FNCM := (JSON as TJSONObject).GetValue('Ncm').Value.Trim;
              FNome := (JSON as TJSONObject).GetValue('Nome').Value.Trim;
              FPeso := (JSON as TJSONObject).GetValue('Peso').Value.Trim;
              FQuantEmbalagem := (JSON as TJSONObject).GetValue('QuantidadeEmbalagem').Value.Trim;
              FStatus := (JSON as TJSONObject).GetValue('Status').Value.Trim;
              FStatusDesc := (JSON as TJSONObject).GetValue('Status_Desc').Value.Trim;
              FTributacao := (JSON as TJSONObject).GetValue('tributacao').Value.Trim;
            end;
          end
          else
          begin
            FStatus := (JSON as TJSONObject).GetValue('Status').Value.Trim;
            FStatusDesc := (JSON as TJSONObject).GetValue('Status_Desc').Value.Trim;
          end;
        finally
          JSON.Free;
        end;
      end;
      if (Tipo = 'I') or (Tipo = 'T') then
      begin
        FLinkImagem := FURLImagem + FGtin;
        ImageStream := TMemoryStream.Create;
        try
          HTTP.Get(FLinkImagem, ImageStream);
          FImagem := FCaminhoImagem + '\' + FGtin + '.png';
          ImageStream.SaveToFile(Imagem);
        except
          FStatusDesc := 'Imagem não encontrada.';
        end;
      end;
      if Tipo = 'N' then
      begin
        FLinkDescProduto := FURLDescProduto + FGtin;
        Response := HTTP.Get(FLinkDescProduto);
        JSON := TJSONObject.ParseJSONValue(Response) as TJSONObject;
        if JSON is TJSONObject then
        begin
          FStatus := (JSON as TJSONObject).GetValue('Status').Value.Trim;
          FStatusDesc := (JSON as TJSONObject).GetValue('Status_Desc').Value.Trim;
          FNome := FStatusDesc;
        end
        else
          FNome := Response.Trim
      end;
      Result := True;
    except
      on E: Exception do
        raise Exception.Create(E.Message);
    end;
  finally
    HTTP.Free;
    SSLHandler.Free;
    ImageStream.Free;
  end;
end;

constructor TEanPictures.Create(Gtin, CaminhoImg: String);
begin
  LimparDados;
  FGtin := Gtin;
  FCaminhoImagem := CaminhoImg;
  FURLImagem := 'http://www.eanpictures.com.br:9000/api/gtin/';
  FURLDescProduto := 'http://www.eanpictures.com.br:9000/api/descricao/';
  FURLDadosProduto := 'http://www.eanpictures.com.br:9000/api/desc/';
end;

procedure TEanPictures.LimparDados;
begin
  FStatus := '';
  FStatusDesc := '';
  FNome := '';
  FNCM := '';
  FCodigoCEST := '';
  FEmbalagem := '';
  FQuantEmbalagem := '';
  FMarca := '';
  FCategoria := '';
  FIdCategoria := '';
  FTributacao := '';
  FPeso := '';
  FImagem := '';
  FLinkImagem := '';
  FLinkDescProduto := '';
  FLinkDadosProduto := '';
end;

function TEanPictures.Pesquisa: Boolean;
begin
  if (FGtin.Trim = '') then
    raise Exception.Create('Gtin inválido.');
  if not DirectoryExists(FCaminhoImagem) then
    raise Exception.Create('Caminho para salvar a imagem inválido.');

  Result := ApiGtin('T');
end;

function TEanPictures.PesquisaDadosProduto: Boolean;
begin
  if (FGtin.Trim = '') then
    raise Exception.Create('Gtin inválido.');

  Result := ApiGtin('D');
end;

function TEanPictures.PesquisaDescricao: Boolean;
begin
  if (FGtin.Trim = '') then
    raise Exception.Create('Gtin inválido.');

  Result := ApiGtin('N');
end;

function TEanPictures.PesquisaImagem: Boolean;
begin
  if (FGtin.Trim = '') then
    raise Exception.Create('Gtin inválido.');
  if not DirectoryExists(FCaminhoImagem) then
    raise Exception.Create('Caminho para salvar a imagem inválido.');

  Result := ApiGtin('I');
end;

end.
