import { LightningElement, track, wire, api } from 'lwc';

import getTerritoryInfo from '@salesforce/apex/ScheduleCampaignController.getTerritoryInfo';
//import getPermission from '@salesforce/apex/ScheduleCampaignController.getPermission';
//import getAvailableResource from '@salesforce/apex/ScheduleCampaignController.getServiceResource';
import saveSchedule from '@salesforce/apex/ScheduleCampaignController.saveSchedule';
import resaveSchedule from '@salesforce/apex/ScheduleCampaignController.reSaveSchedule';
import getHorariosComerciais from '@salesforce/apex/ScheduleCampaignController.getHorariosComerciais';
import updateHorariosComerciais from '@salesforce/apex/ScheduleCampaignController.updateHorariosComerciais';
import cancelSchedule from '@salesforce/apex/ScheduleCampaignController.cancelSchedule';
import notAvailableDate from '@salesforce/apex/ScheduleCampaignController.getNotAvailableDate';
import notAvailableTime from '@salesforce/apex/ScheduleCampaignController.getNotAvailableTime';
import getRescheduleoptions from '@salesforce/apex/ScheduleCampaignController.getRescheduleoptions';
import getPermissionAgendamentoSabado from '@salesforce/apex/ScheduleCampaignController.getPermissionAgendamentoSabado';
import verificarHorarioOcupado from '@salesforce/apex/ScheduleCampaignController.verificarHorarioOcupado';


import hasPermissionAgendamentoSabado from '@salesforce/customPermission/AgendamentoSabado'
import hasPermissionSelecionarAtendente from '@salesforce/customPermission/AgendamentoSelecionarAtendente'
import hasPermissionPSAtendenteCallCenter from '@salesforce/customPermission/PSAtendenteCallCenter'

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex'
import { getRecord, generateRecordInputForUpdate } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';


import SERVICE_APPOINTMENT_OBJECT from '@salesforce/schema/ServiceAppointment';
import LEAD_OBJECT from '@salesforce/schema/Lead';

import CORRETORA_OBJECT from '@salesforce/schema/Corretora__c';

import LEAD_RECORDTYPEID_FIELD from '@salesforce/schema/Lead.RecordTypeId';
import MOTIVO_CANCELAMENTO from '@salesforce/schema/ServiceAppointment.MotivoCancelamento__c';
import SUBMOTIVO_CANCELAMENTO from '@salesforce/schema/ServiceAppointment.SubMotivoCancelamento__c';

import ATENDENTE from '@salesforce/schema/ServiceAppointment.Atendente__c';
import IsDeleted from '@salesforce/schema/Account.IsDeleted';

export default class ScheduleComponent extends LightningElement {
    @api recordId;
    @api actionButton = false;

    @track hasPermission = true;
    @track adressStatus = false;
    @track riskStatus = false;
    @track scheduleStatus = false;
    @track isScheduled = false;
    @track hasAddress = false;
    @track hasError = false;
    @track errorMessage;
    @track riskMessage;
    @track addressMessage;
    @track inProgress;
    @track logErrorMessage;
    @track errorStatus = false;

    @track serviceResourceId;
    @track serviceResourceName;
    @track textResourceName;
    @track scheDate;
    @track scheTime;
    @track consult;
    @track oldConsult;
    @track serviceTerritoryId;
    @track serviceAppointmentId;

    @track dateList = [];
    @track timeList = [];
    @track listLength;

    @track scheduledDate;

    @track additionalInfo;

    @track rescheduleOptions;

    @track loadInfo;
    li;

    @track contadorMarcadoOld = 0;

    //@track permissionAgendamentoSabado = false;
    @track agendamentoSabado = false;
    @track atendenteCallCenter = false;
    @track reschedule = false;
    /* @wire(getPermissionAgendamentoSabado)
     wiredPermissionAgendamentoSabado(value){
         if(typeof value.data != undefined){
             this.permissionAgendamentoSabado = value.data;
         }
         if(value.error){
             console.log(JSON.stringify(value.error));
         }
     }*/
    get permissionAgendamentoSabado() {
        return hasPermissionAgendamentoSabado;
    }

    get permissionSelecionarAtendente() {
        return hasPermissionSelecionarAtendente;
    }

    get permissionPSAtendenteCallCenter() {
        return hasPermissionPSAtendenteCallCenter;
    }

    @track objectLeadInfo;

    @track objectCorretoraInfo;

    @track recordTypeId;

    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    objectLeadInfo;

    @wire(getObjectInfo, { objectApiName: CORRETORA_OBJECT })
    objectCorretoraInfo;

    @wire(getRecord, { recordId: '$recordId', fields: LEAD_RECORDTYPEID_FIELD })
    getLeadRecordType({ error, data }) {
        if (data) {
            var result = JSON.parse(JSON.stringify(data));
            console.log('Lead data: ', result);
            this.recordTypeId = result.fields.RecordTypeId;

        }
        else if (error) {
            var result = JSON.parse(JSON.stringify(error));
            console.log('error: ', result);
        }
    };

