global class VinculacaoLeadMetaBatch implements Database.Batchable<sObject> {

    public static Map<String, String> myMap = new Map<String, String>{
        '01' => 'Janeiro', 
        '02' => 'Fevereiro', 
        '03' => 'Março',
        '04' => 'Abril', 
        '05' => 'Maio', 
        '06' => 'Junho',
        '07' => 'Julho', 
        '08' => 'Agosto', 
        '09' => 'Setembro',
        '10' => 'Outubro', 
        '11' => 'Novembro', 
        '12' => 'Dezembro'
    };

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [SELECT 
            Id,
            OwnerId,
            Owner.Name,
            CreatedDate
            FROM
            Lead
            WHERE Meta__c = null
            ]
        );
    }

    global void execute(Database.BatchableContext BC, List<Lead> leads) {

        Map<Id, String> mapLeadExternal = new Map<Id, String>();

        for(Lead l : leads){
            if(l.OwnerId.getsObjectType().getDescribe().getName() == 'User'){
                String externalId = l.CreatedDate.format('YYYY') + getMonthBR(l.CreatedDate.format('MM')) + l.OwnerId;
                mapLeadExternal.put(l.Id, externalId);
            }
        }

        //System.debug(mapLeadMetaExternal);

        List<Meta__c> metas = [SELECT Id, IdExterno__c FROM Meta__c WHERE IdExterno__c IN :mapLeadExternal.values()];

        Map<String, Id> mapMetas = new Map<String, Id>();
        for(Meta__c meta : metas){
            mapMetas.put(meta.IdExterno__c, meta.Id);
        }

        //System.debug(mapMetas);

        List<Lead> leadsToUpdate = new List<Lead>();
        for(Id leadId : mapLeadExternal.keySet()){
            Lead opptToUpdate = new Lead(
                Id = leadId,
                Meta__c = mapMetas.get(mapLeadExternal.get(leadId))
            );

            leadsToUpdate.add(opptToUpdate);
        }

        TriggerHandler.bypass(LeadTriggerHandler.class);
        List<Database.SaveResult> SR = Database.update(leadsToUpdate, false);
        TriggerHandler.clearBypass(LeadTriggerHandler.class);
    }

    global void finish(Database.BatchableContext BC) {
        
    }

    public static String getMonthBR(String numberS){
        return myMap.get(numberS);
    }
}