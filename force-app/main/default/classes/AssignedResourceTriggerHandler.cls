public without sharing class AssignedResourceTriggerHandler extends TriggerHandler {

    public override void afterInsert() {
        AssigedResourceDomain.getInstance().followWorkOrder((List<AssignedResource>) Trigger.new);
        AssigedResourceDomain.getInstance().updateServiceResourceInServiceAppoitment((List<AssignedResource>) Trigger.new);
        AssigedResourceDomain.getInstance().setOwnerAsUserServiceResource((List<AssignedResource>) Trigger.new);
    }
}