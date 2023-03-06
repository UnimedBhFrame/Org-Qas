public without sharing class AtribuirRegionalizacao {
    
    @future
    static public void atribuir(Set<Id> dvIds){

        List<RegionalizacaoDistribuicaoVisita__c> rdvs = [SELECT Id, DistribuicaoVisita__c, ServiceTerritory__c FROM RegionalizacaoDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN :dvIds];
        List<MembroDistribuicaoVisita__c> mdvs = [SELECT Id, DistribuicaoVisita__c, ServiceResource__c FROM MembroDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN : dvIds];

        Map<Id, Set<Id>> mapDvSt = new Map<Id, Set<Id>>();
        for(RegionalizacaoDistribuicaoVisita__c rdv : rdvs){
            if(!mapDvSt.containsKey(rdv.DistribuicaoVisita__c)){
                mapDvSt.put(rdv.DistribuicaoVisita__c, new Set<Id>());
            }

            mapDvSt.get(rdv.DistribuicaoVisita__c).add(rdv.ServiceTerritory__c);
        }

        Map<Id, Boolean> mapSrP = new Map<Id, Boolean>();
        Map<Id, Set<Id>> mapDvSr = new Map<Id, Set<Id>>();
        for(MembroDistribuicaoVisita__c mdv : mdvs){
            if(!mapDvSr.containsKey(mdv.DistribuicaoVisita__c)){
                mapDvSr.put(mdv.DistribuicaoVisita__c, new Set<Id>());
            }

            mapDvSr.get(mdv.DistribuicaoVisita__c).add(mdv.ServiceResource__c);
            mapSrP.put(mdv.ServiceResource__c, false);
        }

        List<ServiceTerritoryMember> stms = [SELECT Id, ServiceResourceId FROM ServiceTerritoryMember WHERE ServiceResourceId IN :mapSrP.keySet() AND TerritoryType = 'P'];

        for(ServiceTerritoryMember stm : stms){
            mapSrP.put(stm.ServiceResourceId, true);
        }


        List<ServiceTerritoryMember> mterrs = new List<ServiceTerritoryMember>();
        for(Id dvId : mapDvSt.keySet()){
            for(Id stId : mapDvSt.get(dvId)){
                if(mapDvSr.containsKey(dvId)){
                    for(Id srId : mapDvSr.get(dvId)){

                        ServiceTerritoryMember mterr = new ServiceTerritoryMember(
                            ServiceResourceId = srId,
                            ServiceTerritoryId = stId,
                            EffectiveStartDate = System.now(),
                            TerritoryType = mapSrP.get(srId) ? 'S' : 'P'
                        );

                        mterrs.add(mterr);

                        mapSrP.put(srId, true);
                    }
                }
            }
        }

        List<Database.SaveResult> results = Database.insert(mterrs, false);
        System.debug(results);
    }
}