import { LightningElement, track, wire, api } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';
import USER_PROFILE from '@salesforce/schema/User.Profile.Name';
import USER_ROLE from '@salesforce/schema/User.UserRole.DeveloperName';

import SERVICE_APPOINTMENT_OBJECT from '@salesforce/schema/ServiceAppointment';
import MOTIVO_REAGENDAMENTO from '@salesforce/schema/ServiceAppointment.MotivoReagendamento__c';
import MOTIVO_CANCELAMENTO from '@salesforce/schema/ServiceAppointment.MotivoCancelamento__c';
import SUBMOTIVO_CANCELAMENTO from '@salesforce/schema/ServiceAppointment.SubMotivoCancelamento__c';

import hasAccess from '@salesforce/apex/gestaoAgendamentosController.hasAccess';
import getTerritoryInfo from '@salesforce/apex/gestaoAgendamentosController.getTerritoryInfo';
import getAvailableSchedule from '@salesforce/apex/gestaoAgendamentosController.getAvailableSchedule';
import getApp from '@salesforce/apex/gestaoAgendamentosController.getApp';


import saveSchedule from '@salesforce/apex/gestaoAgendamentosController.saveSchedule';
import saveReschedule from '@salesforce/apex/gestaoAgendamentosController.saveReschedule';
import doCancelSchedule from '@salesforce/apex/gestaoAgendamentosController.cancelSchedule';

export default class ScheduleComponent extends LightningElement {
    @api recordId;

    userId = USER_ID;
    loaded = false;
    loadedRes = false;
    loadedCanc = false;
    territoryInfo;
    errorMessage;
    responsibleConsultant;
    scheDate;
    scheduleOptions;
    serviceAppointmentId;
    serviceTerritoryId;
    permissionError = "Você não possui permissão para acessar o componente de agendamento";
    hours = [];

    //Component visibility validations
    hasAccess = false;
    agendamentoForm = true;
    cancelScheduleModal = false;
    rescheduleModal = false;

    //Record validations
    hasAddress = true;
    availableCity = true;
    hasSchedule = false;
    riskStatus = false;

    //Service appointment variables
    resourceName;
    scheduledDate
    selectedDate;
    selectedTime;
    additionalInfo;
    //isDisabled = true;

    // -- Reschedule process -- //
    motivoReagendamentoValues;
    motivoReagendamentoSelected;
    optionRescheduled;

    // -- Cancellation variables -- //
    motivoCancelamentoControllingSubmotivoCancelamento;
    motivoCancelamentoValues;
    submotivoCancelamentoValues;
    motivoCancelamentoSelected;
    submotivoCancelamentoSelected;

    dateval
    get dateValue() {
        if (this.dateval == undefined) {
            this.dateval = new Date().toISOString().substring(0, 10);
        }

        return this.dateval;
    }

    get isDisabled() {
        var valid = true;
        if (this.selectedDate != null) {
            valid = false;
        }

        return valid;
    }

    connectedCallback() {
        this.checkPermissions();
    }

    @wire(getObjectInfo, { objectApiName: SERVICE_APPOINTMENT_OBJECT })
    objectServiceAppointmentInfo

    @wire(getRecord, { recordId: USER_ID, fields: [USER_PROFILE, USER_ROLE, USER_NAME] })
    userDetails({ error, data }) {
        if (data) {
            this.checkPermissions();

            this.responsibleConsultant = data.fields.Name.value;
        }
    }

    checkPermissions() {
        hasAccess({ id: this.userId })
            .then(data => {
                this.hasAccess = data;
            })
            .finally(() => {
                if (this.hasAccess) {
                    this.checkTerritoryInfo();
                }
            })
    }

