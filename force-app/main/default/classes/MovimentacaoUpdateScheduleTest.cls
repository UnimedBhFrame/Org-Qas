@isTest
public class MovimentacaoUpdateScheduleTest {
    @isTest
    static void testMovimentacaoUpdateSchedule() {
        Test.startTest();
        String jobId = System.schedule(
            'Vincular Lead e Movimentação',
            '0 0 5 * * ? *',
            new MovimentacaoUpdateSchedule()
        );
        Test.stopTest();
    }
}