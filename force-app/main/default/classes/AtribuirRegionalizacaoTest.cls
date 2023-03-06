@isTest
public class AtribuirRegionalizacaoTest {
    

    @TestSetup
    static void setup(){
        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),
            Name = 'User',
            ResourceType = 'T'
        );
        insert rsc;

        DistribuicaoVisita__c dist = new DistribuicaoVisita__c(
            Tipo__c = 'Call center',
            NumeroVidas__c = 1,
            Codigo__c = 'PME1',
            Name = 'PME1'
        );
        insert dist;

        MembroDistribuicaoVisita__c membro1 = new MembroDistribuicaoVisita__c();
        membro1.ServiceResource__c = rsc.Id;
        membro1.DistribuicaoVisita__c = dist.Id;
        insert membro1;

        OperatingHours oh = new OperatingHours(
            Name = 'MyOpHours'
        );
        insert oh;

        createTimeSlots(oh.Id);

        ServiceTerritory terr = new ServiceTerritory(
            Name = 'Centro',
            OperatingHoursId = oh.Id,
            IsActive = true
        );
        insert terr;

        RegionalizacaoDistribuicaoVisita__c rdv = new RegionalizacaoDistribuicaoVisita__c(
            ServiceTerritory__c = terr.Id,
            DistribuicaoVisita__c = dist.Id
        );
        insert rdv;
        
    }

    static void createTimeSlots(Id OperatingHoursId){

        List<String> days = new List<String>{'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'};

        List<TimeSlot> tss = new List<TimeSlot>();

        for(String day : days){
            TimeSlot ts = new TimeSlot(
                OperatingHoursId = OperatingHoursId,
                DayOfWeek = day,
                StartTime = Time.newInstance(0, 0, 0, 0),
                EndTime = Time.newInstance(23, 59, 59, 0)   
            );
            
            tss.add(ts);
        }
        
        insert tss;
    }

    @isTest
    static void atribuirTest(){

        DistribuicaoVisita__c dv = [SELECT Id FROM DistribuicaoVisita__c LIMIT 1];

        Test.startTest();
        AtribuirRegionalizacao.atribuir(new Set<Id>{dv.Id});
        Test.stopTest();
    }
}