    @track blackList = [];
    @track canal;

    @wire(getTerritoryInfo, { leadId: '$recordId', agendamentoSab: '$agendamentoSabado', blackList: '$blackList' })
    wiredTypes(result) {
        this.li = result;
        this.hasPermission = true;
        this.adressStatus = false;
        this.riskStatus = false;
        this.scheduleStatus = false;
        this.isScheduled = false;
        this.hasAddress = false;
        this.hasError = false;
        this.inProgress = false;
        console.log('5 ok');
        if (result.error) {
            console.log('error');
            console.log(result.error);
            this.logErrorMessage = "Você não possui permissão para acessar o componente de agendamento";
            this.errorStatus = true;
            this.hasPermission = false;
        } else if (result.data) {
            this.loadInfo = result.data;
            console.log('resdata');
            console.log(this.loadInfo);
            this.hasPermission = this.loadInfo.hasPermission;
            this.serviceAppointmentId = this.loadInfo.serviceAppointmentId;
            if (this.loadInfo != null) {
                if (this.loadInfo.resourceId != null) {
                    if (this.loadInfo.resourceId.RelatedRecord != null) {
                        this.canal = this.loadInfo.resourceId.RelatedRecord.CANAL__c;
                    }
                }
                if (this.loadInfo.AtendimentoCallCenter != null) {
                    this.atendenteCallCenter = this.loadInfo.AtendimentoCallCenter;
                }
            }

            this.consult = [];
            this.consult.push({ label: this.loadInfo.resourceName, value: this.loadInfo.resourceId });

            console.log('consult');
            console.log(this.consult);

            if (this.loadInfo.serviceTerritoryId) {
                this.serviceTerritoryId = this.loadInfo.serviceTerritoryId;
            }

            if (this.loadInfo.resourceId) {
                if (this.loadInfo.resourceId.Id) {
                    this.serviceResourceId = this.loadInfo.resourceId.Id;
                } else {
                    this.serviceResourceId = this.loadInfo.resourceId;
                }

            }

            if (this.loadInfo.leadAddress) {
                this.hasAddress = true;
                if (this.loadInfo.availabelCities) {
                    if (this.loadInfo.hasScheduled) {
                        this.isScheduled = true;
                        this.serviceResourceName = this.loadInfo.resourceName;
                        this.textResourceName = this.loadInfo.resourceName;
                        this.scheduledDate = this.convertDateToUTC(new Date(this.loadInfo.visitDate));
                        if (this.loadInfo.inProgress && this.isScheduled) {
                            this.inProgress = true;
                        } else {
                            this.inProgress = false;
                        }
                    } else {
                        if (this.loadInfo.addressExist) {
                            this.adressStatus = false;
                            if (this.loadInfo.bothDificult) {
                                this.riskStatus = true
                                this.scheduleStatus = false;
                                this.riskMessage = 'Área de Risco e Local de difícil acesso';
                            } else if (this.loadInfo.dificultTerrain) {
                                this.riskStatus = true
                                this.scheduleStatus = false;
                                this.riskMessage = 'Local de difícil acesso';
                            } else if (this.loadInfo.territoryRisk) {
                                this.riskStatus = true
                                this.scheduleStatus = false;
                                this.riskMessage = 'Área de Risco';
                            } else {
                                if (this.loadInfo.success) {
                                    this.consult = [];
                                    this.consult.push({ label: this.loadInfo.resourceId.Name, value: this.loadInfo.resourceId.Id });

                                    this.scheduleStatus = true;

                                    console.log('data consult');
                                    console.log(this.consult);
                                } else {
                                    this.hasError = true;
                                    this.errorMessage = this.loadInfo.message;
                                }
                            }
                        } else {
                            this.adressStatus = true;
                            this.scheduleStatus = false;
                        }
                    }
                } else {
                    this.hasAddress = false;
                    this.addressMessage = 'Endereço fora da área de abrangência da Unimed-BH.'

                }


            } else {
                this.hasAddress = false;
                this.addressMessage = 'Endereço do Lead está incompleto. Favor completá-lo. (Cidade e Bairro);'
            }
        }
    }