    checkTerritoryInfo() {
        getTerritoryInfo({ corretoraId: this.recordId, resourceId: this.userId })
            .then(data => {
                this.territoryInfo = data;
                console.log(this.territoryInfo);

                if (this.territoryInfo.leadAddress) {
                    if (this.territoryInfo.availableCities) {
                        if (this.territoryInfo.isScheduled == false) {
                            if (this.territoryInfo.addressExist == true) {
                                if (this.territoryInfo.bothDificult) {
                                    this.riskStatus = true
                                    this.agendamentoForm = false;
                                    this.riskMessage = 'Área de risco e local de difícil acesso';
                                } else if (this.territoryInfo.dificultTerrain) {
                                    this.riskStatus = true
                                    this.agendamentoForm = false;
                                    this.riskMessage = 'Local de difícil acesso';
                                } else if (this.territoryInfo.territoryRisk) {
                                    this.riskStatus = true
                                    this.agendamentoForm = false;
                                    this.riskMessage = 'Área de risco';
                                } else {
                                    if (this.territoryInfo.success) {
                                        this.agendamentoForm = true;
                                    } else {
                                        this.agendamentoForm = false;
                                        this.errorMessage = 'Erro desconhecido';
                                    }
                                }
                            }
                        } else {
                            this.serviceAppointmentId = this.territoryInfo.serviceAppointmentId;
                            this.resourceName = this.territoryInfo.resourceName;
                            this.scheduledDate = this.convertDateToUTC(this.territoryInfo.visitDate);
                            this.isScheduled = true;
                            this.agendamentoForm = false;
                        }
                    } else {
                        this.availableCity = false;
                        this.agendamentoForm = false;
                        this.errorMessage = 'Esta região não se encontra cadastrada no sistema. Encaminhe os dados do cliente para seu supervisor e informe que receberá um retorno';
                    }
                } else {
                    this.hasAddress = false;
                    this.agendamentoForm = false;
                    this.errorMessage = 'Endereço está incompleto, por favor, preencha o cadastro utilizando o componente de CEP abaixo e tente novamente'
                }
            })
            .finally(() => {
                //CODE
            })
    }

    convertDateToUTC(dateString) {
        dateString = new Date(dateString).toUTCString();
        dateString = dateString.split(' ').slice(0, 5).join(' ');

        return dateString;
    }

    handleDateTime(event) {
        console.log('Entrou: ' + event.detail.value);
        this.selectedDate = event.detail.value;
        //eval("$A.get('e.force:refreshView').fire();");
        this.getSchedules();
    }

    handleTime(event) {
        this.selectedTime = event.detail.value;
    }

    handleAddInfo(event) {
        this.additionalInfo = event.target.value;
    }

    getSchedules() {
        this.getScheduledAppointments();

        getAvailableSchedule({ selectedDate: this.selectedDate, corretoraId: this.recordId, resourceId: this.userId })
            .then(data => {
                this.scheduleOptions = [];

                for (var dt in data) {
                    this.scheduleOptions.push({ label: data[dt], value: data[dt].substr(0, 2) });
                }
            })
            .catch(error => {
                console.log('Erro: ' + JSON.stringify(error));
            })
    }

    getScheduledAppointments() {
        getApp({ corretoraId: this.recordId, resourceId: this.userId, scheDate: this.selectedDate, scheTime: this.selectedTime })
            .then(result => {
                this.hasSchedule = true;
                this.hours = result;
            })
            .catch(error => {
                console.log('Erro: ' + JSON.stringify(error));
            })
    }

    scheduleSave(event) {
        event.preventDefault();

        if (this.validateRequired()) {
            this.loaded = true;

            saveSchedule({ corretoraId: this.recordId, resourceId: this.userId, serviceTerritoryId: this.serviceTerritoryId, scheDate: this.selectedDate, scheTime: this.selectedTime, description: this.additionalInfo })
                .then(data => {
                    var obj = data;
                    this.scheduledDate = this.convertDateToUTC(obj.newScheduledDate);
                    this.loaded = false;
                    this.showMessage({ title: 'Agendamento realizado com sucesso' });
                })
                .catch(error => {
                    console.log('Erro: ' + JSON.stringify(error));
                })
                .finally(() => {
                    this.agendamentoForm = false;
                    this.isScheduled = true; //criar um wire pra puxar os appointments e dar um refresh aqui
                })
        }
    }

