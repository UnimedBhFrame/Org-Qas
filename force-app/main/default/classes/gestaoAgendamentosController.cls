public with sharing class gestaoAgendamentosController {
    private static List<String> availableCities = new List<String>{
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

    @AuraEnabled
    public static boolean hasAccess(String id){
        boolean valid = false;

        try {
            List<ServiceResource> lst = ServiceResourceDAO.getByUserId(id);
            valid = lst.size() != 0 ? true : false;

            return valid;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map <String, Object> getTerritoryInfo(Id corretoraId, Id resourceId) {
        Map <String, Object> response = new Map <String, Object>();
        List<ServiceResource> sr = ServiceResourceDAO.getByUserId(resourceId);
        List<ServiceAppointment> lsa = ServiceAppointmentDAO.getByIdAndStatus(corretoraId, sr[0].Id);
        Corretora__c corretora = CorretoraDAO.getById(corretoraId);

        if(corretora.EnderecoCidade__c != null || corretora.EnderecoBairro__c != null || corretora.EnderecoEstado__c != null) {
            response.put('leadAddress', true);
            if(availableCities.contains(corretora.EnderecoCidade__c.toLowerCase())) {
                response.put('availableCities', true);
                if(lsa.isEmpty()) {
                    response.put('isScheduled', false);

                    List <ServiceTerritory> lst = getServiceTerritoryList(corretora);

                    if(lst.isEmpty()) {
                        response.put('addressExist', false);
                        response.put('territoryRisk', false);
                    } else {
                        response.put('addressExist', true);

                        Boolean ccc = true;

                        for(ServiceTerriTory ls : lst) {
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

                        if(ccc) {
                            response.put('success', true);
                        }
                    }
                } else {
                    try {                        
                        response.put('isScheduled', true);
                        response.put('scheduledDate', lsa[0].EarliestStartTime);
                        response.put('resourceId', sr[0].Id);
                        response.put('resourceName', sr[0].Name);
                        response.put('visitDate', lsa[0].EarliestStartTime.addMinutes(-180));
                        response.put('serviceTerritoryId', lsa[0].ServiceTerritory__c);
                        response.put('AtendimentoCallCenter', lsa[0].AtendimentoCallCenter__c);
                        response.put('serviceAppointmentId', lsa[0].Id);
                    } catch (Exception e) {
                        system.debug('Error: ' + e);
                    }
                    
                }
            } else {
                response.put('availableCities', false);
            }
        } else {
            response.put('leadAddress', false);
        }

        return response;
    }

    private static List<ServiceTerritory> getServiceTerritoryList(Corretora__c corretora) { 
        List <ServiceTerritory> lst = ServiceTerritoryDAO.getByIsActive();
        List <ServiceTerritory> responseList = new List <ServiceTerritory>();

        String bairro;

        if (corretora.EnderecoCidade__c != null && corretora.EnderecoBairro__c != null) { 
            corretora.EnderecoCidade__c = changeCity(corretora.EnderecoCidade__c);
            bairro = changeBairro(corretora.EnderecoBairro__c) + getSigla(corretora.EnderecoCidade__c.toLowerCase());
        }

        for(ServiceTerritory st : lst) {
            if (corretora.EnderecoCidade__c != null && st.Name.toLowerCase() == corretora.EnderecoCidade__c.toLowerCase()) {
                responseList.add(st);
            } else {
                if (bairro != null && st.Name.toLowerCase() == bairro.toLowerCase() && st.ParentTerritoryId != null && st.ParentTerritory.Name.toLowerCase() == corretora.EnderecoCidade__c.toLowerCase()) { 
                    responseList.add(st);
                }
            }
        }

        return responseList;
    }

    private static String changeCity(String city) { 
        if (city == 'ribeirao das neves') { 
            return 'ribeirão das neves';
        }if (city == 'sabara') { 
            return 'sabará';
        }if (city == 'ibirite') { 
            return 'ibirité';
        }

        return city;
    }

    private static String changeBairro(String bairro) { 
        if (bairro == 'Distrito Industrial Paulo Camilo Norte') { 
            return 'Distrito Industrial Paulo Camilo No';
        }

        return bairro;
    }

    @AuraEnabled
    public static List<ServiceAppointment> getApp(Id corretoraId, Id resourceId, Date scheDate, String scheTime){
        DateTime compareInitDate = DateTime.newInstance(scheDate.year(), scheDate.month(), scheDate.day(), 0, 0, 0);
        DateTime compareEndDate = compareInitDate.addDays(1);
        List<ServiceAppointment> unavailableHours = new List<ServiceAppointment>();
        List<ServiceResource> lst = ServiceResourceDAO.getByUserId(resourceId);
        List<ServiceAppointment> appointments = ServiceAppointmentDAO.getByResource(corretoraId, lst[0].Id, compareInitDate, compareEndDate);

        for(Integer i = (appointments.size()-1); i>= 0; i--){
            ServiceAppointment s = appointments[i];
            unavailableHours.add(s);
        }

        unavailableHours.sort();

        return unavailableHours;
    }

    @AuraEnabled
    public static List<String> getAvailableSchedule(Date selectedDate, Id corretoraId, Id resourceId) {
        List<ServiceResource> lst = ServiceResourceDAO.getByUserId(resourceId);
        Set<String> businessHours = new Set<String>();
        List<String> availableHours = new List<String>();
        DateTime compareInitDate = DateTime.newInstance(selectedDate.year(), selectedDate.month(), selectedDate.day(), 0, 0, 0);
        DateTime compareEndDate = compareInitDate.addDays(1);

        Date myDate = compareInitDate.date();
        String dateCompare = String.valueOf(myDate).removeEnd(' 00:00:00');

        String dayOfWeek = compareInitDate.format('EEEEEEEEE');

        try {
            if(dayOfWeek != 'Saturday' ||  dayOfWeek != 'Sunday') {
                businessHours.add('08:00');
                businessHours.add('09:00');
                businessHours.add('10:00');
                businessHours.add('11:00');
                businessHours.add('14:00');
                businessHours.add('15:00');
                businessHours.add('16:00');
                businessHours.add('17:00');
            } else {
                businessHours.add('08:00');
                businessHours.add('09:00');
                businessHours.add('10:00');
                businessHours.add('11:00');
            }
            
            List<ServiceAppointment> appointments = ServiceAppointmentDAO.getByResource(corretoraId, lst[0].Id, compareInitDate, compareEndDate);

            for (Integer i = (appointments.size()-1); i>= 0; i--){
                ServiceAppointment s = appointments[i];
                Date myDate2 = s.EarliestStartTime.date();
                String dateCompare2 = String.valueOf(myDate2).removeEnd(' 00:00:00');

                if(dateCompare == dateCompare2) {
                    Integer hour = s.EarliestStartTime.hour();
                    String formattedDate;

                    if(hour < 10) {
                        formattedDate = '0' + hour + ':00';
                    } else {
                        formattedDate = hour + ':00';
                    }

                    businessHours.remove(formattedDate);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        availableHours.addAll(businessHours);

        return availableHours;
    }

    @AuraEnabled
    public static Map<String, Object> saveSchedule(Id corretoraId, Id resourceId, Id serviceTerritoryId, Date scheDate, String scheTime, String description) { 
        Integer selectedHour = integer.valueOf(scheTime);
        Map<String, Object> scc = new Map<String, Object>();        
        List<ServiceResource> sr = ServiceResourceDAO.getByUserId(resourceId);
        Corretora__c corretora = CorretoraDAO.getById(corretoraId);

        DateTime scheduleDate = Datetime.newInstance(scheDate.year(), scheDate.month(), scheDate.day(), selectedHour, 0, 0);

        WorkOrder wo = new WorkOrder();
        wo.Corretora__c = corretoraId;
        wo.Status = 'Novo';
        insert wo;
        
        ServiceAppointment sa = new ServiceAppointment();
        sa.EarliestStartTime = scheduleDate;
        sa.DueDate = scheduleDate.addDays(1);
        sa.ParentRecordId = wo.Id;
        sa.ServiceResource__c = sr[0].Id;
        sa.Duration = 60;
        sa.DurationType = 'Minutes';
        sa.Corretora__c = corretora.Id;
        sa.OwnerId = sr[0].RelatedRecordId;
        sa.Description = description;
        sa.Street = corretora.Endereco__c;
        sa.City = corretora.EnderecoCidade__c;
        sa.State = corretora.EnderecoEstado__c;
        sa.Country = corretora.EnderecoPais__c;
        sa.PostalCode = corretora.EnderecoCep__c;
        sa.ServiceTerritory__c  = serviceTerritoryId;
        insert sa;
        
        sa.SchedStartTime = scheduleDate;
        sa.SchedEndTime = scheduleDate.addMinutes(60);
        sa.Status = 'Scheduled';
        
        update sa;
        
        // AssignedResource ar = new AssignedResource();
        // ar.ServiceAppointmentId = sa.Id;
        // ar.ServiceResourceId = resourceId;
        
        // insert ar;
        
        scc.put('response', true);
        scc.put('newScheduledDate', scheduleDate.addHours(-3));
        
        return scc;
    }

    @AuraEnabled()
    public static Map<String, Object> saveReschedule(Date scheDate, String scheTime, String description, Id serviceAppointmentId, String rescheduleReason) { 
        Map<String, Object> scc = new Map<String, Object>();
        Integer selectedHour = integer.valueOf(scheTime);
        DateTime scheduleDate = Datetime.newInstance(scheDate.year(), scheDate.month(), scheDate.day(), selectedHour, 0, 0);

        try {
            ServiceAppointment appt = new ServiceAppointment(
                Id = serviceAppointmentId,
                Reagendamento__c = true,
                EarliestStartTime = scheduleDate,
                DueDate = scheduleDate.addDays(1),
                MotivoReagendamento__c = 'Cliente Ausente'//rescheduleReason
            );

            update appt;

            scc.put('newScheduledDate', scheduleDate.addHours(-3));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return scc;
    }

    @AuraEnabled
    public static void cancelSchedule(Id serviceAppointmentId, String motivo, String submotivo) { 
        try {
            ServiceAppointment appt = new ServiceAppointment(
                Id = serviceAppointmentId,
                MotivoCancelamento__c = motivo,
                SubMotivoCancelamento__c = submotivo,
                Status = 'Canceled'
            );

            update appt;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String getSigla(String city) { 
        if (city == 'vespasiado') { 
            return ' - VP';
        }if (city == 'sarzedo') { 
            return ' - SZ';
        }if (city == 'santa luzia') { 
            return ' - SL';
        }if (city == 'sabará') { 
            return ' - SA';
        }if (city == 'ribeirão das neves') { 
            return ' - RN';
        }if (city == 'nova lima') { 
            return ' - NL';
        }if (city == 'lagoa santa') { 
            return ' - LS';
        }if (city == 'juatuba') { 
            return ' - JU';
        }if (city == 'ibirité') { 
            return ' - IB';
        }if (city == 'contagem') { 
            return ' - CO';
        }if (city == 'betim') { 
            return ' - BE';
        }

        return '';
    }
}