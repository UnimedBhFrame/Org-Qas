trigger RegionalizacaoDistribuicaoVisitaTrigger on RegionalizacaoDistribuicaoVisita__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new RegionalizacaoDistVisitaTriggerHandler().run();
}