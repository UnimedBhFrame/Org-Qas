public without sharing class WorkOrderDomain {
    
    private static WorkOrderDomain instance = null;
    
    public static WorkOrderDomain getInstance() {
        if (instance == null) {
            instance = new WorkOrderDomain();
        }
        
        return instance;
    }

    public void sendEmailServiceReportFromWOLI(List<WorkOrder> wos, Map<Id, WorkOrder> oldWos){
        List<WorkOrder> woToSend = new List<WorkOrder>();

        Set<Id> leadIds = new Set<Id>();
        for(WorkOrder wo : wos){
            if(wo.Lead__c != null){
                leadIds.add(wo.Lead__c);
            }
        }

        Map<Id, Lead> mapLead = new Map<Id, Lead>([SELECT Id, Email, Street, Numero__c, Bairro__c, City, State, Country, PostalCode, NumeroVidas__c FROM Lead WHERE Id IN :leadIds]);

        for(WorkOrder wo : wos){
            if(wo.Status == 'Completed' && oldWos.get(wo.Id).Status != 'Completed' && 
                wo.Lead__c != null && mapLead.keySet().contains(wo.Lead__c)){
                woToSend.add(wo);
            }
        }

        WorkOrderService.getInstance().sendEmailServiceReportFromWOLI(woToSend, mapLead);
    }

    public void createServiceReportFromWOLI(List<WorkOrder> wos, Map<Id, WorkOrder> oldWos){
        List<WorkOrder> woToSend = new List<WorkOrder>();

        Set<Id> leadIds = new Set<Id>();
        for(WorkOrder wo : wos){
            if(wo.Lead__c != null){
                leadIds.add(wo.Lead__c);
            }
        }

        Map<Id, Lead> mapLead = new Map<Id, Lead>([SELECT Id, Email, Street, Numero__c, Bairro__c, City, State, Country, PostalCode, NumeroVidas__c FROM Lead WHERE Id IN :leadIds]);

        for(WorkOrder wo : wos){
            if(wo.Status == 'Completed' && oldWos.get(wo.Id).Status != 'Completed' && 
                wo.Lead__c != null && mapLead.keySet().contains(wo.Lead__c)){
                woToSend.add(wo);
            }
        }

        WorkOrderService.getInstance().createServiceReportFromWOLI(woToSend);
    }
}