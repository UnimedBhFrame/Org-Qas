public with sharing class MapGeographicController {

    @AuraEnabled(cacheable=true)
    public static Boolean checkPermissionMap(){
        return FeatureManagement.checkPermission('FSL_Mapa_Rastreamento_Geografico');
    }

    @AuraEnabled
    public static List<String> verificarFiltrosAnteriores() {
        
        User usuario = [SELECT Id, FiltrosRastreamentoGeo__c, FiltrosRastreamentoGeo2__c FROM User WHERE Id = :UserInfo.getUserId()];
        String filtros1 = usuario.FiltrosRastreamentoGeo__c != null ? usuario.FiltrosRastreamentoGeo__c : '{}';
        String filtros2 = usuario.FiltrosRastreamentoGeo2__c != null ? usuario.FiltrosRastreamentoGeo2__c : '{}';
        List<String> filtros = new List<String>();
        filtros.add(filtros1);
        filtros.add(filtros2);
                
        return filtros;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ServiceResource> obtainServiceResource(Boolean isFisica, Boolean isJuridica, List<String> tipo, List<String> porte, String serviceTerritoryId){
    
        List<MembroDistribuicaoVisita__c> membros = [SELECT Id, 
                                                        ServiceResource__c 
                                                        FROM MembroDistribuicaoVisita__c 
                                                        WHERE (DistribuicaoVisita__r.PessoaFisica__c = :isFisica 
                                                        OR (DistribuicaoVisita__r.PessoaJuridica__c = :isJuridica AND DistribuicaoVisita__r.Porte__c IN :porte))
                                                        AND DistribuicaoVisita__r.Tipo__c IN :tipo];
     
        Set<Id> resourceId = new Set<Id>();
        for(MembroDistribuicaoVisita__c membro : membros){
            resourceId.add(membro.ServiceResource__c);
        }

        //Filter by Territory
        if(String.isNotBlank(serviceTerritoryId)){
            Set<Id> serviceTerritoryIds = new Set<Id>();
            
            serviceTerritoryIds.add(serviceTerritoryId);
            for(ServiceTerritory serTerri : [SELECT Id, ParentTerritoryId FROM ServiceTerritory WHERE Id = :serviceTerritoryId]){
                serviceTerritoryIds.add(serTerri.ParentTerritoryId);
            }

            Set<Id> resourceIdTerritory = new Set<Id>();
            for(ServiceTerritoryMember member : [SELECT Id, ServiceResourceId, ServiceTerritoryId FROM ServiceTerritoryMember WHERE ServiceResourceId IN :resourceId AND ServiceTerritoryId IN :serviceTerritoryIds]){
                resourceIdTerritory.add(member.ServiceResourceId);
            }

            resourceId = resourceIdTerritory;
        }
                
        return [SELECT Id, Name, LastKnownLatitude, LastKnownLongitude, LastKnownLocationDate, MinutosUltimaLocalizacao__c FROM ServiceResource WHERE LastKnownLocationDate != null AND Id IN :resourceId];
    }

    @AuraEnabled
    public static void salvarFiltros(Boolean isFisica, Boolean isJuridica, List<String> tipo, List<String> porte, String serviceTerritoryId, String serviceResourceId, String inicio, String fim) {

        FiltrosRastreamento fr = new FiltrosRastreamento();
        fr.isFisica = isFisica;
        fr.isJuridica = isJuridica;
        fr.tipo = tipo;
        fr.porte = porte;
        fr.serviceTerritoryId = serviceTerritoryId;
        String filtros1 = JSON.serialize(fr);
        FiltrosRastreamento2 fr2 = new FiltrosRastreamento2();
        fr2.inicio = inicio;
        fr2.fim = fim;
        fr2.serviceResourceId = serviceResourceId;
        String filtros2 = JSON.serialize(fr2);

        User usuario = new User(Id = UserInfo.getUserId());
        usuario.FiltrosRastreamentoGeo__c = filtros1;
        usuario.FiltrosRastreamentoGeo2__c = filtros2;
        update usuario;
    }

    @AuraEnabled(cacheable=true)
    public static List<RastreamentoRecursoServico__b> obtainLocations(String serviceResourceId, String inicio, String fim) {

        Datetime dateInitial = Datetime.valueOf(inicio + ' 00:00:00');
        Datetime dateFinal = Datetime.valueOf(fim + ' 00:00:00');
        dateFinal = dateFinal.addDays(1);

        if (serviceResourceId == null) {

            Map<Id, ServiceResource> mapServiceResources = new Map<Id, ServiceResource>([SELECT Id FROM ServiceResource]);

            return [SELECT ServiceResource__c, DataLocalizacao__c, Latitude__c, Longitude__c FROM RastreamentoRecursoServico__b 
                WHERE ServiceResource__c IN :mapServiceResources.keySet()
                AND DataLocalizacao__c >= :dateInitial 
                AND DataLocalizacao__c < :dateFinal];
        }
                
        return [SELECT ServiceResource__c, DataLocalizacao__c, Latitude__c, Longitude__c FROM RastreamentoRecursoServico__b 
        WHERE ServiceResource__c = :serviceResourceId 
        AND DataLocalizacao__c >= :dateInitial 
        AND DataLocalizacao__c < :dateFinal];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> obtainServiceAppointment(String serviceResourceId, String inicio, String fim) {

        Datetime dateInitial = Datetime.valueOf(inicio + ' 00:00:00');
        Datetime dateFinal = Datetime.valueOf(fim + ' 00:00:00');
        dateFinal = dateFinal.addDays(1);

        String query = 'SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource ' + 
            'WHERE ServiceAppointment.SchedStartTime >= :dateInitial AND ServiceAppointment.SchedStartTime < :dateFinal';
        if (serviceResourceId != null) {
            query += ' AND ServiceResourceId = :serviceResourceId';
        }
        List<AssignedResource> assigneds = Database.query(query);
        
        /*
        List<AssignedResource> assigneds = [SELECT Id, ServiceAppointmentId, ServiceResourceId 
        FROM AssignedResource 
        WHERE ServiceAppointment.SchedStartTime >= :dateInitial AND
        ServiceAppointment.SchedStartTime < :dateFinal AND
        ServiceResourceId = :serviceResourceId];*/

        Set<Id> serviceAppointmentIds = new Set<Id>();
        for(AssignedResource ass : assigneds){
            serviceAppointmentIds.add(ass.ServiceAppointmentId);
        }
        
        return [SELECT Id, Status, SchedStartTime, ActualStartTime, Lead__c, Lead__r.Name, Lead__r.Status, Lead__r.Phone, Lead__r.Latitude, Lead__r.Longitude, Lead__r.Street, Lead__r.State, Lead__r.City, Lead__r.PostalCode, Lead__r.Country, Lead__r.Coordenadas__Latitude__s, Lead__r.Coordenadas__Longitude__s FROM ServiceAppointment WHERE Id IN :serviceAppointmentIds];
    }

    public class FiltrosRastreamento {

        public Boolean isFisica {get;set;}
        public Boolean isJuridica {get;set;}
        public List<String> tipo {get;set;}
        public List<String> porte {get;set;}
        public String serviceTerritoryId {get;set;}
    }

    public class FiltrosRastreamento2 {

        public String inicio {get;set;}
        public String fim {get;set;}
        public String serviceResourceId {get;set;}
    }
}