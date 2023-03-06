public without sharing class MembroDistribuicaoVisitaDomain {

    private static MembroDistribuicaoVisitaDomain instance = null;
    
    public static MembroDistribuicaoVisitaDomain getInstance() {
        if (instance == null) {
            instance = new MembroDistribuicaoVisitaDomain();
        }
        
        return instance;
    }

    public void checkResourceInGroup(List<MembroDistribuicaoVisita__c> membros){

        Map<Id, MembroDistribuicaoVisita__c> mapMembro = new Map<Id, MembroDistribuicaoVisita__c>();

        Map<Id, Map<Id, Integer>> distribuicaoResource = new Map<Id, Map<Id, Integer>>();
        
        for(MembroDistribuicaoVisita__c membro : membros){
            if(membro.ServiceResource__c != null && membro.DistribuicaoVisita__c != null){
                if(!distribuicaoResource.containsKey(membro.DistribuicaoVisita__c)){
                    distribuicaoResource.put(membro.DistribuicaoVisita__c, new Map<Id, Integer>());
                }

                distribuicaoResource.get(membro.DistribuicaoVisita__c).put(membro.ServiceResource__c, 0);


                mapMembro.put(membro.ServiceResource__c, membro);
            }
        }

        for(MembroDistribuicaoVisita__c membro : [SELECT Id, DistribuicaoVisita__c, ServiceResource__c FROM MembroDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN :distribuicaoResource.keySet()]){
            if(distribuicaoResource.get(membro.DistribuicaoVisita__c).containsKey(membro.ServiceResource__c)){
                distribuicaoResource.get(membro.DistribuicaoVisita__c).put(membro.ServiceResource__c, distribuicaoResource.get(membro.DistribuicaoVisita__c).get(membro.ServiceResource__c) + 1);
            }
        }
        
        for(Id key : distribuicaoResource.keySet()){
            for(Id resource : distribuicaoResource.get(key).keySet()){
                if(distribuicaoResource.get(key).get(resource) > 0){
                    mapMembro.get(resource).ServiceResource__c.addError('A Pessoa já existe como membro nessa Distribuição de Visita.');
                }
            }
        }
    }

    public void atribuirRegionalizacao(List<MembroDistribuicaoVisita__c> membros){

        Set<Id> dvIds = new Set<Id>();

        for(MembroDistribuicaoVisita__c membro : membros){
            dvIds.add(membro.DistribuicaoVisita__c);
        }

        AtribuirRegionalizacao.atribuir(dvIds);

    }
}