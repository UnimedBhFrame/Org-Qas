global class ScheduleLastLocation implements Schedulable{

    public ScheduleLastLocation(){

    }
    
    public static void startJob(String name) {

        if(String.isBlank(name)){
            name = 'Verificação Ultima Localização - ' + Datetime.now().format('YYYYMMDDHHmmSS');
        }

        System.schedule(
            name, 
            '0 30 * * * ?', 
            new ScheduleLastLocation()
        );
    }
    
    global void execute(SchedulableContext SC) {
        checkSchedule();
    }
    
    public static void checkSchedule() {
        Database.executeBatch(new ServiceResourceLastLocation(), 100);
    }
}