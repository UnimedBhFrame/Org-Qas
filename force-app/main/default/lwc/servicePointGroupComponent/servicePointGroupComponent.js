import { LightningElement, track, wire, api   } from 'lwc';

import getAbscenceTypes from '@salesforce/apex/ServicePointGroupComponentController.getAbsenceType';
import abscenceValue from '@salesforce/apex/ServicePointGroupComponentController.getResourceAbsence';
import saveAbscences from '@salesforce/apex/ServicePointGroupComponentController.saveAbscences';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

export default class ServicePointGroupComponent extends LightningElement {
    @api recordId;

    @track abscenceData;
    @track abscenceReason;
    @track abscenceTypes;
    @track options;
    @track gridOptions;
    @track startTime;
    @track endTime;
    @track activeEmptyInfo = false;
    @track description;

    columns = [
        { label: 'Id', fieldName: 'Id' },
        { label: 'Motivo', fieldName: 'Motivo' },
        { label: 'Inicio', fieldName: 'Inicio', type: 'date-local', typeAttributes:{
            month: "2-digit",
            day: "2-digit"
        } },
        { label: 'Fim', fieldName: 'Fim', type: 'date-local', typeAttributes:{
            month: "2-digit",
            day: "2-digit"
        }},
    ];

    
    @wire(getAbscenceTypes, {targetId: '$recordId'})
    wiredTypes ({error, data}){
        if(error){
            console.log('error');
            console.dir(error);
        } else if(data){        
            console.log('type');
            console.log(data);
            this.options = [];
            for (var dt in data){
                this.options.push({label: dt, value: dt});
            }
            this.abscenceTypes = this.options;
            console.log('abscenceTypes');
            console.log(this.abscenceTypes);
        }
    }
    

    @wire(abscenceValue, {targetId: '$recordId'})
    wiredCampaign ({error, data}){
        if(error){
            console.log('error');
            console.dir(error);
        } else if(data){  
            this.activeEmptyInfo = true;      
            console.log('abscence');
            console.log(data);
            if(data == null){
                this.activeEmptyInfo = false;
            }
            this.gridOptions = [];
            var absenceId = 0;
            for (var dt in data){
                absenceId = absenceId+1;
                this.gridOptions.push({Id: absenceId, Motivo: data[dt].Type, Inicio: data[dt].Start, Fim: data[dt].End});
            }
            this.abscenceData = this.gridOptions;
            console.log('abscenceData');
            console.log(this.abscenceData);
        }
    }

    handleAbscenceReason(event){
        this.abscenceReason = event.detail.value;
        console.log('handleAbscenceReason');
        console.log(this.abscenceReason);
    }

    
    dataAbscenceTypes(){
        console.log('getAbscenceTypes');
        getAbscenceTypes({
            }).then(result =>{
                console.log(result);
                console.log('result getAbscenceTypes');
                if(result){
                    this.abscenceTypes = result;
                } else {
                    console.log('Erro na função dataAbscenceTypes')
                }
            });
    }

    handleSaveButton(event){
        if(this.abscenceReason == null){
            this.notificationError('Motivo da Ausência tem que ser preenchido');
        } else if(this.startTime == null) {
            this.notificationError('Data de inicio da ausência tem que ser preenchido');
        } else if(this.endTime == null) {
            this.notificationError('Data de termino da ausência tem que ser preenchido');
        } else {
            this.saveAbscence();
        }
                
    }

    @track isHidden = true;

    saveAbscence(){
        console.log('saveAbscence');
        this.isHidden = false;
        saveAbscences({
            targetId: this.recordId,
            absReason: this.abscenceReason, 
            startTime: this.startTime, 
            endTime: this.endTime,
            description: this.description}).then(result =>{
                console.log(result);
                console.log('result');
                if(result){                    
                    console.log(result.substring(0, 4));
                    if(result.substring(0, 4) == 'ERRO'){
                        this.notificationError(result);
                    } else {
                        this.notificationSuccess(result);
                    }
                } else {
                    this.notificationError('Problema em executar a ação');
                }
                setTimeout(window.location.reload(), 50000);
                
                //eval("$A.get('e.force:refreshView').fire();");
            });
    }

    handleStartTime(event){
        this.startTime = event.detail.value;
    }

    handleEndTime(event){
        this.endTime = event.detail.value;
    }

    handleText(event){
        this.description = event.detail.value;
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

    

    
}