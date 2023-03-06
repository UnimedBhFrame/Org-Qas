import { LightningElement, track, wire } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';

import RESOURCE from '@salesforce/resourceUrl/Leaflet';

import obtainLeads from '@salesforce/apex/MapGeographicLeadController.obtainLeads';
import obtainLegends from '@salesforce/apex/MapGeographicLeadController.obtainLegends';
import verificarFiltrosAnteriores from '@salesforce/apex/MapGeographicLeadController.verificarFiltrosAnteriores';
import salvarFiltros from '@salesforce/apex/MapGeographicLeadController.salvarFiltros';

export default class MapGeographicLead extends LightningElement {
    
    @track loaded = false;
    @track hasPermission = true;
    styleInitialized = false;
    leadValues;
    leads = [];
    map;
    mapColors = new Map();
    inicio;
    fim;
    filtroAnteriorEtapa = [];
    valueTipo = [];
    valueEtapaSelect = [];
    valueEtapa = [];
    valuePorte = [];
    valueCanalEntrada = [];
    valueTemperatura = [];
    exCliente = false;

    renderedCallback() {
        if (!this.styleInitialized)
            this.loadStyle();
    }

    connectedCallback() {
        
        verificarFiltrosAnteriores()
            .then(result => {
                let filtros = JSON.parse(result);
                console.log('filtros:');
                console.log(filtros);
                let hoje = new Date().toISOString();
                this.inicio = /*filtros.inicio ? filtros.inicio :*/ hoje.substring(0, 7) + '-01';
                this.fim = /*filtros.fim ? filtros.fim :*/ hoje.substring(0, 10);
                if (filtros.status) {
                    this.filtroAnteriorEtapa = filtros.status;
                }
                if (filtros.canalEntrada) {
                    this.valueCanalEntrada = filtros.canalEntrada;
                }
                if (filtros.exCliente) {
                    this.exCliente = filtros.exCliente;
                }
                if (filtros.tipoRegistro) {
                    this.valueTipo = filtros.tipoRegistro;
                }
                if (filtros.porte) {
                    this.valuePorte = filtros.porte;
                }
                if (filtros.rating) {
                    this.valueTemperatura = filtros.rating;
                }
            })
            .catch(error => {
                console.log(error);
            });
    }

    disconnectedCallback() {

        salvarFiltros({inicio: this.inicio, fim: this.fim, status: this.valueEtapa, canalEntrada: this.valueCanalEntrada, exCliente: this.exCliente, 
            tipoRegistro: this.valueTipo, porte: this.valuePorte, rating: this.valueTemperatura})
            .then(result => {
                console.log('filtros salvos!');
            })
            .catch(error => {
                console.log(error);
            });
    }

    /* @wire(checkPermissionMap)
     permissionWired(value){
         if(value.data){
             this.hasPermission = value.data;
         }
         if(value.error){
             console.error(JSON.stringify(value.error));
         }
     }*/

    loadStyle() {
        if (this.styleInitialized) {
            return;
        }
        Promise.all([
            loadStyle(this, RESOURCE + '/css/leaflet.css'),
            loadScript(this, RESOURCE + '/js/leaflet.js')
        ])
            .then(() => {
                console.log('%cstyleInitialized', 'color: brown;');
                setTimeout(() => {
                    this.styleInitialized = true;
                    this.initMap();
                }, 2000)


            })
            .catch(error => {
                console.error(JSON.stringify(error));
            });
    }

    
    @wire(obtainLeads, { status: '$valueEtapa', canalEntrada: '$valueCanalEntrada', exCliente: '$exCliente', tipoRegistro: '$valueTipo', porte: '$valuePorte', rating: '$valueTemperatura', inicio: '$inicio', fim: '$fim' })
    mapWired(value) {
        this.leadValues = value;
        if (value.data) {
            console.log('obtainLeads');
            console.log(value.data);
            this.leads = value.data;

            if (this.styleInitialized) {
                this.insertLeads();
            }
        }
        if (value.error) {
            console.error(JSON.stringify(value.error));
        }
    }

    initMap() {
        this.loaded = true;

        const mapRoot = this.template.querySelector(".map-root")
        this.map = L.map(mapRoot, {
            center: [-19.92043, -43.951149],
            zoom: 12
        });

        const accessToken = 'pk.eyJ1IjoiZHNlbHZhdGkiLCJhIjoiY2praGpmeWY1MHRqMjN3cWc1eGhhenpnYiJ9.BD55hAopFNbn9XCV2LXwzg';
        L.tileLayer('https://api.mapbox.com/styles/v1/dselvati/ckds67cc00nbp19msev9pw046/tiles/256/{z}/{x}/{y}@2x?access_token=' + accessToken, {
            attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
            maxZoom: 18,
            /* id: 'mapbox/streets-v11',
             tileSize: 512,
             zoomOffset: -1,*/
            accessToken: accessToken
        }).addTo(this.map);

        this.map.on('click', (e) => {
            console.log("You clicked the map at " + e.latlng);
        });

        this.insertLegend();
    }

