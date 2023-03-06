@isTest
public class VerificacaoJornadaScheduledTest {
    

    @isTest
    static void startJobTest(){
        Test.startTest();
        VerificacaoJornadaScheduled.startJob(null);
        Test.stopTest();
    }

    @isTest
    static void executeTest(){
        Test.startTest();
        (new VerificacaoJornadaScheduled()).execute(null);
        Test.stopTest();
    }
}