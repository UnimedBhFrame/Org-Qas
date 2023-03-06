public without sharing class ServiceReportTriggerHandler extends TriggerHandler {
    
    //TO DO Fazer classe de teste
    public override void afterInsert() {
        ServiceReportDomain.getInstance().finishWorkOderLineItem((List<ServiceReport>) Trigger.new);
    }
}