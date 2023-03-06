import { LightningElement, api } from 'lwc';
import salvarLog from '@salesforce/apex/RastreioAcessoController.salvarLog';

export default class RastreiaAcesso extends LightningElement {

    @api recordId;

    connectedCallback() {

        salvarLog({idRegistro: this.recordId})
            .then(result => {
                console.log('log de acesso criado');
            })
            .catch(error => {
                console.log(error);
            });
    }
}