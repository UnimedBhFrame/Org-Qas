public without sharing class ServiceResourceDomain {
    
    private static ServiceResourceDomain instance = null;
    
    public static ServiceResourceDomain getInstance() {
        if (instance == null) {
            instance = new ServiceResourceDomain();
        }
        
        return instance;
    } 

    public void adjustOwnerServiceResource(List<ServiceResource> srs){

        for(ServiceResource sr : srs){
            if(sr.RelatedRecordId != null){
                sr.OwnerId = sr.RelatedRecordId;
            }
        }
    }

    public void saveGeolocation(List<ServiceResource> rsec, Map<Id, ServiceResource> oldRs){

        List<RastreamentoRecursoServico__b> rastreamentos = new List<RastreamentoRecursoServico__b>();
        for(ServiceResource sr : rsec){
            if(sr.LastKnownLocationDate != oldRs.get(sr.Id).LastKnownLocationDate){
                RastreamentoRecursoServico__b rrs = new RastreamentoRecursoServico__b();
                rrs.DataLocalizacao__c = sr.LastKnownLocationDate;
                rrs.Latitude__c = sr.LastKnownLatitude;
                rrs.Longitude__c = sr.LastKnownLongitude;
                rrs.ServiceResource__c = sr.Id;

                rastreamentos.add(rrs);
            }
        }

        saveRastreamento(JSON.serialize(rastreamentos));
    }

    @future
    public static void saveRastreamento(String jsonRast){
        List<RastreamentoRecursoServico__b> rastreamentos = (List<RastreamentoRecursoServico__b>) JSON.deserialize(jsonRast, List<RastreamentoRecursoServico__b>.class);
        if(!Test.isRunningTest()){
            database.insertImmediate(rastreamentos);
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void registerDistance(List<ServiceResource> serviceResourceList, Map<Id,ServiceResource> oldMapList){
        //Lista de disâncias diárias à serem atualizadas
        List<DailyDistance__c> dailyDistanceList = new List<DailyDistance__c>();
        
        //Precorre todos os registros de regustros em atualização
        for(ServiceResource serviceResourceRecord : serviceResourceList){

            //Se possuem dados de Latitude e Longitude
            if(serviceResourceRecord.LastKnownLatitude != null && 
                serviceResourceRecord.LastKnownLongitude != null &&
                oldMapList.get(serviceResourceRecord.Id).LastKnownLatitude != null && 
                oldMapList.get(serviceResourceRecord.Id).LastKnownLongitude != null){
                
                //Se os dados de posicionamento mudaram
                if(
                    serviceResourceRecord.LastKnownLatitude != oldMapList.get(serviceResourceRecord.Id).LastKnownLatitude ||
                    serviceResourceRecord.LastKnownLongitude != oldMapList.get(serviceResourceRecord.Id).LastKnownLongitude
                ){

                    //Adiciona à lista um registro de distância para cria/atualizar
                    dailyDistanceList.add(
                        calculatePositionUpdate(
                            serviceResourceRecord.Id, 
                            serviceResourceRecord.LastKnownLatitude,
                            serviceResourceRecord.LastKnownLongitude
                        ));
                }
            }
        }

        if(!dailyDistanceList.isEmpty()){
            saveDistancias(JSON.serialize(dailyDistanceList));
        }
    }
    
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public DailyDistance__c calculatePositionUpdate(Id referenceId, Decimal latitude, Decimal longitude) {
        
        //Busca algum registro diário para a referência na data corrente
        DailyDistance__c dailyDistanceRecord = null;
        List<DailyDistance__c> records = [SELECT id, Distance__c, Latitude__c, Longitude__c FROM DailyDistance__c WHERE ServiceResourceId__c = :referenceId AND Date__c = :Date.today()];
        if(records != null && !records.IsEmpty()){
            dailyDistanceRecord = records[0];
        }

        //Se não existe um registro um diário
        if(dailyDistanceRecord == null){
            
            //Criar o registro com os prmeiros valores do dia
            dailyDistanceRecord = new DailyDistance__c();
            dailyDistanceRecord.ServiceResourceId__c = referenceId;
            dailyDistanceRecord.Date__c = Date.today();
            dailyDistanceRecord.Distance__c = 0;

        //Se não existe um registro diário
        } else {

            //calcular a distância e preencher o novo valor
            dailyDistanceRecord.Distance__c += calculateDistance(
                Decimal.valueOf(dailyDistanceRecord.Latitude__c),
                Decimal.valueOf(dailyDistanceRecord.Longitude__c),
                latitude,
                longitude
            );
        }

        System.debug('latitude');
        System.debug(latitude);
        System.debug('longitude');
        System.debug(longitude);
        
        //Atualiza os valores de última posição no registro diário
        dailyDistanceRecord.Latitude__c = String.valueOf(latitude);
        dailyDistanceRecord.Longitude__c = String.valueOf(longitude);
        System.debug('dailyDistanceRecord.Latitude__c ');
        System.debug(dailyDistanceRecord.Latitude__c );
        System.debug('dailyDistanceRecord.Longitude__c ');
        System.debug(dailyDistanceRecord.Longitude__c );

        //Cria ou atualiza o registro diário
        return dailyDistanceRecord;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    @future
    public static void saveDistancias(String jsonRast){
        List<DailyDistance__c> rastreamentos = (List<DailyDistance__c>) JSON.deserialize(jsonRast, List<DailyDistance__c>.class);
        if(!Test.isRunningTest()){
            database.upsert(rastreamentos);
        }
    }

    //Realiza o cálculo de distância em quilômetros entre dois pontos
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static Decimal calculateDistance(
        Decimal oldLatitude, 
        Decimal oldLongitude, 
        Decimal newLatitude, 
        Decimal newLongitude){

        //Geração do registro de localização
        Location oldLocation = Location.newInstance(oldLatitude,oldLongitude);
        Location newLocation = Location.newInstance(newLatitude,newLongitude);

        //Realiza o cálculo de distância entre as duas posições
        Decimal distance = Location.getDistance(oldLocation, newLocation, 'km');

        //Retorna ovalor da distância entre os dois ponteos
        return distance;
    }
}