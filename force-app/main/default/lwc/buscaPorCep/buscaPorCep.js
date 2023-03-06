import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';


export default class BuscaPorCep extends LightningElement {

    @api recordId;
    @api objectApiName;
    @track fields;

    @track cep;
    @track endereco;

    @api ConfigCep;
    @api ConfigRua;
    @api ConfigNumero;
    @api ConfigComplemento;
    @api ConfigBairro;
    @api ConfigCidade;
    @api ConfigEstado;
    @api ConfigPais;
    @api ConfigLatitude;
    @api ConfigLongitude;

    get searched() {
        return typeof this.endereco != undefined && this.endereco != null;
    }

   
    handleOnChange(event) {
        this.cep = event.target.value;
    }

    handleOnChangeNumero(event) {
        this.numero = event.target.value;
    }

    handleOnClick(event) {
        
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);
            
        if (allValid) {
            this.updateAddress(); 
        }

    }



    updateAddress() {
        const url = `https://viacep.com.br/ws/${this.cep}/json/`;
           
            fetch(url, {
                method: 'GET'
            })
                .then(response =>
                    response.json())
                .then(data => {
                   
                    this.endereco = data;
                    
                    const fields = {};
                                
                    fields[this.ConfigRua] = this.numero != null ? data.logradouro + ', ' + this.numero : data.logradouro;
                    fields[this.ConfigEstado] = data.uf;
                    fields[this.ConfigCidade] = data.localidade;
                    fields[this.ConfigCep] = this.cep;
                    fields[this.ConfigPais] = 'Brasil';
                    fields[this.ConfigBairro] = data.bairro;
                    fields[this.ConfigNumero] = this.numero;

                    this.update(fields);

                    var url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${data.logradouro} ${data.city} Brasil.json?access_token=pk.eyJ1IjoiZHNlbHZhdGkiLCJhIjoiY2praGpmeWY1MHRqMjN3cWc1eGhhenpnYiJ9.BD55hAopFNbn9XCV2LXwzg`;
                    url = url.replace(' ', '%20');
                    fetch(url, {
                        method: 'GET',
                    })
                        .then(response =>
                            response.json())
                        .then(coord => {
                           
                            fields[this.ConfigLatitude] = coord.features[0].center[0];
                            fields[this.ConfigLongitude] = coord.features[0].center[1];
                            this.update(fields);
                         
                        })
                        .catch(error => {
                            console.error(error);
                        })
            
                })
                .catch(error => {
                    console.error(error)
                })
    }


    update(fields) {

        fields['Id'] = this.recordId;
        const recordInput = { fields };

        
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: 'Endereço da Corretora atualizado!',
                        variant: 'success'
                    })
                );
        
                this.handleChangeAddress();
                this.handleClearField();
                return refreshApex(this.contact);
        
            })
            .catch(error => {
                console.error(JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: '',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    handleClearField() {
        const inputs = this.template.querySelectorAll('lightning-input');
        if (typeof inputs != undefined && inputs != null) {
            for (var input of inputs) {
                input.value = '';
            }
        }
    }

    handleChangeAddress() {
        this.dispatchEvent(
            new CustomEvent('changeaddress')
        );
    }
}