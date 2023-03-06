import { LightningElement, api, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateLead from '@salesforce/apex/SearchAddressController.updateLead';

export default class SearchAddress extends LightningElement {
    @api recordId;
    @track cep;
    @api previewAddress;
    @track number;

    handleOnChange(event) {
        this.cep = event.target.value;
    }

    number;
    handleOnChangeNumero(event) {
        this.number = event.target.value;
        console.log(this.number)
    }

    handleOnClick(event) {
        console.log(this.recordId);

        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);

        if (allValid) {

            const url = `https://viacep.com.br/ws/${this.cep}/json/`

            fetch(url, {
                method: 'GET',
            })
                .then(response =>
                    response.json())
                .then(data => {
                    console.log(data)
                    //this.updateLead(data);
                    //this.getLocation(data);
                    this.updateLead(data, null);
                })
                .catch(error => {
                    console.error(error)
                })
        }
    }

    getLocation(data) {
        var url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${data.logradouro} ${data.city} Brasil.json?access_token=pk.eyJ1IjoiZHNlbHZhdGkiLCJhIjoiY2praGpmeWY1MHRqMjN3cWc1eGhhenpnYiJ9.BD55hAopFNbn9XCV2LXwzg`;
        url = url.replace(' ', '%20');
        fetch(url, {
            method: 'GET',
        })
            .then(response =>
                response.json())
            .then(coord => {
                console.log(coord)
                this.updateLead(data, coord);
            })
            .catch(error => {
                console.error(error)
            })
    }

    @track fields;
    get searched() {
        return typeof this.fields != undefined && this.fields != null;
    }


    updateLead(data, coord) {

        // Create the recordInput object

        const fields = {};
        fields.Id = this.recordId;
        fields.Street = this.number != null ? data.logradouro + ', ' + this.number : data.logradouro;
        fields.State = data.uf;
        fields.City = data.localidade;
        fields.PostalCode = this.cep;
        fields.Country = 'Brasil';
        fields.Bairro__c = data.bairro;
        //fields.Longitude = coord.features[0].center[0];
        //fields.Latitude = coord.features[0].center[1];
        fields.Numero__c = this.number;
        fields.Complemento__c = null;

        //fields.Coordenadas__Longitude__s = coord.features[0].center[0];
        //fields.Coordenadas__Latitude__s = coord.features[0].center[1];
        this.fields = fields;

        // const recordInput = { fields };

        // updateRecord(recordInput)
        //     .then(() => {
        //         this.toast('', 'Endereço do Lead atualizado!', 'success');
        //         this.handleChangeAddress();
        //         this.handleClearField();
        //     })
        //     .catch(error => {
        //         console.error(JSON.stringify(error));
        //         this.toast('', error.body.message, 'error')
        //     });


        updateLead({ld: fields})
        .then(() => {
            this.toast('', 'Endereço do Lead atualizado!', 'success');
                this.handleChangeAddress();
                this.handleClearField();
        })
        .catch(err => {
            console.error(JSON.stringify(err));
            this.toast('', err.body.message, 'error')
        })
    }

    handleChangeAddress() {
        this.dispatchEvent(
            new CustomEvent('changeaddress')
        );
    }

    handleClearField() {
        const inputs = this.template.querySelectorAll('lightning-input');
        if (typeof inputs != undefined && inputs != null) {
            for (var input of inputs) {
                input.value = '';
            }
        }
    }

    handleOnChangeNumero(event) {
        this.number = event.detail.value;
    }

    toast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}