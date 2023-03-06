@isTest (SeeAllData=true)
public class SearchAddressControllerTest {

    @AuraEnabled 
    
    @isTest public static void updateLeadTest(){
        Lead[] ld = [Select Id, Name from Lead LIMIT 1];
        SearchAddressController.updateLead(ld[0]);
    }
    
    @isTest public static void updateLeadFailTest(){
        Lead ld = new Lead();
        ld.LastName = 'Lorem Ipsum';
        try{
            SearchAddressController.updateLead(ld);
        } catch (Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
    }
}