    insertLegend() {
        obtainLegends()
            .then(result => {
                // console.log(result);
                for (var r of result) {
                    this.mapColors.set(
                        r.StatusLead__c,
                        r.Cor__c
                    )

                }
                this.putMap(result);
                this.putStage(result);
            }).catch(err => {
                console.error(JSON.stringify(err));
            })
    }

    putMap(values) {

        var legend = L.control({ position: 'topright' });

        legend.onAdd = (map) => {

            var div = L.DomUtil.create('div', 'info legend')
            /*grades = ['ProcuraAtiva', 'Atracao', 'Convertido'],
            labels = ['Procura Ativa', 'Atração', 'Convertido'];*/

            div.innerHTML += '<b>Status do Lead<b><br><br>'
            // loop through our density intervals and generate a label with a colored square for each interval
            for (var value of values) {
                div.innerHTML +=
                    '<i style="background:' + value.Cor__c + '"></i> ' +
                    value.MasterLabel + '<br>';
            }

            return div;
        };

        legend.addTo(this.map);

        this.insertLeads();
    }

    getColor(d) {
        return this.mapColors.get(d);
    }

    insertLeads() {

        this.map.eachLayer((layer) => {
            if (layer instanceof L.CircleMarker) {
                layer.remove();
            }
        });

        for (var lead of this.leads) {
            // console.log(lead);
            var circle = L.circle([parseFloat(lead.Latitude__c), parseFloat(lead.Longitude__c)], {
                color: this.getColor(lead.Status),
                fillColor: this.getColor(lead.Status),
                fillOpacity: 1,
                radius: 20
            }).addTo(this.map).bindPopup(`<a href="/${lead.Id}" target="_blank">${lead.Name}</a><br>Status: ${lead.Status}<br>Telefone: ${lead.Phone != null ? lead.Phone : ''}<br>Celular: ${lead.MobilePhone != null ? lead.MobilePhone : ''}<br>Email: ${lead.Email != null ? lead.Email : ''}<br>Latitude: ${lead.Latitude__c}<br>Longitude: ${lead.Longitude__c}`);

            //this.circles.push(circle);
        }
    }

    //Filters
    
    get optionsTipo() {
        return [
            { label: 'Medico Cooperado', value: 'MedicoCooperado' },
            { label: 'Pessoa Física', value: 'PessoaFisica' },
            { label: 'Pessoa Física RN', value: 'PessoaFisicaRN' },
            { label: 'Pessoa Jurídica', value: 'PessoaJuridica' },
        ];
    }

    handleChangeTipo(e) {
        this.valueTipo = e.detail.value;
        console.log(this.valueTipo);
    }

    handleChangeExCliente(event) {
        this.exCliente = event.target.checked;
        console.log(this.exCliente);
    }

    get optionsEtapa() {
        return this.valueEtapaSelect;
    }

    putStage(result) {
        var valueEtapaSelect = [];
        var valueEtapa = [];

        for (var r of result) {
            valueEtapaSelect.push({ label: r.StatusLead__c, value: r.StatusLead__c })
            //valueEtapa.push(r.StatusLead__c)
        }

        this.valueEtapaSelect = valueEtapaSelect;
        this.valueEtapa = this.filtroAnteriorEtapa.length > 0 ? this.filtroAnteriorEtapa : valueEtapa;
    }

    handleChangeEtapa(e) {
        this.valueEtapa = e.detail.value;
        console.log(this.valueEtapa);
    }

    get optionsPorte() {
        return [
            { label: 'Individual', value: 'Individual' },
            { label: 'PME1', value: 'PME1' },
            { label: 'PME2', value: 'PME2' },
            { label: 'ME', value: 'ME' },
            { label: 'GC', value: 'GC' },
            { label: 'CE', value: 'CE' },
        ];
    }

    handleChangePorte(e) {
        this.valuePorte = e.detail.value;
        console.log(this.valuePorte);
    }

    get optionsCanalEntrada() {
        return [
            { label: 'Atendimento Loja', value: 'Atendimento Loja' },
            { label: 'Ativo - AeC', value: 'Ativo - AeC' },
            { label: 'Blended - AeC', value: 'Blended - AeC' },
            { label: 'Mailing', value: 'Mailing' },
            { label: 'Promotor', value: 'Promotor' },
            { label: 'Prospecção', value: 'Prospecção' },
            { label: 'Receptivo - AeC', value: 'Receptivo - AeC' },
        ];
    }

    handleChangeCanalEntrada(e) {
        this.valueCanalEntrada = e.detail.value;
        console.log(this.valueCanalEntrada);
    }

    handleChangeInicio(event) {
        console.log(event.target.value);
        this.inicio = event.target.value;
    }

    handleChangeFim(event) {
        console.log(event.target.value);
        this.fim = event.target.value;
    }

    get optionsTemperatura() {
        return [
            { label: 'Frio', value: 'Frio' },
            { label: 'Morno', value: 'Morno' },
            { label: 'Quente', value: 'Quente' },
        ];
    }

    handleChangeTemperatura(e) {
        this.valueTemperatura = e.detail.value;
        console.log(this.valueTemperatura);
    }

}