    convertDateToUTC(date) {
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours() - 3, date.getUTCMinutes(), date.getUTCSeconds());
    }

    @wire(getRescheduleoptions, { targetId: '$recordId' })
    wiredOptions({ error, data }) {
        if (error) {
            console.log('error');
            console.dir(error);
        } else if (data) {
            console.log('type');
            console.log(data);
            this.options = [];
            for (var dt in data) {
                this.options.push({ label: dt, value: dt });
            }
            this.rescheduleOptions = this.options;
            console.log('rescheduleOptions');
            console.log(this.rescheduleOptions);
        }
    }

    handleChangeAgendSabados(event) {
        this.agendamentoSabado = event.detail.checked;
        console.log(this.agendamentoSabado)

        this.clearFields();
    }

    handleConsult(event) {
        console.log('event detail');
        console.log(event.detail.value);

        if (this.reschedule) {
            if (this.atendenteCallCenter) {
                this.serviceResourceId = event.detail.value;
                this.serviceResourceName = event.detail.value;

                if (this.atendenteCallCenter && this.reschedule) {
                    for (var i in this.listPeriodoTrabalho.data) {
                        if (this.listPeriodoTrabalho.data[i].Atendente__r.Id == event.detail.value) {
                            this.primeiroHorario = this.msToTime(this.listPeriodoTrabalho.data[i].PeriodoTrabalho__r.HoraEntrada__c) + 'Z';
                            this.ultimoHorario = this.msToTime(this.listPeriodoTrabalho.data[i].PeriodoTrabalho__r.HoraSaida__c) + 'Z';
                        }
                    }
                }
            }
            else {
                this.serviceResourceName = event.detail.value;
            }
            console.log(this.serviceResourceName);
        }
        else {

            var itemCanal;
            if (this.atendenteCallCenter) {
                for (var i in this.listPeriodoTrabalho.data) {
                    if (this.listPeriodoTrabalho.data[i].Atendente__c == event.detail.value) {
                        itemCanal = this.listPeriodoTrabalho.data[i].Atendente__r.RelatedRecord.CANAL__c;
                        break;
                    }
                }
            }
            else {
                itemCanal = this.canal;
            }

            const rtis = this.objectLeadInfo.data.recordTypeInfos;
            let idPessoaFisicaRN = Object.keys(rtis).find(rti => rtis[rti].name === 'Pessoa Física RN');
            let idMedicoCooperado = Object.keys(rtis).find(rti => rtis[rti].name === 'Médico Cooperado');

            console.log('Ids teste');
            console.log(rtis);
            console.log(idPessoaFisicaRN);
            console.log(idMedicoCooperado);
            console.log(itemCanal == 'LOJAS AUTORIZADAS');
            console.log(this.recordTypeId.value == idPessoaFisicaRN || this.recordTypeId.value == idMedicoCooperado);

            if (itemCanal == 'LOJAS AUTORIZADAS' && (this.recordTypeId.value == idPessoaFisicaRN || this.recordTypeId.value == idMedicoCooperado)) {
                console.log('Entrou no erro');
                this.serviceResourceId = event.detail.value;
                this.notificationWarning('Leads com o tipo de registro Pessoa Física RN ou Médico Cooperado não podem ser direcionados para lojas autorizadas.');
                this.reloadedBlackList();
                this.serviceResourceId = null;
            }
            else {
                console.log('Não entrou no erro');
                if (this.atendenteCallCenter) {
                    this.serviceResourceId = event.detail.value;
                    this.serviceResourceName = event.detail.value;
                }
                else {
                    this.serviceResourceName = event.detail.value;
                }
                console.log(this.serviceResourceName);
            }
        }
    }

    handleText(event) {
        this.additionalInfo = event.detail.value;
    }

    @track scheDateAtual;

    handleDateTime(event) {
        console.log('scheDate');
        console.log(this.scheDate);
        refreshApex(this.listPeriodoTrabalho)
        if (this.atendenteCallCenter && !this.reschedule) {
            this.selecionarAlocacaoAtendenteCallCenter(this.atendenteCallCenter);
        }
        if (event.detail.value != null) {
            console.log('Entrou if 1');
            this.scheDateAtual = event.detail.value;
        }
        if (this.atendenteCallCenter && this.scheTime != null) {
            console.log('Teste ScheTime');
            this.getAtendenteDisponivelHorario(this.scheTime);
        }
        if (event.detail.value != null) {
            console.log('Entrou if 3');
            this.getNotAvailableDate(event.detail.value);
        }
    }


    handleTime(event) {
        refreshApex(this.listPeriodoTrabalho)
        if (this.atendenteCallCenter && !this.reschedule) {
            this.selecionarAlocacaoAtendenteCallCenter(this.atendenteCallCenter);
        }
        console.log(this.dateList);
        this.scheTime = event.detail.value;
        console.log(this.scheTime);
        console.log(this.scheTime);
        if (this.atendenteCallCenter && this.scheTime != null && this.scheDateAtual != null) {
            this.getAtendenteDisponivelHorario(this.scheTime);
        }
    }

    refreshPage(event) {
        this.blackList = [];
        this.atendenteCallCenter = false
        this.clearFields();
        refreshApex(this.li);
        refreshApex(this.listPeriodoTrabalho);
    }

    getAtendenteDisponivelHorario(time) {
        var optArray = [];
        var hrEntrada;
        var hrSaida;
        var idsUsandoHorario = [];

        var horaMinuto = this.getHourAndMinute(time);

        verificarHorarioOcupado({
            scheDate: this.scheDateAtual,
            scheHour: horaMinuto.hour,
            scheMin: horaMinuto.min
        })
            .then(result => {

                idsUsandoHorario = result;

                for (var i in this.listPeriodoTrabalho.data) {
                    hrEntrada = this.msToTime(this.listPeriodoTrabalho.data[i].PeriodoTrabalho__r.HoraEntrada__c);
                    hrSaida = this.msToTime(this.listPeriodoTrabalho.data[i].PeriodoTrabalho__r.HoraSaida__c);


                    var idResposta = idsUsandoHorario.find(valor => this.listPeriodoTrabalho.data[i].Atendente__r.Id === valor);
                    var verificaBlacklist = this.blackList.find(valor => this.listPeriodoTrabalho.data[i].Atendente__r.Id === valor)

                    if (hrEntrada <= time && time <= hrSaida && !idResposta && !verificaBlacklist && !this.reschedule) {
                        let stringLabel = this.listPeriodoTrabalho.data[i].Atendente__r.Name + ' (' + this.listPeriodoTrabalho.data[i].Atendente__r.RelatedRecord.CANAL__c + ')';

                        optArray.push({
                            label: stringLabel,
                            value: this.listPeriodoTrabalho.data[i].Atendente__r.Id
                        });

                        break;
                    }
                    else if (hrEntrada <= time && time <= hrSaida && !idResposta && !verificaBlacklist && this.reschedule) {
                        if (this.listPeriodoTrabalho.data[i].Atendente__c == this.serviceResourceId) {

                            optArray.push({
                                label: this.listPeriodoTrabalho.data[i].Atendente__r.Name,
                                value: this.listPeriodoTrabalho.data[i].Atendente__r.Id
                            });

                            break;
                        }
                    }
                }

                if (optArray.length != 0) {
                    this.consult = optArray;
                    this.serviceResourceId = optArray[0].value;
                }

                if (optArray.length == 0 && !this.reschedule) {
                    this.notificationError('Não foi encontrado um atendente disponível para ser atribuído.');
                    this.clearFields();
                }
                else if (optArray.length == 0 && this.reschedule) {
                    this.notificationWarning('Esse horário não se encontra disponível para ser atribuído a esse atendente.');
                    //this.consult = this.oldConsult;
                    this.clearFields();
                }

            })

    }

    msToTime(s) {
        let ms = s % 1000;
        s = (s - ms) / 1000;
        let secs = s % 60;
        s = (s - secs) / 60;
        let mins = s % 60;
        let hrs = (s - mins) / 60;
        hrs = hrs < 10 ? '0' + hrs : hrs;
        mins = mins < 10 ? '0' + mins : mins;
        console.log(hrs + ':' + mins + ':00.000');
        return hrs + ':' + mins + ':00.000';
    }

    //método sendo criado
    handleChangeAtendenteCallCenter(event) {
        this.clearFields();
        refreshApex(this.li);
        refreshApex(this.listPeriodoTrabalho);
        this.atendenteCallCenter = event.detail.checked;
        var verificaItemNaLista = this.listPeriodoTrabalho.data.find(valor => this.consult[0].Id === valor.Id);
        console.log('resposta teste');
        console.log(this.serviceResourceId);
        console.log(verificaItemNaLista);
        if (this.atendenteCallCenter && !this.reschedule) {
            this.selecionarAlocacaoAtendenteCallCenter(event.detail.checked)
        }
        if (!this.atendenteCallCenter && !this.reschedule) {
            this.consult = this.oldConsult;
        }
    }

    selecionarAlocacaoAtendenteCallCenter(booleanAtendenteCallCenter) {
        if (booleanAtendenteCallCenter) {
            if (this.listPeriodoTrabalho.data) {
                console.log('this.listPeriodoTrabalho.data');
                console.log(this.listPeriodoTrabalho.data);
                if (this.oldConsult == null) {
                    this.oldConsult = this.consult;
                }

                this.contadorMarcadoOld = 0;

                var optArray = [];
                for (var i in this.listPeriodoTrabalho.data) {

                    if (this.listPeriodoTrabalho.data[i].AtendimentoMarcado__c) {
                        this.contadorMarcadoOld++;
                    }

                    var verificaBlacklist = this.blackList.find(valor => this.listPeriodoTrabalho.data[i].Atendente__r.Id === valor);

                    if (optArray.length == 0 && !verificaBlacklist) {
                        console.log(this.listPeriodoTrabalho.data[i].Atendente__r.Name);
                        let stringLabel = this.listPeriodoTrabalho.data[i].Atendente__r.Name + ' (' +
                            this.listPeriodoTrabalho.data[i].Atendente__r.RelatedRecord.CANAL__c + ')';

                        optArray.push({
                            label: stringLabel,
                            value: this.listPeriodoTrabalho.data[i].Atendente__r.Id
                        });

                    }
                    if (this.primeiroHorario == null && this.ultimoHorario == null) {
                        this.primeiroHorario = this.msToTime(this.listPeriodoTrabalho.data[i].PeriodoTrabalho__r.HoraEntrada__c) + 'Z';
                        this.ultimoHorario = this.msToTime(this.listPeriodoTrabalho.data[i].PeriodoTrabalho__r.HoraSaida__c) + 'Z';
                        console.log(this.primeiroHorario);
                        console.log(this.ultimoHorario);
                    }
                    else {
                        if (this.primeiroHorario > this.msToTime(this.listPeriodoTrabalho.data[i].PeriodoTrabalho__r.HoraEntrada__c)) {
                            this.primeiroHorario = this.msToTime(this.listPeriodoTrabalho.data[i].PeriodoTrabalho__r.HoraEntrada__c) + 'Z';
                            console.log(this.primeiroHorario);
                        }
                        if (this.ultimoHorario < this.msToTime(this.listPeriodoTrabalho.data[i].PeriodoTrabalho__r.HoraSaida__c)) {
                            this.ultimoHorario = this.msToTime(this.listPeriodoTrabalho.data[i].PeriodoTrabalho__r.HoraSaida__c) + 'Z';
                            console.log(this.ultimoHorario);
                        }
                    }
                }
                this.consult = optArray;

                if (optArray.length == 0) {
                    this.notificationError('Não foi encontrado um atendente disponível para ser atribuído.');
                }

                console.log(optArray);
                console.log(this.consult);

            }
            else if (this.listPeriodoTrabalho.error != null) {
                console.log('Erros >> ');
                console.log(this.listPeriodoTrabalho.error);
            }
        }
        else {
            this.consult = this.oldConsult;
        }
        console.log(this.consult);
    }

    //Combobox - Atendente
    @track optionsAtendente;
    @track valueAtendente;
    @track primeiroHorario;
    @track ultimoHorario;

    @wire(getPicklistValues, { recordTypeId: '$objectServiceAppointmentInfo.data.defaultRecordTypeId', fieldApiName: ATENDENTE })
    wiredAtendente(value) {
        console.log('ATENDENTE');
        if (value.data) {
            // console.log(value.data.controllerValues);
            console.log(value.data.values);
            var array = [];
            for (var i in value.data.values) {
                array.push({ value: value.data.values[i].value, label: value.data.values[i].label });
            }
            this.optionsAtendente = array;
            //  console.log(this.motivoCancelamentoValues);
        }
    }

    @wire(getHorariosComerciais)
    listPeriodoTrabalho;

    handleChangeAtendente(event) {
        this.valueAtendente = event.detail.value;
        // console.log(this.valueAtendente);
    }
    //END - Combobox - Atendente

    handleSaveButton(event) {

        var contadorMarcadoNew = 0;
        refreshApex(this.listPeriodoTrabalho);

        for (var i in this.listPeriodoTrabalho.data) {
            if (this.listPeriodoTrabalho.data[i].AtendimentoMarcado__c) {
                contadorMarcadoNew++;
            }
        }

        console.log(contadorMarcadoNew);
        console.log(this.contadorMarcadoOld);

        if (contadorMarcadoNew != this.contadorMarcadoOld && this.atendenteCallCenter) {
            this.notificationWarning('Os registros de marcações de atendentes do call center estavam desatualizados, a lista foi devidamente atualizada.');
            refreshApex(this.listPeriodoTrabalho);
            this.selecionarAlocacaoAtendenteCallCenter(this.atendenteCallCenter);
            this.clearFields();
        }
        else if (this.serviceResourceName == null) {
            this.notificationError('Necessário informar o consultor');
        } else if (this.scheDate == null) {
            this.notificationError('Favor escolher a Data de agendamento');
        } else if (this.scheTime == null) {
            this.notificationError('Favor escolher o horário de agendamento');
        } else {
            this.scheduleSave();
        }

    }

    @track loaded = false;

    getHourAndMinute(time) {
        let newScheTime;

        if (this.atendenteCallCenter) {
            newScheTime = { hour: time.substr(0, 2), min: time.substr(3).substr(0, 2) };
        }
        else {
            newScheTime = { hour: time, min: '0' };
        }

        console.log(newScheTime);

        return newScheTime;
    }

    scheduleSave() {

        let historico = 'getTerritoryInfo: <BR>' + JSON.stringify(this.loadInfo);

        console.log('scheduleSave');
        console.log(this.scheTime);

        let newScheTime = this.getHourAndMinute(this.scheTime);

        this.loaded = true;
        saveSchedule({
            leadId: this.recordId,
            resourceId: this.serviceResourceId,
            serviceTerritoryId: this.serviceTerritoryId,
            scheDate: this.scheDate,
            scheTimeHour: newScheTime.hour,
            scheTimeMin: newScheTime.min,
            description: this.additionalInfo,
            atendente: this.valueAtendente,
            AtendenteCallCenter: this.atendenteCallCenter,
            historico: historico
        }).then(result => {
            console.log(result);
            console.log('result');
            if (result) {
                console.log(result);
                if (result.response) {
                    this.loaded = false;

                    if (this.atendenteCallCenter) {
                        var listaIds = [];
                        var listaIdsMarcados = [];

                        for (var item in this.listPeriodoTrabalho.data) {
                            if (this.listPeriodoTrabalho.data[item].Atendente__c == this.serviceResourceId) {
                                listaIds.push(this.listPeriodoTrabalho.data[item].Id);
                            }
                            if (this.listPeriodoTrabalho.data[item].AtendimentoMarcado__c == true) {
                                listaIdsMarcados.push(this.listPeriodoTrabalho.data[item].Id);
                            }
                        }

                        console.log('lista Ids');
                        console.log(listaIds);
                        console.log('listaIdsMarcados');
                        console.log(listaIdsMarcados);
                        if (listaIdsMarcados.length == this.listPeriodoTrabalho.data.length) {
                            this.atualizarHorariosComerciais(listaIdsMarcados, listaIds[0]);
                        }
                        else {
                            this.atualizarHorariosComerciais(listaIds, listaIds[0]);
                        }
                    }

                    this.notificationSuccess('Agendamento criado com sucesso');
                    refreshApex(this.li);

                } else {
                    this.loaded = false;
                    console.log('Erro salvando');
                    console.log(result.message);
                    this.notificationError(result.message);
                    refreshApex(this.li);
                }

            } else {
                this.loaded = false;
                this.notificationError('Problema em executar a ação');
            }
        });

    }

    atualizarHorariosComerciais(listaIds, idMarcado) {
        // let list;
        // for(var item in this.listPeriodoTrabalho){
        //     list.add('{ "attributes": { "type": "PeriodoTrabalhoAtendente__c" }, ' + JSON.stringify(item) + '}')
        // }
        // console.log('Teste lista');
        // console.log(this.listPeriodoTrabalho);
        console.log('listaIdsAtualizarHorarios');
        console.log(listaIds);
        console.log('idMarcado');
        console.log(idMarcado);
        updateHorariosComerciais({ listaAtendentes: this.listPeriodoTrabalho.data, listaIds: listaIds, idMarcado: idMarcado })
            .then(result => {
                console.log('log de acesso criado');
            })
            .catch(error => {
                console.log(error);
            });
    }



    @track scheduleOptions;
    scheOp;

    getNotAvailableDate(date) {
        console.log('getNotAvailableDate');
        notAvailableDate({
            serviceResourceId: this.serviceResourceId,
            dt: date,
            serviceTerritoryId: this.serviceTerritoryId
        }).then(result => {
            this.scheOp = result;
            console.log(result);
            console.log('result available date');
            if (result) {
                //sthis.scheduleOptions = result;
                this.scheduleOptions = [];
                for (var dt in result) {
                    this.scheduleOptions.push({ label: result[dt], value: result[dt].substr(0, 2) });
                }
                this.dateList = result;
                this.listLength = this.dateList.length;
                if (this.dateList.length > 0) {
                    this.scheDate = date;
                } else {
                    this.notificationWarning('Consultor não disponível para este dia. Selecione o próximo consultor.');
                    this.scheDate = null;
                    this.reloadedBlackList();
                }
            } else {
                this.notificationError('Problema em executar a ação');
            }
            refreshApex(this.scheOp);
        });
    }

    reloadedBlackList() {
        var list = [];
        for (var id of this.blackList) {
            list.push(id);
        }
        list.push(this.serviceResourceId);
        this.blackList = list;

        this.clearFields();
        this.atendenteCallCenter = false;
    }

    getNotAvailableTime() {
        console.log('getNotAvailableTime');
        notAvailableTime({
            serviceResId: this.serviceResourceId,
            dt: this.scheDate
        }).then(result => {
            console.log(result);
            console.log('result available time');
            if (result) {
                this.timeList = result;
            } else {
                this.notificationError('Problema em executar a ação');
            }
        });
    }

    notificationError(mensagem) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Erro!',
                message: mensagem,
                variant: 'error',
            }),
        );
    }

    notificationWarning(mensagem) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Atenção!',
                message: mensagem,
                variant: 'warning',
            }),
        );
    }

    notificationSuccess(mensagem) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Sucesso!',
                message: mensagem,
                variant: 'success',
            }),
        );
        console.log('mensagem de sucesso');
    }


    clearFields() {
        const se_consultor = this.template.querySelector('.selecione-consultor');
        if (typeof se_consultor != undefined && se_consultor != null) {
            se_consultor.value = null;
        }

        const se_data = this.template.querySelector('.selecione-data');
        if (typeof se_data != undefined && se_data != null) {
            se_data.value = null;
        }

        const se_horario = this.template.querySelector('.selecione-horario');
        if (typeof se_horario != undefined && se_horario != null) {
            se_horario.value = null
        }

        this.serviceResourceId = null;
        this.serviceResourceName = null;
        this.scheDate = null;
        this.scheDateAtual = null;
        this.scheTime = null;

    }

    //Reagendamento
    @track optionRescheduled;

    showHideModalReschedule() {

        for (var item in this.listPeriodoTrabalho.data) {
            if (this.listPeriodoTrabalho.data[item].Atendente__c == this.serviceResourceId && this.atendenteCallCenter) {
                this.primeiroHorario = this.msToTime(this.listPeriodoTrabalho.data[item].PeriodoTrabalho__r.HoraEntrada__c) + 'Z'
                this.ultimoHorario = this.msToTime(this.listPeriodoTrabalho.data[item].PeriodoTrabalho__r.HoraSaida__c) + 'Z'
            }
        }

        const dareDevil = this.template.querySelector('.modal-reschedule.slds-modal');
        const spiderMan = this.template.querySelector('.modal-reschedule.slds-backdrop');

        this.reschedule = !this.reschedule;

        dareDevil.classList.toggle('slds-fade-in-open');
        spiderMan.classList.toggle('slds-backdrop_open');
    }

    handleRescheduleReason(event) {
        this.optionRescheduled = event.detail.value;
        console.log(this.optionRescheduled);
    }

    handleReSaveButton(event) {
        refreshApex(this.listPeriodoTrabalho);
        if (this.optionRescheduled == null) {
            this.notificationError('Necessário informar o motivo do reagendamento');
        } else if (this.scheDate == null) {
            this.notificationError('Favor escolher a Data de reagendamento');
        } else if (this.scheTime == null) {
            this.notificationError('Favor escolher o horário de reagendamento');
        } else {
            this.isHidden = false;
            //document.getElementById("resButton").style.visibility = "hidden";
            this.rescheduleSave();
        }

        console.log('valor reschedule');
        console.log(this.reschedule);
    }

    @track isHidden = true;
    @track scheduleLoaded = true;

    rescheduleSave() {
        console.log('rescheduleSave');
        console.log(this.scheTime);

        let newScheTime = this.getHourAndMinute(this.scheTime);

        this.loaded = true;
        this.inProgress = true;
        this.scheduleLoaded = false;

        resaveSchedule({
            leadId: this.recordId,
            resourceId: this.serviceResourceId,
            serviceTerritoryId: this.serviceTerritoryId,
            scheDate: this.scheDate,
            scheTimeHour: newScheTime.hour,
            scheTimeMin: newScheTime.min,
            description: this.additionalInfo,
            serviceAppointmentId: this.serviceAppointmentId,
            rescheduleReason: this.optionRescheduled
        }).then(result => {
            console.log(result);
            console.log('result');
            //button.style.visibility = "hidden";
            this.scheduleLoaded = true;

            if (result) {
                console.log(result);
                if (result.response) {
                    this.notificationSuccess('Agendamento criado com sucesso');
                    this.showHideModalReschedule()
                    refreshApex(this.li);

                } else if (!result.response) {
                    this.notificationError(result.message);
                    this.inProgress = false;
                    refreshApex(this.li);
                    console.log('Erro salvando');
                    console.log(result.message);

                }

            } else {
                this.notificationError('Problema em executar a ação');
                refreshApex(this.li);
                this.showHideModalReschedule();
                this.inProgress = false;
            }
        });
        this.isHidden = true;
        this.loaded = false;
    }

    handleChangeAddress() {
        if (typeof this.li != undefined && this.li != null) {
            refreshApex(this.li);
        }
    }



    //Cancelamento
    @wire(getObjectInfo, { objectApiName: SERVICE_APPOINTMENT_OBJECT })
    objectServiceAppointmentInfo

    @track motivoCancelamentoValues;
    motivoCancelamentoControllingSubmotivoCancelamento;

    @track submotivoCancelamentoValues;

    @track motivoCancelamentoSelected;
    @track submotivoCancelamentoSelected;

    @track cancelLoaded = true;

    @wire(getPicklistValues, { recordTypeId: '$objectServiceAppointmentInfo.data.defaultRecordTypeId', fieldApiName: MOTIVO_CANCELAMENTO })
    wiredMotivoCancelamento(value) {
        // console.log('MOTIVO DE CANCELAMENTO');
        if (value.data) {
            // console.log(value.data.controllerValues);
            //console.log(value.data.values);
            var array = [];
            for (var i in value.data.values) {
                array.push({ value: value.data.values[i].value, label: value.data.values[i].label });
            }
            this.motivoCancelamentoValues = array;
            //  console.log(this.motivoCancelamentoValues);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectServiceAppointmentInfo.data.defaultRecordTypeId', fieldApiName: SUBMOTIVO_CANCELAMENTO })
    wiredSubmotivoCancelamento(value) {
        // console.log('SUBMOTIVO DE CANCELAMENTO');
        if (value.data) {

            var controlling = [];
            var array;
            for (var i in value.data.controllerValues) {
                array = [];
                //console.log(i + ' - ' + value.data.controllerValues[i])
                for (var j in value.data.values) {
                    if (this.findValueInArray(value.data.values[j].validFor, value.data.controllerValues[i])) {
                        array.push({ value: value.data.values[j].value, label: value.data.values[j].label });
                    }
                }
                controlling[i] = array;
            }
            // console.log(controlling);
            this.motivoCancelamentoControllingSubmotivoCancelamento = controlling;
            // console.log(this.motivoCancelamentoControllingSubmotivoCancelamento);
        }
    }

    findValueInArray = (data, value) => {
        return data.find(o => o === value) !== undefined;
    }

    handleOnChangeMotivoCancelamento(event) {
        this.motivoCancelamentoSelected = event.target.value;
        this.submotivoCancelamentoValues = this.motivoCancelamentoControllingSubmotivoCancelamento[event.target.value];
        this.submotivoCancelamentoSelected = null;

        const combobox = this.template.querySelector('.submotivo-cancelamento-combobox');
        if (typeof this.submotivoCancelamentoValues != undefined && this.submotivoCancelamentoValues.length > 0) {
            combobox.disabled = false;
        } else {
            combobox.disabled = true;
        }

        this.setValidationMotivoCancelamento(null);
    }

    handleOnChangeSubmotivoCancelamento(event) {
        this.submotivoCancelamentoSelected = event.target.value;
        this.setValidationSubmotivoCancelamento(null);
    }


    showHideModalCancel() {

        const dareDevil = this.template.querySelector('.modal-cancel.slds-modal');
        const spiderMan = this.template.querySelector('.modal-cancel.slds-backdrop');

        dareDevil.classList.toggle('slds-fade-in-open');
        spiderMan.classList.toggle('slds-backdrop_open');

        this.atendenteCallCenter = false;
        this.clearFieldsModalCancel();
    }

    handleSaveCancelButton() {

        const comboboxSubmotivo = this.template.querySelector('.submotivo-cancelamento-combobox');

        if (typeof this.motivoCancelamentoSelected == undefined || this.motivoCancelamentoSelected == null) {
            this.setValidationMotivoCancelamento('Selecione um motivo.');
            return
        }

        if (comboboxSubmotivo.disabled == false && (typeof this.submotivoCancelamentoSelected == undefined || this.submotivoCancelamentoSelected == null)) {
            this.setValidationSubmotivoCancelamento('Selecione um submotivo.');
            return;
        }
        this.cancelLoaded = false;
        cancelSchedule({ serviceAppointmentId: this.serviceAppointmentId, motivo: this.motivoCancelamentoSelected, submotivo: this.submotivoCancelamentoSelected })
            .then(() => {
                this.cancelLoaded = true;
                this.notificationSuccess('Agendamento cancelado com sucesso!');
                this.showHideModalCancel();
                refreshApex(this.li);
                refreshApex(this.listPeriodoTrabalho);
            })
            .catch(err => {
                console.error(JSON.parse(JSON.stringify(err)));
                this.cancelLoaded = true;
                this.notificationError('Houve um problema durante o cancelamento, utilize a forma tradicional pela guia "Relacionado".');
                this.showHideModalCancel();
                refreshApex(this.li);
            })
    }

    setValidationMotivoCancelamento(message) {
        const comboboxMotivo = this.template.querySelector('.motivo-cancelamento-combobox');
        comboboxMotivo.setCustomValidity(message);
        comboboxMotivo.showHelpMessageIfInvalid();
    }

    setValidationSubmotivoCancelamento(message) {
        const comboboxSubmotivo = this.template.querySelector('.submotivo-cancelamento-combobox');
        comboboxSubmotivo.setCustomValidity(message);
        comboboxSubmotivo.showHelpMessageIfInvalid();
    }

    clearFieldsModalCancel() {
        this.template.querySelector('.motivo-cancelamento-combobox').value = null;
        this.template.querySelector('.submotivo-cancelamento-combobox').value = null;

        this.motivoCancelamentoSelected = null;
        this.submotivoCancelamentoSelected = null;
    }

    rendered = false
    intervalId
    renderedCallback() {
        if (!this.rendered) {
            this.rendered = true
            console.log('%crenderedCallback', 'color: green;')
            this.intervalId = setInterval(() => {
                console.log('try interval refreshApex(this.li)')
                refreshApex(this.li);
                console.log('try interval refreshApex(this.listPeriodoTrabalho);')
                refreshApex(this.listPeriodoTrabalho);;
            }, 5000);
        }

    }

    disconnectedCallback() {
        if (this.intervalId) {
            console.log('%cdisconnectedCallback', 'color: green;')
            clearTimeout(this.intervalId)
        }
    }

}