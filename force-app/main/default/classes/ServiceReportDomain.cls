public without sharing class ServiceReportDomain {
    
    private static ServiceReportDomain instance = null;
    
    public static ServiceReportDomain getInstance() {
        if (instance == null) {
            instance = new ServiceReportDomain();
        }
        
        return instance;
    } 

    public void finishWorkOderLineItem(List<ServiceReport> reports){

        Set<Id> setWOLIIds = new Set<Id>();
        for(ServiceReport report : reports){
            if(report.ParentId != null && report.ParentId.getsObjectType().getDescribe().getName() == 'WorkOrderLineItem'){
                setWOLIIds.add(report.ParentId);
            }
        }
        
        List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
        //Nova verificação, pois estava batendo na regra de validação ImpedeAlteracaoStatus durante update quando a Ata já esta com status de Completed
        for(WorkOrderLineItem woli : [SELECT Id, Status FROM WorkOrderLineItem WHERE Id IN :setWOLIIds AND Status != 'Completed']){
            woli.Status = 'Completed';
            wolis.add(woli);
        }

        /*for(ServiceReport report : reports){
            if(/*report.IsSigned == true && *//*report.ParentId != null && report.ParentId.getsObjectType().getDescribe().getName() == 'WorkOrderLineItem'){
                WorkOrderLineItem woli = new WorkOrderLineItem(
                    Id = report.ParentId,
                    Status = 'Completed'
                );

                wolis.add(woli);
            }
        }*/

        List<Lead> lds = new List<Lead>();
        for(WorkOrderLineItem woli : [SELECT Id, Lead__c FROM WorkOrderLineItem WHERE Id IN : wolis AND Lead__c != null]){
            Lead ld = new Lead(
                Id = woli.Lead__c,
                DataUltimaAta__c = Date.today()
            );

            lds.add(ld);
        }       
        
        update wolis;
        TriggerHandler.bypass(LeadTriggerHandler.class);
        Database.update(lds, false);
        TriggerHandler.clearBypass(LeadTriggerHandler.class);
        
    }
    
}