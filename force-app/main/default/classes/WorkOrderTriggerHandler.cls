public without sharing class WorkOrderTriggerHandler extends TriggerHandler {
    

    //TO DO Fazer classe de teste

    public override void afterUpdate() {
        WorkOrderDomain.getInstance().sendEmailServiceReportFromWOLI((List<WorkOrder>) Trigger.new, (Map<Id, WorkOrder>) Trigger.oldMap);
        WorkOrderDomain.getInstance().createServiceReportFromWOLI((List<WorkOrder>) Trigger.new, (Map<Id, WorkOrder>) Trigger.oldMap);
    }
}