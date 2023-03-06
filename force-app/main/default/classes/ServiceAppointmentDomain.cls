public without sharing class ServiceAppointmentDomain {

    final private static Expediente__mdt expediente = [SELECT Id, HoraInicio__c, HoraFim__c FROM Expediente__mdt LIMIT 1];
    
    private static ServiceAppointmentDomain instance = null;
    
    public static ServiceAppointmentDomain getInstance() {
        if (instance == null) {
            instance = new ServiceAppointmentDomain();
        }
        
        return instance;
    } 

    public void copyLeadFromWorkOrder(List<ServiceAppointment> appts){
        
        Map<Id, Id> mapApptWO = new Map<Id, Id>();

        for(ServiceAppointment appt : appts){
            if(appt.ParentRecordId != null && appt.ParentRecordId.getsObjectType().getDescribe().getName() == 'WorkOrder'){
                mapApptWO.put(appt.Id, appt.ParentRecordId);
            }
        }

        Map<Id, WorkOrder> mapWorkOrder = new Map<Id, WorkOrder>([SELECT Id, Lead__c FROM WorkOrder WHERE Id IN :mapApptWO.values()]);

        for(ServiceAppointment appt: appts){
            if(mapApptWO.containsKey(appt.Id) && mapWorkOrder.containsKey(appt.ParentRecordId) && mapWorkOrder.get(appt.ParentRecordId).Lead__c != null){
                appt.Lead__c = mapWorkOrder.get(appt.ParentRecordId).Lead__c;
            }
        }
    }

    public void sendEmail(List<ServiceAppointment> appts, Map<Id, ServiceAppointment> oldAppts){
        List<ServiceAppointment> apptsToSendEmail = new List<ServiceAppointment>();

        for(ServiceAppointment appt : appts){
            if((appt.Status == 'Scheduled' && oldAppts.get(appt.Id).Status != 'Scheduled') || (appt.Status == 'Canceled' && oldAppts.get(appt.Id).Status != 'Canceled') || (appt.Reagendamento__c == true && oldAppts.get(appt.Id).Reagendamento__c != true)) {
                apptsToSendEmail.add(appt);
            }
        }

        if(apptsToSendEmail.size() > 0){
            ServiceAppointmentService.getInstance().sendEmail(apptsToSendEmail);
        }
    }

    public void setPrimeiraVisitaRealizadaLead(List<ServiceAppointment> appts, Map<Id, ServiceAppointment> oldAppts){
        List<Lead> leads = new List<Lead>();

        for(ServiceAppointment appt : appts){
            if(appt.Status == 'Completed' && oldAppts.get(appt.Id).Status != 'Completed' && appt.Lead__c != null){
                Lead l = new Lead(
                    Id = appt.Lead__c,
                    PrimeiraVisitaRealizada__c = true
                );

                leads.add(l);
            }
        }

        TriggerHandler.bypass(LeadTriggerHandler.class);
        Database.update(leads, false);
        TriggerHandler.clearBypass(LeadTriggerHandler.class);
    }

    public void updateOwner(List<ServiceAppointment> appts, Map<Id, ServiceAppointment> oldAppts){
        List<Lead> leadsToUpdate = new List<Lead>();
        
        Map<Id, Id> mapLeadSR = new Map<Id, Id>();

        for(ServiceAppointment appt : appts){
            if((appt.Status == 'Scheduled' && oldAppts.get(appt.Id).Status != 'Scheduled') && 
            appt.Lead__c != null && appt.ServiceResource__c != null && (appt.SchedStartTime != null || appt.EarliestStartTime != null)){
                mapLeadSR.put(appt.Lead__c, appt.ServiceResource__c);
            }
        }
        
        Map<Id, ServiceResource> mapSR = new Map<Id, ServiceResource>([SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN : mapLeadSR.values()]);
        for(Id leadId : mapLeadSR.keySet()){
            Lead ld = new Lead(
            	Id = leadId,
                OwnerId = mapSR.get(mapLeadSR.get(leadId)).RelatedRecordId
            );
            
            leadsToUpdate.add(ld);
        }
        
        TriggerHandler.bypass(LeadTriggerHandler.class);
        Database.update(leadsToUpdate, false);
        TriggerHandler.clearBypass(LeadTriggerHandler.class);
    }

    public void cancelParentWorkOrder(List<ServiceAppointment> appts, Map<Id, ServiceAppointment> oldAppts){

        List<WorkOrder> wos = new List<WorkOrder>();

        for(ServiceAppointment appt : appts){
            if(appt.Status == 'Canceled' && oldAppts.get(appt.Id).Status != 'Canceled' && appt.ParentRecordId != null && appt.ParentRecordId.getsObjectType().getDescribe().getName() == 'WorkOrder'){
                WorkOrder wo = new WorkOrder(
                    Id = appt.ParentRecordId,
                    Status = 'Canceled'
                );

                wos.add(wo);
            }
        }

        TriggerHandler.bypass(WorkOrderTriggerHandler.class);
        Database.update(wos, false);
        TriggerHandler.clearBypass(WorkOrderTriggerHandler.class);
    }
}