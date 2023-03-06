public with sharing class ServiceResourceDAO {
    public static ServiceResource getById(String id) {
        ServiceResource lst = [SELECT Id, RelatedRecord.CANAL__c, Name FROM ServiceResource WHERE id =: id];

        return lst;
    }

    public static List<ServiceResource> getByUserId(String id) {
        List <ServiceResource> lst = [SELECT RelatedRecordId, Name FROM ServiceResource WHERE RelatedRecordId =: id];

        return lst;
    }
}