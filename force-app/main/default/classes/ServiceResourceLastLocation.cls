global class ServiceResourceLastLocation implements Database.Batchable<sObject> {

    private Map<Id, List<Id>> mapaIdUsuario = new Map<Id, List<Id>>();
    private Map<Id, String> mapMsg = new Map<Id, String>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [SELECT Id, 
            MinutosUltimaLocalizacao__c, 
            Name, 
            RelatedRecordId,
            RelatedRecord.Name,
            RelatedRecord.UserRoleId,
            LastKnownLocationDate, 
            OwnerId, 
            EmailAtrasoJornadaTrabalho__c 
            FROM ServiceResource WHERE LastKnownLocationDate != null AND MinutosUltimaLocalizacao__c > 30 AND MinutosUltimaLocalizacao__c < 60]
        );
    }

    global void execute(Database.BatchableContext BC, List<ServiceResource> lsa) {

        Map<Id, Id> mapTseRole = new Map<Id, Id>();
        for(ServiceResource sr : lsa){
            if(sr.RelatedRecord.UserRoleId != null){
                mapTseRole.put(sr.Id, sr.RelatedRecord.UserRoleId);
            }
        }
                
        Map<Id, Set<Id>> mapRoleAboveUsers = RoleUtils.getRoleUsers(new Set<Id>(mapTseRole.values()));

        for (ServiceResource sa : lsa){
			
        mapaIdUsuario.put(sa.Id, new List<Id>{/*sa.RelatedRecordId*/});

            String msg = 'Prezado gestor, o usuário '+sa.Name+' ficou sem sinal de GPS por mais de 30 minutos, no dia '+sa.LastKnownLocationDate.date().format()+' a partir das '+sa.LastKnownLocationDate.format('HH:mm')+'.';
            mapMsg.put(sa.Id, msg);

            if(sa.RelatedRecord.UserRoleId != null){
                mapaIdUsuario.get(sa.Id).addAll(new List<Id>(mapRoleAboveUsers.get(sa.RelatedRecord.UserRoleId)));
            }

        }
        
        PostChatter.PostForUsers(mapaIdUsuario, mapMsg, true);
    }

    global void finish(Database.BatchableContext BC) {
        
    }
    
}