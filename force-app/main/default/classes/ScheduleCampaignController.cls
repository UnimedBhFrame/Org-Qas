public without sharing class ScheduleCampaignController {
    public static String historicoDecisao = '';
    public String message{get; set;}
    public Boolean response {get; set;}
    public List<ServiceResource> resourceList {get; set;}
    public static Boolean agendamentoSabado;
    public static List<String> blackListServiceResource;

    private static List<String> availabelCities = new List<String>{
    	'baldim',
        'barão de cocais',
        'belo horizonte',
        'betim',
        'brumadinho',
        'caeté',
        'capim branco',
        'catas altas',
        'conceição do mato dentro',
        'confins',
        'contagem',
        'esmeraldas',
        'ibirité',
        'ibirite',
        'igarapé',
        'jaboticatubas',
        'juatuba',
        'lagoa santa',
        'mário campos',
        'matozinhos',
        'nova lima',
        'nova união',
        'pedro leopoldo',
        'raposos',
        'ribeirão das neves',
        'ribeirao das neves',
        'rio acima',
        'sabará',
        'sabara',
        'santa bárbara',
        'santa luzia',
        'santana do riacho',
        'são joaquim de bicas',
        'são josé da lapa',
        'sarzedo',
        'taquaraçu de minas',
        'vespasiano',
        'salvador',
        'são paulo',
        'juiz de fora',
        'rio de janeiro',
        'itaúna'
    };

    public static Id checkLead(Id leadId){
        if(leadId.getsObjectType().getDescribe().getName() == 'Account'){
            leadId = [SELECT Id, ConvertedAccountId FROM Lead WHERE ConvertedAccountId = :leadId LIMIT 1].Id;
        }

        return leadId;
    }
	
    @AuraEnabled(cacheable=true)
    public static Map <String, Object> getTerritoryInfo(Id leadId, Boolean agendamentoSab, List<String> blackList){
        checkFormasDistribuicao();
        leadId = checkLead(leadId);
        agendamentoSabado = agendamentoSab;
        blackListServiceResource = blackList != null ? blackList : new List<String>();

        Map <String, Object> response = new Map <String, Object>();

        Boolean hasPermission = true;
        
        Lead ld = [Select Id, Bairro__c, City, NumeroVidas__c, Porte__c, TipoAtendimento__c from Lead Where Id =: leadId];

        if(ld.City != null){

            response.put('leadAddress', true);
            if(availabelCities.contains(ld.City.toLowerCase())){
                response.put('availabelCities', true);
                List<ServiceAppointment> lsa = [SELECT Id, Status, Lead__c, EarliestStartTime, SchedStartTime, ServiceResource__c, ServiceTerritory__c, AtendimentoCallCenter__c from ServiceAppointment Where Lead__c =: leadId AND (Status ='Scheduled' OR Status ='In Progress')];
            
                if(lsa.isEmpty()){
                    
                    response.put('hasScheduled', false);
                    
                    List <ServiceTerritory> lst = getServiceTerritoryList(ld);

                    if(lst.isEmpty()){
                        response.put('addressExist', false);
                        response.put('territoryRisk', false);
                    }else{
                
                        Boolean ccc = true;
                        for (ServiceTerritory ls : lst){
                            System.debug('city ls - ' + ls.Name);
                           // System.debug('city ld'+ld.City);
                            
                                response.put('addressExist', true);
                                
                                    if(ls.Risco__c  && ls.LocalDificilAcesso__c){
                                        response.put('bothDificult', true);
                                        ccc = false;
                                        break;
                                    } else if(ls.LocalDificilAcesso__c){
                                        response.put('dificultTerrain', true);
                                        ccc = false;
                                        break;
                                    } else if(ls.Risco__c){
                                        response.put('territoryRisk', true);
                                        ccc = false;
                                        break;
                                    }                    
                                 
                        }
                                    if(ccc){
                                        Map <String, Object> resource = getServiceResource(ld, lst);
                                        response.put('territoryRisk', false);
                                        response.put('serviceTerritoryId', lst[0].Id);
                                        if(Boolean.valueOf(resource.get('success'))){
                                            response.put('success', resource.get('success'));
                                            response.put('resourceId', resource.get('resource'));
                                        } else {
                                            response.put('success', resource.get('success'));
                                            response.put('message', resource.get('message'));
                                        }
                                }
                                   
                                
                                
                            
                        
                    }
                } else {
                    String resId;
                    if(lsa[0].ServiceResource__c != null){
                        resId = lsa[0].ServiceResource__c;
                    } 
                    //else if(lsa[0].ServiceResourceId__c != null){
                        //resId = lsa[0].ServiceResourceId__c;
                    //}
                    ServiceResource sr = [SELECT Id, Name, RelatedRecord.CANAL__c from ServiceResource Where Id =: resId];
                    response.put('hasScheduled', true);
                    response.put('resourceName', sr.Name);
                    response.put('visitDate', lsa[0].SchedStartTime);
                    response.put('resourceId', sr.Id);
                    response.put('resourceChannel', sr.RelatedRecord.CANAL__c);
                    response.put('serviceTerritoryId', lsa[0].ServiceTerritory__c);
                    response.put('AtendimentoCallCenter', lsa[0].AtendimentoCallCenter__c);
                    response.put('serviceAppointmentId', lsa[0].Id);
                    if(lsa[0].Status == 'In Progress'){
                        response.put('inProgress', true);
                    } else {
                        response.put('inProgress', false);
                    }
                }
            } else {
                response.put('availabelCities', false);
            }

            
        } else {
            response.put('leadAddress', false);
        }
        
        
        

        response.put('hasPermission', hasPermission);
        response.put('historicoDecisao', historicoDecisao);
        
        return response;
    }

    public static Boolean getPermission(){
        Boolean hasCustomPermission = FeatureManagement.checkPermission('Predestinado');
        
        return hasCustomPermission;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean getPermissionAgendamentoSabado(){
        Boolean hasCustomPermission = FeatureManagement.checkPermission('AgendamentoSabado');
        
        return hasCustomPermission;
    }

    //Function to get Service Resource
    public static Map<String, Object> getServiceResource(Lead ld, List<ServiceTerritory> lst){

        Map<String, Object> response = new Map<String, Object>();

        //Get the 'Predestinado' permission.
        Boolean isPredestined = getPermission();
        if(getPermission()){
            List<ServiceResource> sr = [SELECT Id, Name, RelatedRecord.CANAL__c from ServiceResource Where RelatedRecordId =: UserInfo.getUserId()];
            
            if(!sr.isEmpty()){
                System.debug(sr[0].Name);
                response.put('success', true);
                response.put('resource', sr[0]);
                return response;
            }
        }

        // Get Resource List of Distribuição de visita from list of Service Territory
        ScheduleCampaignController resourceResponse =  getServiceResourcesList(ld, lst);

        if(resourceResponse.response){
            //get the available resource with less scheduled visits
            ServiceResource sr = getAvailableResource(resourceResponse.resourceList);
            response.put('success', true);
            response.put('resource', sr);
            return response;
        } else {
            response.put('success', false);
            response.put('message', resourceResponse.message);
            return response;
        }
    }

    //Function to get Service Resource List of the Service TerritoryList
    public static ScheduleCampaignController getServiceResourcesList(Lead ld, List<ServiceTerritory> lst){
        
        ScheduleCampaignController resResponse = new ScheduleCampaignController(); 

        //get the DistribuiçãoVisita
        List <DistribuicaoVisita__c> ldv = getDisctibuicaoVisita(ld, lst);
        if(ldv.isEmpty()){
            resResponse.response = false;
            resResponse.message = 'Nenhuma Distribuição de Visita obedece os parâmetros';
            return resResponse;
        }

        List<DistribuicaoVisita__c> ldv2 = new List<DistribuicaoVisita__c>();
        for(DistribuicaoVisita__c dv : ldv){
            if(!(dv.Tipo__c == 'Loja autorizada' && UserInfo.getProfileId() == System.Label.ProfileId_Promotor)){
                ldv2.add(dv);
            }
        }

        Set<Id> distribuicaoVisitaIds = new Set<Id>();
        for(RegionalizacaoDistribuicaoVisita__c rdv : [SELECT Id, DistribuicaoVisita__c FROM RegionalizacaoDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN :ldv2 AND ServiceTerritory__c IN :lst]){
            distribuicaoVisitaIds.add(rdv.DistribuicaoVisita__c);
        }
        historicoDecisao = historicoDecisao + '<br><br>getServiceResourcesList: ';
        historicoDecisao = historicoDecisao + '<br>distribuicaoVisitaIds: ';
        historicoDecisao = historicoDecisao + String.valueOf(distribuicaoVisitaIds);

        List<MembroDistribuicaoVisita__c> lmdv = new List<MembroDistribuicaoVisita__c>();
        Set<Id> serviceResourceIds = new Set<Id>();
        //get all available members of MembroDistribuicaoVisita__c
       // for (DistribuicaoVisita__c dv : ldv){
            for(MembroDistribuicaoVisita__c mdv : [SELECT Id, ServiceResource__c, Supervisor__c, ServiceResource__r.Name, ServiceResource__r.IsActive, DistribuicaoVisita__r.Name from MembroDistribuicaoVisita__c Where DistribuicaoVisita__c IN :distribuicaoVisitaIds]){
                if(!(mdv.Supervisor__c == true && UserInfo.getProfileId() == System.Label.ProfileId_Promotor) && !blackListServiceResource.contains(mdv.ServiceResource__c) && mdv.ServiceResource__r.IsActive == true){
                    lmdv.add(mdv);
                    serviceResourceIds.add(mdv.ServiceResource__c);
                }
            }            
       // }
        System.debug('Lista de Membros');
        for(MembroDistribuicaoVisita__c mdv : lmdv){
            System.debug(mdv.ServiceResource__r.Name + ' - ' + mdv.DistribuicaoVisita__r.Name);
        }

        historicoDecisao = historicoDecisao + '<br>serviceResourceIds: ';
        historicoDecisao = historicoDecisao + String.valueOf(serviceResourceIds);

        
        if(lmdv.isEmpty()){
            resResponse.response = false;
            resResponse.message = 'Nenhuma Distribuição de visita na Região do Lead. Entre em contato com o Administrador.';
            return resResponse;
        }

    
        //check if the MembroDistribuicaoVisita and ServiceTerritoryMember are the same resource an mount a list of service resources

       /* Set<Id> serviceResourcePredestined = new Set<Id>();
        for(ServiceTerritoryMember stm : [SELECT Id, ServiceTerritoryId, ServiceResourceId FROM ServiceTerritoryMember WHERE ServiceResourceId IN :serviceResourceIds AND ServiceTerritoryId IN :lst]){
            serviceResourcePredestined.add(stm.ServiceResourceId);
        }*/

        List<ServiceResource> lsr = [SELECT Id, RelatedRecordId, Name, RelatedRecord.CANAL__c FROM ServiceResource WHERE Id IN :serviceResourceIds];                      

        if(lsr.isEmpty()){
            resResponse.response = false;
            resResponse.message = 'Não tem nenhum consultor cadastrado em Distribuição de visita ou na região do endereço do lead';
            return resResponse;
        } else {
            resResponse.response = true;
            resResponse.resourceList = lsr;
            return resResponse;
        }
    }
    
    //resource with less scheduled visits
    public static ServiceResource getAvailableResource(List<ServiceResource> lsr){
        ServiceResource sr;
        if (lsr.size() == 1){
            sr = lsr[0];
        } else {
            //List<ServiceResourceChoose> lsrc = new List<ServiceResourceChoose>();
            //get the number of visits of each resource

            

            Map<Id, Integer> mapSRTotal = new Map<Id, Integer>();
            for(ServiceResource servResource : lsr){
                //if(!mapSRTotal.containsKey(appt.ServiceResource__c)){
                    mapSRTotal.put(servResource.Id, 0);
               // }
            }

            Date dateToday = Date.today();
            Datetime startedDate = Datetime.newInstance(dateToday.year(), dateToday.month(), dateToday.addDays(-1).day(), 0, 0, 0);
            Datetime endedDate = Datetime.newInstance(dateToday.year(), dateToday.month(), dateToday.day(), 23, 59, 59);

            Map<Id, ServiceAppointment> mapWOAppt = new Map<Id, ServiceAppointment>();
            for(ServiceAppointment appt : [SELECT Id, ParentRecordId, ServiceResource__c FROM ServiceAppointment WHERE ServiceResource__c IN :lsr /*AND Status = 'Scheduled'*/ AND ParentRecordType = 'WorkOrder' AND CreatedDate >= :startedDate AND CreatedDate <= :endedDate/*SchedStartTime >= :Date.today()*/]){
                mapWOAppt.put(appt.ParentRecordId, appt);
            }

            for(WorkOrder wo : [SELECT Id FROM WorkOrder WHERE Id IN : mapWOAppt.keySet() AND (CreatedBy.ProfileId = :System.Label.ProfileId_AtendenteCallCenter OR CreatedBy.ProfileId = :System.Label.ProfileId_Promotor)]){
                if(mapWOAppt.containsKey(wo.Id)){
                    ServiceAppointment appt = mapWOAppt.get(wo.Id);

                    Integer quant = mapSRTotal.get(appt.ServiceResource__c);
                    mapSRTotal.put(appt.ServiceResource__c, quant + 1);
                }
            }
            
            // for(Id srId : mapSRTotal.keySet()){
            //     ServiceResourceChoose src = new ServiceResourceChoose();
            //     src.resourceId = srId;
            //     src.quant = mapSRTotal.get(srId);
            //     lsrc.add(src);
            // }

            Id predestinado;
            Integer auxQuant;

            for(Id srId : mapSRTotal.keySet()){
                    
                if(auxQuant == null){
                    auxQuant = mapSRTotal.get(srId);
                    predestinado = srId;
                }else{
                    if(mapSRTotal.get(srId) < auxQuant){
                        auxQuant = mapSRTotal.get(srId);
                        predestinado = srId;
                    }
                }            
            }

            sr = [SELECT Id, Name, RelatedRecord.CANAL__c from ServiceResource Where Id =: predestinado];
        }
        System.debug('Predestinado' + ' = ' + sr.Name + ' ' + sr.Id);
        return sr; 
    }
    
    @AuraEnabled
    public static List<String> getNotAvailableDate (Id serviceResourceId, Date dt, Id serviceTerritoryId){
        
        System.debug('date serviceResourceId '+serviceResourceId);
        //List of not available dates
        List<String> ldt = new List<String>();
        DateTime tod = Datetime.now();
        DateTime compareInitDate = DateTime.newInstance(dt.year(), dt.month(), dt.day(), 0, 0, 0);

        system.debug('Init: ' + compareInitDate);
        
        DateTime compareEndDate = compareInitDate.addDays(1);
        system.debug('End: ' + compareEndDate);
        
        //List of Occupied ServiceAppointments
        List<ServiceAppointment> lsa = [SELECT Id, EarliestStartTime from ServiceAppointment Where ServiceResource__c =: serviceResourceId AND  EarliestStartTime >=: compareInitDate AND  EarliestStartTime <=: compareEndDate AND (Status ='Scheduled' OR Status ='In Progress' OR Status ='None')];
        System.debug('date lsa '+lsa);
        for(ServiceAppointment sa:lsa){
            ldt.add((string.valueof(sa.EarliestStartTime.time())).substring(0,5));
        }
        List<ResourceAbsence> lra = [SELECT Id, Start, End, StartDate__c, EndDate__c from ResourceAbsence Where ResourceId =:serviceResourceId  AND StartDate__c <=: dt AND EndDate__c >=: dt];
        System.debug('lra '+lra);
        if(!lra.isEmpty()){
            for(ResourceAbsence ra : lra){            
                Integer initTime = 8;
                
                if(ra.StartDate__c == dt){
                    initTime = Integer.valueOf((string.valueof(ra.Start.time())).substring(0,2));
                }
                System.debug('initTime'+initTime);
                Integer EndTime = 18;
                
                if(ra.EndDate__c == dt){
                    EndTime = Integer.valueOf((string.valueof(ra.End.time())).substring(0,2));
                }

                Integer iteration = EndTime-initTime;
                
                Integer count = 0;
                integer sum = 0;
                while (count <= iteration) {
                    if (initTime+sum<10){
                        ldt.add('0'+String.valueOf(initTime+sum)+':00');
                    } else {
                        ldt.add(String.valueOf(initTime+sum)+':00');    
                    }
                    count++;
                    sum++;
                }
                
            }
        }

        String dayOfWeek = compareInitDate.format('EEEEEEEEE');
        System.debug('dayOfWeek '+dayOfWeek);

        List<MembroDistribuicaoVisita__c> mdv = [SELECT Id FROM MembroDistribuicaoVisita__c WHERE ServiceResource__c = :serviceResourceId AND DistribuicaoVisita__r.Tipo__c = 'Loja autorizada'];

        Set<String> operationHourList = new Set<String>();
        Set<String> compareHour = new Set<String>();
        if(dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday'){
            compareHour.add('08:00');
            compareHour.add('09:00');
            compareHour.add('10:00');
            compareHour.add('11:00');
            compareHour.add('14:00');
            compareHour.add('15:00');
            compareHour.add('16:00');
            compareHour.add('17:00');
        }

        if(dayOfWeek == 'Saturday' && !mdv.isEmpty()){
            compareHour.add('08:00');
            compareHour.add('09:00');
            compareHour.add('10:00');
            compareHour.add('11:00');
        }

        List <ServiceTerritory> lst = [SELECT OperatingHoursId from ServiceTerriTory Where Id =: serviceTerritoryId Limit 1];
        List <TimeSlot> lts = new List<TimeSlot>();
        if(!lst.isEmpty()){
            lts = [SELECT DayOfWeek, StartTime, EndTime from TimeSlot Where OperatingHoursId =: lst[0].OperatingHoursId AND dayOfWeek =: dayOfWeek];
            if(!lts.isEmpty()){
                
                for(TimeSlot ts : lts){
                    Integer opInitTime = Integer.valueOf((string.valueof(ts.StartTime)).substring(0,2));
                    Integer opEndTime = Integer.valueOf((string.valueof(ts.EndTime)).substring(0,2));
                    Integer opIteration = opEndTime-opInitTime;
                    if(opIteration > 0){
                        Integer opcount = 1;
                        integer opsum = 0;
                        while (opcount <= opIteration) {
                            if (opInitTime+opsum<10){
                                operationHourList.add('0'+String.valueOf(opInitTime+opsum)+':00');
                            } else {
                                operationHourList.add(String.valueOf(opInitTime+opsum)+':00');    
                            }
                            opcount++;
                            opsum++;
                        }
                    }
                }
                //Integer hourIndex = 0;
            } 
        }

        //Security    
        if(lst.isEmpty() || lts.isEmpty()){
            operationHourList = compareHour;
        }

        List<String> hourList = new List<String>();
        Integer hourIndex = 0;
        for(String ohl : operationHourList){
            Boolean res = ldt.contains(ohl);
            if(!res){
                hourList.add(ohl);
            }
        }
        
        hourList.sort();

        System.debug('operationHourList '+hourList);
        
        System.debug('ldt date list'+ldt);
        return hourList;
    }
    
    @AuraEnabled
    public static List<Time> getNotAvailableTime (Date dt, Id serviceResId){
        List<Time> tm = new List<Time>();
        System.debug('Date' + dt);
        System.debug('Id' + serviceResId);
        List<ServiceAppointment> lsa = [SELECT Id, EarliestStartTime from ServiceAppointment Where ServiceResource__c =: serviceResId AND  EarliestStartTime >=: dt  AND EarliestStartTime <=: dt.addDays(1) AND Status = 'Scheduled'];
        System.debug('lsa list'+lsa);
        
        if(!lsa.isEmpty()){
            for (ServiceAppointment sa : lsa){
                System.debug('lsa time'+sa.EarliestStartTime.time());
                tm.add(sa.EarliestStartTime.time());
            }
        }
        System.debug('time list '+tm);
        return tm;
    }
    
    @AuraEnabled
    public static Map<String, Object> saveSchedule(Id leadId, Id resourceId, Id serviceTerritoryId, Date scheDate, Integer scheTimeHour, Integer scheTimeMin, String description, String atendente, Boolean AtendenteCallCenter, String historico){
        leadId = checkLead(leadId);
        blackListServiceResource = new List<String>();
        //System.debug(atendente);
        Map<String, Object> scc = new Map<String, Object>();
        Boolean isHoliday = false;
        String holidayMessage;
        System.debug('serviceResource '+resourceId);
        
        system.debug(resourceId);
        ServiceResource sr = [SELECT Id, RelatedRecordId, RelatedRecord.CANAL__c from ServiceResource Where Id =:resourceId];
        
        //ServiceTerritoryMember stm = [SELECT Id, ServiceTerritoryId from ServiceTerritoryMember Where ServiceResourceId =:resourceId AND ServiceTerritoryId =:serviceTerritoryId Limit 1];
        List<AusenciaTerritorioServico__c> lats = [SELECT Id, DataHorarioInicio__c, ServiceTerritoryId__c, Name, Tipo__c from AusenciaTerritorioServico__c Where ServiceTerritoryId__c =:serviceTerritoryId];
        System.debug('lats'+lats);
        if(!lats.isEmpty()){
            for(AusenciaTerritorioServico__c ats : lats){
                System.debug('ats.DataHorarioInicio__c.date()'+ats.DataHorarioInicio__c.date());
                System.debug('scheDate'+scheDate);
                if(ats.DataHorarioInicio__c.date() == scheDate){
                    isHoliday = true;
                    holidayMessage = ats.Tipo__c;
                    break;
                }
            }
        }
        
        DateTime scheduleDate = Datetime.newInstance(scheDate.year(), scheDate.month(), scheDate.day(), scheTimeHour, scheTimeMin, 0);
        
        Lead ld = [Select Id, Bairro__c, City, NumeroVidas__c, Porte__c, TipoAtendimento__c, Street, State, Country, PostalCode, Status from Lead Where Id =: leadId];
        
        Map<String, Object> responseCheck = checkBeforeSave(ld, scheduleDate, resourceId, false);
        System.debug('responseCheck '+responseCheck);
        historico = historico + '<br><br> responseCheck:<br> ' + responseCheck;

        if (responseCheck.get('success') != true){
            scc.put('message',responseCheck.get('message'));
            scc.put('response',false);
        } else {
            if (isHoliday){
                scc.put('message','Não é possível realizar agendamento neste dia. Motivo: '+holidayMessage);
                scc.put('response',false);
            } else {
                try {
                    
                   // checkLeadStatus(ld);
                
                    WorkOrder wo = new WorkOrder();
                    wo.Lead__c = leadId;
                    wo.Status = 'Novo';
                    Insert wo;
                    
                    ServiceAppointment sa = new ServiceAppointment();
                    sa.EarliestStartTime = scheduleDate;
                    sa.DueDate = scheduleDate.addDays(1);
                    sa.ParentRecordId = wo.Id;
                    sa.ServiceResource__c = resourceId;
                    sa.Duration = 60;
                    sa.DurationType = 'Minutes';
                    sa.Lead__c = ld.Id;
                    sa.OwnerId = sr.RelatedRecordId;
                    sa.Description = description;
                    sa.Street = ld.Street;
                    sa.City = ld.City;
                    sa.State = ld.State;
                    sa.Country = ld.Country;
                    sa.PostalCode = ld.PostalCode;
                    sa.ServiceTerritory__c  = serviceTerritoryId;
                    sa.Atendente__c = atendente;
                    sa.AtendimentoCallCenter__c = AtendenteCallCenter;
                    sa.HistoricoDecisao__c = historico;
                    insert sa;
                    
                    System.debug('sa re'+sa);
                    
                    
                    sa.SchedStartTime = scheduleDate;
                    sa.SchedEndTime = scheduleDate.addMinutes(60);
                    sa.Status = 'Scheduled';
                    
                    update sa;
                    
                    AssignedResource ar = new AssignedResource();
                    ar.ServiceAppointmentId = sa.Id;
                    ar.ServiceResourceId = resourceId;
                    
                    insert ar;
                    
                    System.debug('ar re'+sa);
                    
                    If(!Test.isRunningTest() && UserInfo.getProfileId() == System.Label.ProfileId_AtendenteCallCenter){
                        updateMetaData(resourceId, ld, serviceTerritoryId);    
                    }
                    
                    scc.put('response',true);
                } catch (Exception e) {
                    scc.put('response',false);
                    scc.put('message',e.getMessage());
                }
                
            }
        }        
        
        
        System.debug('scc '+scc);
        
        return scc;
    }
    
    //update the metadata
    public static void updateMetaData(Id resourceId, Lead ld, Id serviceTerritoryId){
        
        // 2022-01-24
        // List <DistribuicaoVisita__c> dv = getDisctibuicaoVisita(ld, new List<ServiceTerritory>{new ServiceTerritory(Id = serviceTerritoryId)});
        // AgendamentoDistribuicao__mdt adLAutorizada = [SELECT QuantidadeAtual__c, QuantidadePermitida__c FROM AgendamentoDistribuicao__mdt WHERE DeveloperName = 'LojaAutorizada' LIMIT 1];
        // AgendamentoDistribuicao__mdt adLPropria = [SELECT QuantidadeAtual__c, QuantidadePermitida__c FROM AgendamentoDistribuicao__mdt WHERE DeveloperName = 'LojaPropria' LIMIT 1];
        
        
        // Integer valueLAutorizada = adLAutorizada.QuantidadeAtual__c.intValue() + 1;
        // Integer valueLPropria = adLPropria.QuantidadeAtual__c.intValue() + 1;

        // if(!dv.isEmpty()){
        //     if(dv[0].Tipo__c != 'Loja autorizada'){     
        //         CustomMetadataCallback.createUpdateMetadata('AgendamentoDistribuicao__mdt.LojaAutorizada', 'Loja autorizada', 'QuantidadeAtual__c', valueLAutorizada);
        //     } else if(dv[0].Tipo__c == 'Loja autorizada') {
        //         CustomMetadataCallback.createUpdateMetadata('AgendamentoDistribuicao__mdt.LojaAutorizada', 'Loja autorizada', 'QuantidadeAtual__c', 0); 
        //     }

        //     if(dv[0].Tipo__c != 'Loja própria'){
        //         CustomMetadataCallback.createUpdateMetadata('AgendamentoDistribuicao__mdt.LojaPropria', 'Loja própria', 'QuantidadeAtual__c', valueLPropria);
        //     }else if(dv[0].Tipo__c == 'Loja própria'){
        //         CustomMetadataCallback.createUpdateMetadata('AgendamentoDistribuicao__mdt.LojaPropria', 'Loja própria', 'QuantidadeAtual__c', 0); 
        //     }
        // }

        List <DistribuicaoVisita__c> dv = getDisctibuicaoVisita(ld, new List<ServiceTerritory>{new ServiceTerritory(Id = serviceTerritoryId)});

        Map<String, FormaDistribuicao__c> mapFormaDistribuicao = new Map<String, FormaDistribuicao__c>();
        for(FormaDistribuicao__c fd : [SELECT Id, Name, QuantidadeAtual__c, QuantidadePermitida__c FROM FormaDistribuicao__c FOR UPDATE]){
            mapFormaDistribuicao.put(fd.Name, fd);
        }

        FormaDistribuicao__c fdAutorizada = mapFormaDistribuicao.get('Loja autorizada');
        FormaDistribuicao__c fdPropria = mapFormaDistribuicao.get('Loja própria');

        List<FormaDistribuicao__c> formasToUpdate = new List<FormaDistribuicao__c>();
        if(!dv.isEmpty()){
            if(dv[0].Tipo__c != 'Loja autorizada'){     
                fdAutorizada.QuantidadeAtual__c = fdAutorizada?.QuantidadeAtual__c + 1;
            } else if(dv[0].Tipo__c == 'Loja autorizada') {
                fdAutorizada.QuantidadeAtual__c = 0;
            }

            if(dv[0].Tipo__c != 'Loja própria'){
                fdPropria.QuantidadeAtual__c = fdPropria?.QuantidadeAtual__c + 1;
            }else if(dv[0].Tipo__c == 'Loja própria'){
                fdPropria.QuantidadeAtual__c = 0; 
            }

            formasToUpdate.add(fdAutorizada);
            formasToUpdate.add(fdPropria);
        }
        
        Database.update(formasToUpdate, false);
    }
    
    @TestVisible
    private static Map<String, Object> checkBeforeSave(Lead ld, DateTime dt, Id serviceResourceId, Boolean reScheduled){
        Map<String, Object> response = new Map<String, Object>();        
        
        //checking if the Lead has a schedul
        List <ServiceAppointment> leadsa = [SELECT Id, EarliestStartTime, Status from ServiceAppointment Where Lead__c =: ld.Id AND (Status = 'Scheduled' OR Status = 'In Progress')]; 
        
        if(!reScheduled){
            if(!leadsa.isEmpty()){
                response.put('success', false);
                response.put('message', 'Já existe um agendamento para esse Lead no dia '+ leadsa[0].EarliestStartTime.format('dd.MM.yyyy HH:mm'));
                return response;  
            }
        } else {
            if(!leadsa.isEmpty()){
                for (ServiceAppointment lsda : leadsa){
                    if(lsda.Status == 'In Progress'){
                        response.put('success', false);
                        response.put('message', 'Já existe um agendamento em curso.');
                        return response;
                    }
                }      
            }
        }
        
        
        //check if exist a ServiceAppointment on the same time
        List <ServiceAppointment> serviceResourcesa = [SELECT Id from ServiceAppointment Where ServiceResource__c =: serviceResourceId AND EarliestStartTime =: dt AND Status = 'Scheduled']; 
        if(!serviceResourcesa.isEmpty()){    
            response.put('success', false);
            response.put('message', 'Já existe um agendamento para esse Consultor nesse mesmo horário e dia ');
            return response;
        }
        
        //check if the date is passed
        if(dt < DateTime.now()){
            response.put('success', false);
            response.put('message', 'A data/hora de agendamento não pode ser anterior ao dia de hoje');
            return response;
        }
        
        response.put('success', true);
        return response; 
    }
    
    //get the territory List of the Lead
    private static List<ServiceTerritory> getServiceTerritoryList(Lead ld){
        List <ServiceTerritory> lst = [SELECT Id, Risco__c, LocalDificilAcesso__c, Name, ParentTerritoryId, ParentTerritory.Name from ServiceTerritory Where IsActive = true];
        List <ServiceTerritory> responseList = new List <ServiceTerritory>();

        String bairro;
        if(ld.City != null && ld.Bairro__c != null){
            ld.City = changeCity(ld.City);
            bairro = changeBairro(ld.Bairro__c) + getSigla(ld.City.toLowerCase());
        }

        for(ServiceTerritory st : lst){
            if(ld.City != null && st.Name.toLowerCase() == ld.City.toLowerCase()){
                responseList.add(st);
            }else{
                if(bairro != null && st.Name.toLowerCase() == bairro.toLowerCase() && st.ParentTerritoryId != null && st.ParentTerritory.Name.toLowerCase() == ld.City.toLowerCase()){
                    responseList.add(st);
                }
            }
        }
        return responseList;
    }

    private static String changeCity(String city){
        if(city == 'ribeirao das neves'){
            return 'ribeirão das neves';
        }if(city == 'sabara'){
            return 'sabará';
        }if(city == 'ibirite'){
            return 'ibirité';
        }

        return city;
    }

    private static String changeBairro(String bairro){
        if(bairro == 'Distrito Industrial Paulo Camilo Norte'){
            return 'Distrito Industrial Paulo Camilo No';
        }

        return bairro;
    }

    private static String getSigla(String city){
        if(city == 'vespasiado'){
            return ' - VP';
        }if(city == 'sarzedo'){
            return ' - SZ';
        }if(city == 'santa luzia'){
            return ' - SL';
        }if(city == 'sabará'){
            return ' - SA';
        }if(city == 'ribeirão das neves'){
            return ' - RN';
        }if(city == 'nova lima'){
            return ' - NL';
        }if(city == 'lagoa santa'){
            return ' - LS';
        }if(city == 'juatuba'){
            return ' - JU';
        }if(city == 'ibirité'){
            return ' - IB';
        }if(city == 'contagem'){
            return ' - CO';
        }if(city == 'betim'){
            return ' - BE';
        }

        return '';
    }
    
    //get the DistribuiçãoVisita from Lead
   /* private static DistribuicaoVisita__c [] getDisctibuicaoVisita(Lead ld){
        AgendamentoDistribuicao__mdt ad;
        
        Boolean isCPF = false;
        Boolean isCNPJ = false;
        if(ld.TipoAtendimento__c == 'Pessoa Física' || ld.TipoAtendimento__c == 'Pessoa Física RN' || ld.TipoAtendimento__c == 'Médico Cooperado'){
            isCPF = true;
        } else {
            isCNPJ = true;
        }
        
        if(Test.isRunningTest()){
            ad = ScheduleCampaignControllerFactory.createMeta();
        } else {
        	ad = [SELECT QuantidadeAtual__c, QuantidadePermitida__c from AgendamentoDistribuicao__mdt Limit 1];    
        }
        
        List<DistribuicaoVisita__c> dv = new List<DistribuicaoVisita__c> ();
        
        if(ad.QuantidadeAtual__c >= ad.QuantidadePermitida__c){
            dv = [SELECT Id, PessoaFisica__c, PessoaJuridica__c, Porte__c, Name, Tipo__c from DistribuicaoVisita__c Where (PessoaFisica__c =: isCPF OR PessoaJuridica__c =: isCNPJ) AND Porte__c LIKE: '%' + ld.Porte__c + '%' AND Tipo__c = 'Loja autorizada'];
            Integer totalMembros = [SELECT COUNT() FROM MembroDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN : dv];
            if(totalMembros == 0){
                dv = new List<DistribuicaoVisita__c>();
            }
        }
        if(dv.isEmpty()){
            dv = [SELECT Id, PessoaFisica__c, PessoaJuridica__c, Porte__c, Name, Tipo__c from DistribuicaoVisita__c Where (PessoaFisica__c =: isCPF OR PessoaJuridica__c =: isCNPJ) AND Porte__c LIKE: '%' + ld.Porte__c + '%' AND Tipo__c != 'Loja autorizada'];
        }   
        if(dv.isEmpty()){
            dv = [SELECT Id, PessoaFisica__c, PessoaJuridica__c, Porte__c, Name, Tipo__c from DistribuicaoVisita__c Where (PessoaFisica__c =: isCPF OR PessoaJuridica__c =: isCNPJ) AND Porte__c LIKE: '%' + ld.Porte__c + '%'];
        }

        System.debug('dv list'+dv);
        
        return dv;
    }*/

    private static DistribuicaoVisita__c [] getDisctibuicaoVisita(Lead ld, List<ServiceTerritory> lst){
        String historico = '<br><br>getDisctibuicaoVisita:<br>';
        // AgendamentoDistribuicao__mdt adLAutorizada; // 2022-01-24
        // AgendamentoDistribuicao__mdt adLPropria; // 2022-01-24
        Boolean isCPF = false;
        Boolean isCNPJ = false;
        if(ld.TipoAtendimento__c == 'Pessoa Física' || ld.TipoAtendimento__c == 'Pessoa Física RN' || ld.TipoAtendimento__c == 'Médico Cooperado'){
            isCPF = true;
        } else {
            isCNPJ = true;
        }
        
        // 2022-01-24
        // if(Test.isRunningTest()){
        //     adLAutorizada = ScheduleCampaignControllerFactory.createMeta();
        //     adLPropria = ScheduleCampaignControllerFactory.createMeta();
        // } else {
        //     adLAutorizada = [SELECT QuantidadeAtual__c, QuantidadePermitida__c FROM AgendamentoDistribuicao__mdt WHERE DeveloperName = 'LojaAutorizada' LIMIT 1];    
        //     adLPropria = [SELECT QuantidadeAtual__c, QuantidadePermitida__c FROM AgendamentoDistribuicao__mdt WHERE DeveloperName = 'LojaPropria' LIMIT 1];   
        // }

        Map<String, FormaDistribuicao__c> mapFormaDistribuicao = new Map<String, FormaDistribuicao__c>();
        for(FormaDistribuicao__c fd : [SELECT Id, Name, QuantidadeAtual__c, QuantidadePermitida__c, Priorizar__c FROM FormaDistribuicao__c]){
            mapFormaDistribuicao.put(fd.Name, fd);
        }

        FormaDistribuicao__c fdAutorizada = mapFormaDistribuicao.get('Loja autorizada');
        FormaDistribuicao__c fdPropria = mapFormaDistribuicao.get('Loja própria');
        
        List<DistribuicaoVisita__c> dv = new List<DistribuicaoVisita__c> ();
        historico = historico + '<br>fdAutorizada?.QuantidadeAtual__c = ' + fdAutorizada?.QuantidadeAtual__c;
        historico = historico + '<br>fdAutorizada?.QuantidadePermitida__c = ' + fdAutorizada?.QuantidadePermitida__c;
        historico = historico + '<br>fdAutorizada?.Priorizar__c = ' + fdAutorizada?.Priorizar__c;
        historico = historico + '<br>fdPropria?.QuantidadeAtual__c = ' + fdPropria?.QuantidadeAtual__c;
        historico = historico + '<br>fdPropria?.QuantidadePermitida__c = ' + fdPropria?.QuantidadePermitida__c;
        historico = historico + '<br>fdPropria?.Priorizar__c = ' + fdPropria?.Priorizar__c;
        
        if(
            (
                (fdAutorizada?.QuantidadeAtual__c >= fdAutorizada?.QuantidadePermitida__c || fdAutorizada?.Priorizar__c == true) 
                && UserInfo.getProfileId() != System.Label.ProfileId_Promotor 
                && (ld.TipoAtendimento__c != 'Pessoa Física RN' && ld.TipoAtendimento__c != 'Médico Cooperado')
            ) || agendamentoSabado == true){
                historico = historico + '<br> Primeira Condição linha 872';
                historico = historico + '<br> Query: ' + '[SELECT Id, PessoaFisica__c, PessoaJuridica__c, Porte__c, Name, Tipo__c from DistribuicaoVisita__c Where (PessoaFisica__c =: '+isCPF+' OR PessoaJuridica__c =: '+isCNPJ+') AND Porte__c LIKE: \'%\' + '+ld.Porte__c+' + \'%\' AND Tipo__c = \'Loja autorizada\'];';
            dv = [SELECT Id, PessoaFisica__c, PessoaJuridica__c, Porte__c, Name, Tipo__c from DistribuicaoVisita__c Where (PessoaFisica__c =: isCPF OR PessoaJuridica__c =: isCNPJ) AND Porte__c LIKE: '%' + ld.Porte__c + '%' AND Tipo__c = 'Loja autorizada'];
            Set<Id> dvIds = new Set<Id>();
            for(RegionalizacaoDistribuicaoVisita__c rdv : [SELECT Id, DistribuicaoVisita__c FROM RegionalizacaoDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN : dv AND ServiceTerritory__c IN : lst]){
                dvIds.add(rdv.DistribuicaoVisita__c);
            }
            historico = historico + '<BR> RegionalizacaoDistribuicaoVisita__c :<BR>' + String.valueOf(dvIds);
            
            Integer totalMembros = [SELECT COUNT() FROM MembroDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN : dvIds AND ServiceResource__r.IsActive = true AND ServiceResource__c NOT IN :blackListServiceResource];
            if(totalMembros == 0){
                dv = new List<DistribuicaoVisita__c>();
            }
            historico = historico + '<br>TotalMembros: ' + totalMembros;
        }

        if(dv.isEmpty() && (fdPropria?.QuantidadeAtual__c >= fdPropria?.QuantidadePermitida__c || fdPropria?.Priorizar__c == true) && UserInfo.getProfileId() != System.Label.ProfileId_Promotor){
            historico = historico + '<br> Segunda Condição linha 889';

            dv = [SELECT Id, PessoaFisica__c, PessoaJuridica__c, Porte__c, Name, Tipo__c from DistribuicaoVisita__c Where (PessoaFisica__c =: isCPF OR PessoaJuridica__c =: isCNPJ) AND Porte__c LIKE: '%' + ld.Porte__c + '%' AND Tipo__c = 'Loja própria'];
            historico = historico + '<br> Query: ' + '[SELECT Id, PessoaFisica__c, PessoaJuridica__c, Porte__c, Name, Tipo__c from DistribuicaoVisita__c Where (PessoaFisica__c =: '+isCPF+' OR PessoaJuridica__c =: '+isCNPJ+') AND Porte__c LIKE: \'%\' + '+ld.Porte__c+' + \'%\' AND Tipo__c = \'Loja própria\'];';
            Set<Id> dvIds = new Set<Id>();
            for(RegionalizacaoDistribuicaoVisita__c rdv : [SELECT Id, DistribuicaoVisita__c FROM RegionalizacaoDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN : dv AND ServiceTerritory__c IN : lst]){
                dvIds.add(rdv.DistribuicaoVisita__c);
            }
            historico = historico + '<BR> RegionalizacaoDistribuicaoVisita__c :<BR>' + String.valueOf(dvIds);
            
            Integer totalMembros = [SELECT COUNT() FROM MembroDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN : dvIds AND ServiceResource__r.IsActive = true AND ServiceResource__c NOT IN :blackListServiceResource];
            if(totalMembros == 0){
                dv = new List<DistribuicaoVisita__c>();
            }
            historico = historico + '<br>TotalMembros: ' + totalMembros;
        }

        if(dv.isEmpty()){
            historico = historico + '<br> Terceira Condição linha 907';
            historico = historico + '<br> Query: ' + '[SELECT Id, PessoaFisica__c, PessoaJuridica__c, Porte__c, Name, Tipo__c from DistribuicaoVisita__c Where (PessoaFisica__c =: '+isCPF+' OR PessoaJuridica__c =: '+isCNPJ+') AND Porte__c LIKE: \'%\' + '+ld.Porte__c+' + \'%\' AND Tipo__c != \'Loja autorizada\' AND Tipo__c != \'Loja própria\'];';
            dv = [SELECT Id, PessoaFisica__c, PessoaJuridica__c, Porte__c, Name, Tipo__c from DistribuicaoVisita__c Where (PessoaFisica__c =: isCPF OR PessoaJuridica__c =: isCNPJ) AND Porte__c LIKE: '%' + ld.Porte__c + '%' AND Tipo__c != 'Loja autorizada' AND Tipo__c != 'Loja própria'];
            Set<Id> dvIds = new Set<Id>();
            for(RegionalizacaoDistribuicaoVisita__c rdv : [SELECT Id, DistribuicaoVisita__c FROM RegionalizacaoDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN : dv AND ServiceTerritory__c IN : lst]){
                dvIds.add(rdv.DistribuicaoVisita__c);
            }
            historico = historico + '<BR> RegionalizacaoDistribuicaoVisita__c :<BR>' + String.valueOf(dvIds);
            Integer totalMembros = [SELECT COUNT() FROM MembroDistribuicaoVisita__c WHERE DistribuicaoVisita__c IN : dvIds AND ServiceResource__r.IsActive = true AND ServiceResource__c NOT IN :blackListServiceResource];
            if(totalMembros == 0){
                dv = new List<DistribuicaoVisita__c>();
            }
            historico = historico + '<br>TotalMembros: ' + totalMembros;
        }   

        // if(dv.isEmpty()){
        //     dv = [SELECT Id, PessoaFisica__c, PessoaJuridica__c, Porte__c, Name, Tipo__c from DistribuicaoVisita__c Where (PessoaFisica__c =: isCPF OR PessoaJuridica__c =: isCNPJ) AND Porte__c LIKE: '%' + ld.Porte__c + '%'];
        // }
    
        System.debug('getDisctibuicaoVisita');
        historicoDecisao = historicoDecisao + historico;
        //historicoDecisao = historicoDecisao + '<br><br>' + String.valueOf(dv);
        for(DistribuicaoVisita__c d : dv){
            historicoDecisao = historicoDecisao + '<br>' + String.valueOf(d);
            System.debug(d.Name + ' - ' + d.Id + ' - ' + d.Tipo__c);
        }
        
        return dv;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getRescheduleoptions(){
        Map<String, String> options = new Map<String, String>();
    
        Schema.DescribeFieldResult fieldResult = ServiceAppointment.MotivoReagendamento__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                
        for( Schema.PicklistEntry f : ple)
        {
            options.put(f.getLabel(), f.getValue());
        }       
        return options;
    }
    
    @AuraEnabled()
    public static Map<String, Object> reSaveSchedule(Id leadId, Id resourceId, Id serviceTerritoryId, Date scheDate, Integer scheTimeHour, Integer scheTimeMin, String description, Id serviceAppointmentId, String rescheduleReason){
        leadId = checkLead(leadId);
        blackListServiceResource = new List<String>();

        Map<String, Object> scc = new Map<String, Object>();
        
        Lead ld = [Select Id, Bairro__c, City, NumeroVidas__c, Porte__c, TipoAtendimento__c, Street, State, Country, PostalCode, Status from Lead Where Id =: leadId];
        
        ServiceResource sr = [Select Id, RelatedRecordId, RelatedRecord.CANAL__c from ServiceResource Where Id =:resourceId];
        
        ServiceAppointment sa = [SELECT Id, ParentRecordId from ServiceAppointment Where Id =:serviceAppointmentId];
        
        DateTime scheduleDate = Datetime.newInstance(scheDate.year(), scheDate.month(), scheDate.day(), scheTimeHour, scheTimeMin, 0);
        
        Map<String, Object> responseCheck = checkBeforeSave(ld, scheduleDate, resourceId, true);
        System.debug('responseCheck '+responseCheck);
        
        if (responseCheck.get('success') != true){
            scc.put('message',responseCheck.get('message'));
            scc.put('response',false);
        } else {
            try {
                
              // checkLeadStatus(ld);
            
                sa.Status = 'Rescheduled';
                sa.MotivoReagendamento__c = rescheduleReason;
                if(!Test.isRunningTest()){
                    update sa;
                }
                
                ServiceAppointment newSa = new ServiceAppointment();
                newSa.EarliestStartTime = scheduleDate;
                newSa.DueDate = scheduleDate.addDays(1);
                newSa.ParentRecordId = sa.ParentRecordId;
                newSa.ServiceResource__c = resourceId;
                newSa.Duration = 60;
                newSa.DurationType = 'Minutes';
                newSa.Lead__c = ld.Id;
                newSa.OwnerId = sr.RelatedRecordId;
                newSa.Description = description;
                newSa.SchedStartTime = scheduleDate;
                newSa.SchedEndTime = scheduleDate.addMinutes(60);
                newSa.Street = ld.Street;
                newSa.City = ld.City;
                newSa.State = ld.State;
                newSa.Country = ld.Country;
                newSa.PostalCode = ld.PostalCode;
                newSa.ServiceTerritory__c  = serviceTerritoryId;
                newSa.Reagendamento__c  = true;
                
                insert newSa;
                
                newSa.Status = 'Scheduled';
                
                update newSa;
    
                AssignedResource ar = new AssignedResource();
                ar.ServiceAppointmentId = newSa.Id;
                ar.ServiceResourceId = resourceId;
                
                insert ar;
                
                scc.put('response',true);
                
            } catch (Exception e) {
                scc.put('response',false);
                scc.put('message',e.getMessage());
            }
        }
        
        
        return scc;
        
        
    }

    @AuraEnabled
    public static void cancelSchedule(Id serviceAppointmentId, String motivo, String submotivo){
        try {
            ServiceAppointment appt = new ServiceAppointment(
                Id = serviceAppointmentId,
                MotivoCancelamento__c = motivo,
                SubMotivoCancelamento__c = submotivo,
                Status = 'Canceled'
            );
            // if(atendenteCallCenter != null){
            //     atendenteCallCenter.AtendimentoMarcado__c = false;
            //     //atendenteCallCenter.TeveAtendimentoCancelado__c = true;
            //     update atendenteCallCenter;
            // }

            update appt;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static void checkFormasDistribuicao(){
        String historico = 'checkFormasDistribuicao: <br>';
        Set<String> formasExistentes = new Set<String>();
        for(FormaDistribuicao__c forma : [SELECT Id, Name FROM FormaDistribuicao__c]) {
            formasExistentes.add(forma.Name);
        }

        List<FormaDistribuicao__c> formasToInsert = new List<FormaDistribuicao__c>();
        if(formasExistentes.contains('Loja autorizada') == false){
            formasToInsert.add(new FormaDistribuicao__c(Name='Loja autorizada', QuantidadeAtual__c = 0, QuantidadePermitida__c = 10));
        }

        if(formasExistentes.contains('Loja própria') == false){
            formasToInsert.add(new FormaDistribuicao__c(Name='Loja própria', QuantidadeAtual__c = 0, QuantidadePermitida__c = 10));
        }

        if(formasToInsert.isEmpty() == false){
            insertFormas(JSON.serialize(formasToInsert));
            historicoDecisao = historicoDecisao + historico + JSON.serialize(formasToInsert);
        }

       
    }

    @future
    static void insertFormas(String toInsert){
        try{
            List<FormaDistribuicao__c> formasToInsert = (List<FormaDistribuicao__c>) JSON.deserialize(toInsert, List<FormaDistribuicao__c>.class);
             insert formasToInsert;
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        

    }

    @AuraEnabled(cacheable=true)
    public static List<PeriodoTrabalhoAtendente__c> getHorariosComerciais(){
        
        try {
            List<PeriodoTrabalhoAtendente__c> itensHorarios = [
                                                        SELECT id, 
                                                               PeriodoTrabalho__r.HoraEntrada__c, 
                                                               PeriodoTrabalho__r.HoraSaida__c,
                                                               AtendimentoMarcado__c,
                                                               Atendente__r.Name,
                                                               Atendente__c,
                                                               Atendente__r.RelatedRecord.CANAL__c
                                                        FROM PeriodoTrabalhoAtendente__c 
                                                        WHERE PeriodoTrabalho__r.Ativo__c = true
                                                        ORDER BY AtendimentoMarcado__c ASC
                                                    ];
            
            return itensHorarios;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateHorariosComerciais( List<PeriodoTrabalhoAtendente__c> listaAtendentes, List<String> listaIds, String idMarcado){
        
        try {
            for(PeriodoTrabalhoAtendente__c itemAtendente : listaAtendentes){
                if(listaIds.size() == listaAtendentes.size()){
                    System.debug('entrou comparação');
                    if(itemAtendente.Id != idMarcado){
                        System.debug('entrou comparação 2');
                        itemAtendente.AtendimentoMarcado__c = false;
                    }
                }
                else if(listaIds.contains(itemAtendente.Id)){
                    itemAtendente.AtendimentoMarcado__c = true;
                }
            }
            update listaAtendentes;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<String> verificarHorarioOcupado(Date scheDate, integer scheHour, Integer scheMin){
        try {
            DateTime scheduleDate = Datetime.newInstance(scheDate.year(), scheDate.month(), scheDate.day(), scheHour, scheMin, 0);
            List<String> idsRegistradosNoHorario = new List<String>();

            List<ServiceAppointment> lsa = [SELECT Id, ServiceResource__c from ServiceAppointment Where EarliestStartTime =: scheduleDate AND Status = 'Scheduled'];
            for(ServiceAppointment lsaItem : lsa){
                idsRegistradosNoHorario.add(lsaItem.ServiceResource__c);
            }

            return idsRegistradosNoHorario;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}