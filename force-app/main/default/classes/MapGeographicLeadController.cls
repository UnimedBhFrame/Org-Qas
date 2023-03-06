public with sharing class MapGeographicLeadController {
    
    //TO DO fazer classe de TEST
    private final static List<LegendaMapaGeografico__mdt> legendas = [SELECT Id, MasterLabel, StatusLead__c, Cor__c FROM LegendaMapaGeografico__mdt];

    @AuraEnabled(cacheable=true)
    public static Boolean checkPermissionMap(){
        return FeatureManagement.checkPermission('FSL_Mapa_Lead_Geografico');
    }

    @AuraEnabled(cacheable=true)
    public static String verificarFiltrosAnteriores() {
        
        User usuario = [SELECT Id, FiltroMapaGeo__c FROM User WHERE Id = :UserInfo.getUserId()];
        String filtros = usuario.FiltroMapaGeo__c != null ? usuario.FiltroMapaGeo__c : '{}';
        return filtros;
    }

    @AuraEnabled
    public static void salvarFiltros(String inicio, String fim, List<String> status, List<String> canalEntrada, Boolean exCliente, List<String> tipoRegistro, List<String> porte, List<String> rating) {

        FiltrosMapGeo fmg = new FiltrosMapGeo();
        fmg.inicio = inicio;
        fmg.fim = fim;
        fmg.status = status;
        fmg.canalEntrada = canalEntrada;
        fmg.exCliente = exCliente;
        fmg.tipoRegistro = tipoRegistro;
        fmg.porte = porte;
        fmg.rating = rating;
        String filtros = JSON.serialize(fmg);
        
        User usuario = new User(Id = UserInfo.getUserId());
        usuario.FiltroMapaGeo__c = filtros;
        update usuario;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Lead> obtainLeads(List<String> status, List<String> canalEntrada, Boolean exCliente, List<String> tipoRegistro, List<String> porte, List<String> rating, String inicio, String fim) {
        
        String valueExCliente = exCliente == true ? 'Sim' : 'Não';

        Datetime dtInicio = Datetime.valueOf(inicio + ' 00:00:00');
        Datetime dtFim = Datetime.valueOf(fim + ' 00:00:00');
        dtFim = dtFim.addDays(1);
        
        return [SELECT Id, Name, LeadSource, Status, Owner.Name, Phone, Email, MobilePhone, Longitude__c, Latitude__c, Coordenadas__Longitude__s, Coordenadas__Latitude__s 
        FROM Lead 
        WHERE Longitude__c != null
        AND Status IN :status
        AND (CanalEntrada__c IN :canalEntrada OR CanalEntrada__c = null)
       /* AND ExCliente__c = :valueExCliente*/
        AND RecordType.DeveloperName IN :tipoRegistro
        AND Porte__c IN :porte
        AND (Rating IN :rating OR Rating = null)
        AND CreatedDate >= :dtInicio AND CreatedDate < :dtFim
        LIMIT 40000];
    }

    @AuraEnabled(cacheable=true)
    public static List<LegendaMapaGeografico__mdt> obtainLegends(){
        return legendas;
    }

    public class FiltrosMapGeo {

        public String inicio {get;set;}
        public String fim {get;set;}
        public List<String> status {get;set;}
        public List<String> canalEntrada {get;set;}
        public Boolean exCliente {get;set;}
        public List<String> tipoRegistro {get;set;}
        public List<String> porte {get;set;}
        public List<String> rating {get;set;}
        
    }
}