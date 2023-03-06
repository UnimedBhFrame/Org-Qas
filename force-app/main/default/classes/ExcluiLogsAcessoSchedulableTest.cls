@isTest
public without sharing class ExcluiLogsAcessoSchedulableTest {
    
    @isTest
    public static void testaSchedulable() {
            
        String cronExpr = '0 0 0 10 5 ? 2029';
        
        Test.startTest();	
        String jobId = System.schedule('myJobTestJobName', cronExpr, new ExcluiLogsAcessoSchedulable());
        Test.stopTest();
    }

}