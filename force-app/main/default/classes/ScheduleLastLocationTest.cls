@isTest
public class ScheduleLastLocationTest {
    
    public static String CRON_EXP = '0 30 * * * ?';
    
	@isTest(SeeAllData=true)
    static void testScheduleLastLocation(){
        String uniqueUserName =
          'Administrador' +
          DateTime.now().getTime() +
          '@testorg.com';
        Profile p = [
          SELECT Id
          FROM Profile LIMIT 1
        ];
        User us = new User(
            Alias = 'standt',
            Email = 'administrador@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'pt_BR',
            LocaleSidKey = 'pt_BR',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            UserName = uniqueUserName
        );
        insert us;
        
        
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Jorge';
        sr.RelatedRecordId = us.Id;
        sr.ResourceType = 'T';
        
        insert sr;
        
        sr.LastKnownLocationDate = DateTime.now().addMinutes(-35);
        update sr;
       
        Test.startTest();

        String jobId = System.schedule(
          'ScheduledApexTest',
          CRON_EXP,
          new ScheduleLastLocation()
        );
        ScheduleLastLocation.startJob(null);
        Test.stopTest();
        
    }

}