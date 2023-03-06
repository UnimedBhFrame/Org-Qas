public without sharing class MembroDistribuicaoVisitaTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert() {
        MembroDistribuicaoVisitaDomain.getInstance().checkResourceInGroup((List<MembroDistribuicaoVisita__c>) Trigger.new);
    }

    public override void beforeUpdate() {
        MembroDistribuicaoVisitaDomain.getInstance().checkResourceInGroup((List<MembroDistribuicaoVisita__c>) Trigger.new);
    }

    public override void afterInsert() {
        MembroDistribuicaoVisitaDomain.getInstance().atribuirRegionalizacao((List<MembroDistribuicaoVisita__c>) Trigger.new);
    }

    public override void afterUpdate(){
        MembroDistribuicaoVisitaDomain.getInstance().atribuirRegionalizacao((List<MembroDistribuicaoVisita__c>) Trigger.new);
    }

}