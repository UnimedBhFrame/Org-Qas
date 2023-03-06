public without sharing class RegionalizacaoDistribuicaoVisitaDomain {
    
    private static RegionalizacaoDistribuicaoVisitaDomain instance = null;
    
    public static RegionalizacaoDistribuicaoVisitaDomain getInstance() {
        if (instance == null) {
            instance = new RegionalizacaoDistribuicaoVisitaDomain();
        }
        
        return instance;
    }

    public void atribuir(List<RegionalizacaoDistribuicaoVisita__c> rdvs){
        Set<Id> dvIds = new Set<Id>();

        for(RegionalizacaoDistribuicaoVisita__c rdv : rdvs){
            dvIds.add(rdv.DistribuicaoVisita__c);
        }

        AtribuirRegionalizacao.atribuir(dvIds);
    }

}