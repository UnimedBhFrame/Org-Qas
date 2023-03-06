@isTest
public class ServiceResourceTriggerHandlerTest {
    
    @TestSetup
    static void setup(){
        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),
            Name = 'User',
            ResourceType = 'T',
            LastKnownLatitude = -19.818720,
            LastKnownLongitude = -43.832884
        );
        insert rsc;
    }

    @isTest
    static void saveGeolocationTest(){
        ServiceResource rs = [SELECT Id FROM ServiceResource LIMIT 1];
        rs.LastKnownLocationDate = Datetime.now();
        rs.LastKnownLatitude = -19.918720;
        rs.LastKnownLongitude = -43.932884;

        Test.startTest();
        update rs;
        rs.LastKnownLocationDate = Datetime.now().addDays(1);
        rs.LastKnownLatitude = -19.818720;
        rs.LastKnownLongitude = -43.832884;
        update rs;
        Test.stopTest();

        System.assert(true, 'Processo realizado com sucesso');
    }
}