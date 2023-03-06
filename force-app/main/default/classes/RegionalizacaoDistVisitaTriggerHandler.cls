public with sharing class RegionalizacaoDistVisitaTriggerHandler extends TriggerHandler {
      
    public override void afterInsert(){
        RegionalizacaoDistribuicaoVisitaDomain.getInstance().atribuir((List<RegionalizacaoDistribuicaoVisita__c>) Trigger.new);
    }
}