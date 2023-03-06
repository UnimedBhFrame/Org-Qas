@isTest
public class VerificacaoJornadaBatchTest {
    
    @testSetup
    static void setup(){

        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),
            Name = 'User',
            ResourceType = 'T'
        );
        insert rsc;

        TimeSheet ts = new TimeSheet(
            ServiceResourceId = rsc.Id,
            StartDate = System.today(),
            EndDate = System.today()
        );
        insert ts;

        TimeSheetEntry tse = new TimeSheetEntry(
            StartTime = System.now(),
            TimeSheetId = ts.Id
        );
        insert tse;
    }

    @isTest
    static void executeTest(){

        Test.startTest();
        Database.executeBatch(new VerificacaoJornadaBatch(), 100);
        Test.stopTest();
    }
}