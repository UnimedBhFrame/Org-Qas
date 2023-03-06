import { LightningElement } from 'lwc';
import salvarLog from '@salesforce/apex/RastreioAcessoController.salvarLogUtility';

export default class RastreiaAcessoUtility extends LightningElement {

    url;
    intervalId;

    connectedCallback() {
        
        this.intervalId = setInterval(() => {
            let urlAtual = window.location.href;
            if (this.url !== urlAtual) {
                this.url = urlAtual
                console.log('url change >>> ' + urlAtual);
                this.tratarUrl(urlAtual);
            }
        }, 2000);
    }

    tratarUrl(url) {

        let id;
        let objeto;
        let urlArray = url.split('/');
        let registro = false;
        
        if (url.includes('view')) {
            id = urlArray[6];
            objeto = urlArray[5];
            registro = true;
        }
        else if (url.includes('list?')) {
            let list = urlArray[6];
            id = list.split('filterName=')[1];
            objeto = 'Modo de exibição de lista (' + urlArray[5] + ')';
        }
        else if (url.includes('lightning/n')) {
            id = urlArray[5];
            objeto = 'Página Lightning';
        }
        console.log('id >>> ' + id);
        console.log('objeto >>> ' + objeto);

        if (id) {
            salvarLog({identificador: id, objeto: objeto, registro: registro})
            .then(result => {
                console.log('log de acesso criado');
            })
            .catch(error => {
                console.log(error);
        });
        }
    }

    disconnectedCallback() {
        
        clearInterval(this.intervalId);
        console.log('clear interval rastreio');
    }
}