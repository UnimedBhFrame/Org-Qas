public without sharing class ServiceResourceTriggerHandler extends TriggerHandler {
    
    //TO DO Fazer classe de teste

    public override void beforeInsert() {
        ServiceResourceDomain.getInstance().adjustOwnerServiceResource((List<ServiceResource>) Trigger.new);
    }

    public override void beforeUpdate() {
        ServiceResourceDomain.getInstance().adjustOwnerServiceResource((List<ServiceResource>) Trigger.new);
    }

    public override void afterUpdate() {
        ServiceResourceDomain.getInstance().saveGeolocation((List<ServiceResource>) Trigger.new, (Map<Id, ServiceResource>) Trigger.oldMap);
        ServiceResourceDomain.getInstance().registerDistance((List<ServiceResource>) Trigger.new, (Map<Id, ServiceResource>) Trigger.oldMap);
    }
}