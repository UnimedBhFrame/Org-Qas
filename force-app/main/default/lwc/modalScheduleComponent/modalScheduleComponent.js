import { LightningElement, api, wire } from 'lwc';
import permissaoCallCenter from '@salesforce/customPermission/PSAtendenteCallCenter';
import verificaMostrarModal from '@salesforce/apex/ModalScheduleComponentController.verificaMostrarModal';
import marcaCampoModal from '@salesforce/apex/ModalScheduleComponentController.preencheCampoModal'
import LEAD_CREATEDDATE from '@salesforce/schema/Lead.CreatedDate';

const camposLead = [LEAD_CREATEDDATE];

export default class ModalScheduleComponent extends LightningElement {

    @api recordId;
    mostrarModal = false;
    
    connectedCallback() {

        if (permissaoCallCenter) {
            verificaMostrarModal({ idLead: this.recordId })
                .then((result) => {
                    this.mostrarModal = result;
                })
                .catch((error) => {
                    console.log(error);
                });
        }
    }

    fecharModal() {
        marcaCampoModal({ idLead: this.recordId })
            .then((result) => {
                console.log('fechar modal');
                this.mostrarModal = false;
            })
            .catch((error) => {
                console.log(error);
                this.mostrarModal = false;
            });
    }
}