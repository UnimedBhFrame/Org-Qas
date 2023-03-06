public without sharing class SearchAddressController {
    @AuraEnabled
    public static void updateLead(Lead ld){
        try {
            update ld;
        } catch (Exception e) {
           /*throw e;*/
           throw new AuraHandledException(e.getMessage()); 
        }
    }
}