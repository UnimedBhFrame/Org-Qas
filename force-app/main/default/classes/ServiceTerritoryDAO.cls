public with sharing class ServiceTerritoryDAO {
    public static List<ServiceTerritory> getByIsActive() {
        List <ServiceTerritory> lst = [SELECT Id, Risco__c, LocalDificilAcesso__c, Name, ParentTerritoryId, ParentTerritory.Name FROM ServiceTerritory WHERE IsActive = true];

        return lst;
    }
}