    // -- Reschedule process -- //
    @wire(getPicklistValues, { recordTypeId: '$objectServiceAppointmentInfo.data.defaultRecordTypeId', fieldApiName: MOTIVO_REAGENDAMENTO })
    wiredMotivoReagendamento(value) {
        if (value.data) {
            var array = [];
            for (var i in value.data.values) {
                array.push({ value: value.data.values[i].value, label: value.data.values[i].label });
            }
            this.motivoReagendamentoValues = array;
        }
    }

    handleRescheduleReason(event) {
        this.optionRescheduled = event.detail.value;
    }

    rescheduleSave(event) {
        event.preventDefault();

        if (this.validateRequired()) {
            this.loadedRes = true;

            saveReschedule({ scheDate: this.selectedDate, scheTime: this.selectedTime, description: this.additionalInfo, serviceAppointmentId: this.serviceAppointmentId, rescheduleReason: this.optionRescheduled })
                .then(data => {
                    var obj = data;
                    this.scheduledDate = this.convertDateToUTC(obj.newScheduledDate);
                    this.hideRescheduleModal();
                    this.showMessage({ title: 'Reagendamento realizado com sucesso' });
                })
                .catch(error => {
                    console.log('Erro: ' + JSON.stringify(error));
                })
                .finally(() => {
                    setTimeout(() => {
                        eval("$A.get('e.force:refreshView').fire();");
                    }, 1000);
                })
        }
    }

    showRescheduleModal() {
        this.rescheduleModal = true;
    }

    hideRescheduleModal() {
        this.loadedRes = false;
        this.rescheduleModal = false;
    }

    // -- Cancellation process -- //
    @wire(getPicklistValues, { recordTypeId: '$objectServiceAppointmentInfo.data.defaultRecordTypeId', fieldApiName: MOTIVO_CANCELAMENTO })
    wiredMotivoCancelamento(value) {
        if (value.data) {
            var array = [];
            for (var i in value.data.values) {
                array.push({ value: value.data.values[i].value, label: value.data.values[i].label });
            }
            this.motivoCancelamentoValues = array;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectServiceAppointmentInfo.data.defaultRecordTypeId', fieldApiName: SUBMOTIVO_CANCELAMENTO })
    wiredSubmotivoCancelamento(value) {
        if (value.data) {

            var controlling = [];
            var array;
            for (var i in value.data.controllerValues) {
                array = [];
                for (var j in value.data.values) {
                    if (this.findValueInArray(value.data.values[j].validFor, value.data.controllerValues[i])) {
                        array.push({ value: value.data.values[j].value, label: value.data.values[j].label });
                    }
                }
                controlling[i] = array;
            }
            this.motivoCancelamentoControllingSubmotivoCancelamento = controlling;
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
    }

    handleOnChangeSubmotivoCancelamento(event) {
        this.submotivoCancelamentoSelected = event.target.value;
    }

    cancelSchedule(event) {
        event.preventDefault();

        if (this.validateRequired()) {
            this.loadedCanc = true;

            doCancelSchedule({ serviceAppointmentId: this.serviceAppointmentId, motivo: this.motivoCancelamentoSelected, submotivo: this.submotivoCancelamentoSelected })
                .then(() => {
                    this.hideCancelModal();
                    this.showMessage({ title: 'Agendamento cancelado com sucesso!', variant: 'success' });
                })
                .catch(err => {
                    this.hideCancelModal();
                    this.showMessage({ title: 'Houve um problema durante o cancelamento, utilize a forma tradicional pela guia "Relacionado".', variant: 'error' });
                })
                .finally(() => {
                    this.isScheduled = false;
                    this.agendamentoForm = true;
                })
        }
    }

    showCancelModal() {
        this.cancelScheduleModal = true;
    }

    hideCancelModal() {
        this.loadedCanc = false;
        this.cancelScheduleModal = false;
    }

    // -- Utils -- //
    showMessage({ title, message, variant = 'success' }) {
        let toastMessage = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(toastMessage);
    }

    validateRequired() {
        const allInputs = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);

        const allComboboxes = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);

        return (allInputs && allComboboxes);
    }
}