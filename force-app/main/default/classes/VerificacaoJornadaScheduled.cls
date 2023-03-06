global class VerificacaoJornadaScheduled implements Schedulable {
    
    public VerificacaoJornadaScheduled(){

    }
    
    public static void startJob(String name) {

        if(String.isBlank(name)){
            name = 'Verificação Jornada de Trabalho - ' + Datetime.now().format('YYYYMMDDHHmmSS');
        }

        System.schedule(
            name, 
            '0 0 19 * * ?', 
            new VerificacaoJornadaScheduled()
        );
    }
        
    
    global void execute(SchedulableContext SC) {
        verificaJornada();
    }

    public static void verificaJornada() {
        Database.executeBatch(new VerificacaoJornadaBatch(), 100);
    }
}