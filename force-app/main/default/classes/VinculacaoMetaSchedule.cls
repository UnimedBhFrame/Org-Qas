global class VinculacaoMetaSchedule implements Schedulable {

    public static void startJob() {

        String name = 'Vinculação de Lead, Oportunidade e Movimentação com Meta';
        if(Test.isRunningTest()){
            name += ' - ' + Datetime.now().format('YYYYMMDDHHmmSS');
        }
        
        System.schedule(
            name, 
            '0 0 3 * * ?', 
            new VinculacaoMetaSchedule()
        );
    }

    global void execute(SchedulableContext context) {
        Database.executeBatch(new VinculacaoLeadMetaBatch(), 200);
        Database.executeBatch(new VinculacaoOpportunityMetaBatch(), 200);
        Database.executeBatch(new VinculacaoMovimentacaoMetaBatch(), 200);
    }
}