@isTest
public  class SurveyInvitationTriggerHandlerTest {
    
    // @TestSetup
    // static void setup(){
    //     Lead ld = new Lead(
    //         LastName = 'MyLead',
    //         MobilePhone = '31988887777',
    //         Status = 'Captação',
    //         Email = 'mylead@email.com.br.test',
    //         //Email__c = 'mylead@email.com.br.test',
    //         NumeroVidas__c = 31
    //     );
    //     insert ld;
    // }

    @isTest(SeeAllData=true)
    static void insertTest(){
        Lead lead = [SELECT Email, OwnerId, Name from Lead LIMIT 1];
        Survey sv = [SELECT Id FROM Survey WHERE ActiveVersionId != null LIMIT 1];
        Network community = [SELECT Id FROM Network LIMIT 1];

        SurveyInvitation sInv = new SurveyInvitation();
        sInv.ParticipantId = lead.Id;
        sInv.OptionsCollectAnonymousResponse = false;
        sInv.SurveyId = sv.Id;
        sInv.Name = lead.Name;             
        sInv.CommunityId = community.Id;
        sInv.IsDefault = false;
        sInv.OptionsAllowGuestUserResponse = true;
        sInv.OptionsAllowParticipantAccessTheirResponse = false;

       
        Test.startTest();
        insert sInv;
        Test.stopTest();
    }
}