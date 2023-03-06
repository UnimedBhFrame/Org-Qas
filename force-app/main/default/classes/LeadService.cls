public without sharing class LeadService {
    
    private static LeadService instance = null;
    
    public static LeadService getInstance() {
        if (instance == null) {
            instance = new LeadService();
        }
        
        return instance;
    }

    public void sendRelationshipToAccount(List<Lead> leads){
        Map<Id, Id> mapLeadAccount = new Map<Id, Id>();

        for(Lead ld : leads){
            mapLeadAccount.put(ld.Id, ld.ConvertedAccountId);
        }

        List<WorkOrder> wos = [SELECT Id, Lead__c FROM WorkOrder WHERE Lead__c IN :leads];
        //Pela WorkOrder o Account do ServiceAppointment já é preenchido automatico
       // List<ServiceAppointment> appts = [SELECT Id, Lead__c FROM ServiceAppointment WHERE Lead__c IN :leads]; 
        List<WorkOrderLineItem> wolis = [SELECT Id, Lead__c FROM WorkOrderLineItem WHERE Lead__c IN :leads];

        for(WorkOrder wo : wos){
            wo.AccountId = mapLeadAccount.get(wo.Lead__c);
        }

       /* for(ServiceAppointment appt : appts){
            appt.AccountId = mapLeadAccount.get(appt.Lead__c);
        }*/

        for(WorkOrderLineItem woli : wolis){
            woli.Account__c = mapLeadAccount.get(woli.Lead__c);
        }

        TriggerHandler.bypass(WorkOrderTriggerHandler.class);
        Database.update(wos, false);
        TriggerHandler.clearBypass(WorkOrderTriggerHandler.class);

       /* TriggerHandler.bypass(ServiceAppointmentTriggerHandler.class);
        Database.update(appts, false);
        TriggerHandler.clearBypass(ServiceAppointmentTriggerHandler.class);*/

        Database.update(wolis, false);
    }
}