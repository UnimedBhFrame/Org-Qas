import { LightningElement, track, wire } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';

import RESOURCE from '@salesforce/resourceUrl/Leaflet';
import STYLE from '@salesforce/resourceUrl/MapaGeografico';

import checkPermissionMap from '@salesforce/apex/MapGeographicController.checkPermissionMap';
import obtainServiceResource from '@salesforce/apex/MapGeographicController.obtainServiceResource';
import obtainLocations from '@salesforce/apex/MapGeographicController.obtainLocations';
import obtainServiceAppointment from '@salesforce/apex/MapGeographicController.obtainServiceAppointment';
import verificarFiltrosAnteriores from '@salesforce/apex/MapGeographicController.verificarFiltrosAnteriores';
import salvarFiltros from '@salesforce/apex/MapGeographicController.salvarFiltros';


const ICON_AGENDADO = RESOURCE + '/icons/appt_agendado.png';
const ICON_ANDAMENTO = RESOURCE + '/icons/appt_andamento.png';
const ICON_CANCELADO = RESOURCE + '/icons/appt_cancelado.png';
const ICON_CONCLUIDO = RESOURCE + '/icons/appt_concluido.png';
const ICON_REAGENDADO = RESOURCE + '/icons/appt_reagendado.png';

const ICON_ONLINE = RESOURCE + '/icons/resource_online.png';
const ICON_OFFLINE = RESOURCE + '/icons/resource_offline.png';

const adjustLocations = (value) => {
    var data = JSON.parse(JSON.stringify(value));
    var array = [];

    for (var val of data) {
        array.push([
            val.Longitude__c,
            val.Latitude__c,
            val.DataLocalizacao__c
        ])
    }

    return array;
}

export default class MapGeographic extends LightningElement {

    @track loaded = false;
    @track hasPermission = false;
    styleInitialized = false;
    valuePFisica = false;
    valuePJuridica = false;
    valueTipo = []; //['Call center', 'Consultores', 'Equipe corporativa', 'Loja autorizada', 'Promotores'];
    valuePorte = []; //['PME1 e Individual', 'PME2', 'ME', 'GC', 'CE'];
    serviceTerritoryId = null;
    hoje = new Date().toISOString();
    inicio = this.hoje.substring(0, 10);
    fim = this.hoje.substring(0, 10);
    serviceResourceId;
    locationsResource;
    serviceAppointments = [];
    serviceAppointmentsCompleted = 0;
    resources = [];
    mapvalues;
    map;
    circles = [];

    renderedCallback() {
        if (!this.styleInitialized) {
            this.loadStyle();
        }
    }

    connectedCallback() {
        
        verificarFiltrosAnteriores()
            .then(result => {
                let filtros1 = JSON.parse(result[0]);
                let filtros2 = JSON.parse(result[1]);
                console.log('filtros1:');
                console.log(filtros1);
                console.log('filtros2:');
                console.log(filtros2);
                
                //let hoje = new Date().toISOString();
                //this.inicio = filtros.inicio ? filtros.inicio : hoje.substring(0, 7) + '-01';
                //this.fim = filtros.fim ? filtros.fim : hoje.substring(0, 10);
                if (filtros1.tipo) {
                    this.valueTipo = filtros1.tipo;
                }
                if (filtros1.porte) {
                    this.valuePorte = filtros1.porte;
                }
                if (filtros1.isFisica) {
                    this.valuePFisica = filtros1.isFisica;
                }
                if (filtros1.isJuridica) {
                    this.valuePJuridica = filtros1.isJuridica;
                }
                if (filtros2.serviceResourceId) {
                    this.serviceResourceId = filtros2.serviceResourceId;
                }
                if (filtros1.serviceTerritoryId) {
                    this.serviceTerritoryId = filtros1.serviceTerritoryId;
                }
            })
            .catch(error => {
                console.log(error);
            });
    }

    disconnectedCallback() {

        salvarFiltros({inicio: this.inicio, fim: this.fim, tipo: this.valueTipo, porte: this.valuePorte, serviceResourceId: this.serviceResourceId,
            isFisica: this.valuePFisica, isJuridica: this.valuePJuridica,  serviceTerritoryId: this.serviceTerritoryId})
            .then(result => {
                console.log('filtros salvos!');
            })
            .catch(error => {
                console.log(error);
            });
    }

    @wire(checkPermissionMap)
    permissionWired(value) {
        if (value.data) {
            this.hasPermission = value.data;
        }
        if (value.error) {
            console.error(JSON.stringify(value.error));
        }
    }

    loadStyle() {
        if (this.styleInitialized) {
            return;
        }
        Promise.all([
            loadStyle(this, RESOURCE + '/css/leaflet.css'),
            loadScript(this, RESOURCE + '/js/leaflet.js'),
            loadStyle(this, STYLE + '/style.css')
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

    @wire(obtainServiceResource, { isFisica: '$valuePFisica', isJuridica: '$valuePJuridica', tipo: '$valueTipo', porte: '$valuePorte', serviceTerritoryId: '$serviceTerritoryId' })
    mapWired(value) {
        this.mapvalues = value;
        if (value.data) {
            console.log('obtainServiceResource');
            console.log(value.data);
            this.resources = value.data;

            if (this.styleInitialized) {
                this.insertResourceService();
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

        this.insertResourceService();
        this.insertLegend();

        setInterval(() => {
            refreshApex(this.mapvalues);
            console.log('try refresh');
        }, 5000)
    }

    //Legendas
    insertLegend() {
        var legend = L.control({ position: 'topright' });
        legend.onAdd = (map) => {

            var div = L.DomUtil.create('div', 'info legend');
            div.innerHTML += `<img style="max-width: 25px;" src="${ICON_ONLINE}"></img>   <b>Sinc. < 5 min.</b><br><img style="max-width: 25px;" src="${ICON_OFFLINE}"></img>   <b>Sinc. > 5 min.</b>`;
            div.innerHTML += `<br><img style="max-width: 25px;" src="${ICON_AGENDADO}"></img>   <b>Agendado</b><br><img style="max-width: 25px;" src="${ICON_ANDAMENTO}"></img>   <b>Em andamento</b>`;
            div.innerHTML += `<br><img style="max-width: 25px;" src="${ICON_CANCELADO}"></img>   <b>Cancelado</b><br><img style="max-width: 25px;" src="${ICON_CONCLUIDO}"></img>   <b>Concluido</b><br><img style="max-width: 25px;" src="${ICON_REAGENDADO}"></img>   <b>Reagendado</b>`;
            return div;
        };
        legend.addTo(this.map);
    }

    insertResourceService() {

        for (let circle of this.circles) {
            if (this.map.hasLayer(circle)) {
                this.map.removeLayer(circle);
            }
        }
        this.circles = []

        /* this.map.eachLayer((layer) => {
             if (layer instanceof L.Marker) {
                 layer.remove();
             }
         });*/

        for (let resource of this.resources) {

            // const color = resource.MinutosUltimaLocalizacao__c >= 5 ? 'red' : 'green';

            /* var circle = L.circle([parseFloat(resource.LastKnownLatitude), parseFloat(resource.LastKnownLongitude)], {
                 color: color,
                 fillColor: color,
                 fillOpacity: 1,
                 radius: 3
             }).addTo(this.map).bindPopup(`<a href="/${resource.Id}" target="_blank">${resource.Name}</a><br>Latitude: ${resource.LastKnownLatitude}<br>Longitude: ${resource.LastKnownLongitude}`);
 
             this.circles.push(circle);*/

            const status = resource.MinutosUltimaLocalizacao__c >= 5 ? ICON_OFFLINE : ICON_ONLINE;

            var circle = L.icon({
                iconUrl: status,

                iconSize: [33, 50], // size of the icon
                shadowSize: [50, 64], // size of the shadow
                iconAnchor: [16, 49], // point of the icon which will correspond to marker's location
                shadowAnchor: [4, 62],  // the same for the shadow
                popupAnchor: [0, -49] // point from which the popup should open relative to the iconAnchor
            });

            var marker1 = L.marker([parseFloat(resource.LastKnownLatitude), parseFloat(resource.LastKnownLongitude)], { icon: circle }).addTo(this.map).bindPopup(`<a href="/${resource.Id}" target="_blank">${resource.Name}</a><br>Latitude: ${resource.LastKnownLatitude}<br>Longitude: ${resource.LastKnownLongitude}`);

            this.circles.push(marker1);
        }
    }

    //Filtros
    handleChangeServiceTerritory(event) {
        console.log(event.target.value);
        this.serviceTerritoryId = event.target.value;
    }

    handleChangePFisica(event) {
        console.log(event.target.checked);
        this.valuePFisica = event.target.checked;
    }

    handleChangePJuridica(event) {
        console.log(event.target.checked);
        this.valuePJuridica = event.target.checked;
    }

    get optionsTipo() {
        return [
            { label: 'Call center', value: 'Call center' },
            { label: 'Consultores', value: 'Consultores' },
            { label: 'Equipe corporativa', value: 'Equipe corporativa' },
            { label: 'Loja autorizada', value: 'Loja autorizada' },
            { label: 'Promotores', value: 'Promotores' },
        ];
    }

    handleChangeTipo(e) {
        this.valueTipo = e.detail.value;
        console.log(this.valueTipo);
    }

    get optionsPorte() {
        return [
            { label: 'PME1 e Individual', value: 'PME1 e Individual' },
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

    //Rota do Recurso de Serviço
    handleChangeServiceResource(event) {
        console.log(event.target.value);
        this.serviceResourceId = event.target.value;
    }

    handleChangeInicio(event) {
        console.log(event.target.value);
        this.inicio = event.target.value;
    }

    handleChangeFim(event) {
        console.log(event.target.value);
        this.fim = event.target.value;
    }

    @wire(obtainServiceAppointment, { serviceResourceId: '$serviceResourceId', inicio: '$inicio', fim: '$fim' })
    serviceAppointmentWired(value) {
        // this.locationsResource = value;
        if (value.data) {
            console.log('obtainServiceAppointment');
            console.log(value.data);
            this.serviceAppointments = value.data;
            this.insertServiceAppointment();
        }
        if (value.error) {
            console.error(JSON.stringify(value.error));
        }
    }

    insertServiceAppointment() {

        if (this.map) {

            this.map.eachLayer((layer) => {
                if (layer instanceof L.Marker) {
                    layer.remove();
                }
            });
            this.serviceAppointmentsCompleted = 0;
            for (var service of this.serviceAppointments) {
                if (service.Lead__c != null && service.Lead__r.Coordenadas__Latitude__s != null && service.Lead__r.Coordenadas__Longitude__s != null) {

                    if (service.Status == 'Completed') {
                        this.serviceAppointmentsCompleted++;
                    }

                    var circle = L.icon({
                        iconUrl: this.getIconStatusAppointment(service.Status),

                        iconSize: [33, 50], // size of the icon
                        shadowSize: [50, 64], // size of the shadow
                        iconAnchor: [16, 49], // point of the icon which will correspond to marker's location
                        shadowAnchor: [4, 62],  // the same for the shadow
                        popupAnchor: [0, -49] // point from which the popup should open relative to the iconAnchor
                    });

                    L.marker([service.Lead__r.Coordenadas__Latitude__s, service.Lead__r.Coordenadas__Longitude__s], { icon: circle }).addTo(this.map).bindPopup(`<a href="/${service.Lead__c}" target="_blank">${service.Lead__r.Name}</a><br>Status do agendamento: ${service.Status}<br>Horário do Agendamento: ${this.getDateTime(service.SchedStartTime)}<br>Rua: ${service.Lead__r.Street}<br>Celular: ${service.Lead__r.Phone}`);
                }
            }

            this.lcoationsWired(null);
        }
    }

    // @wire(obtainLocations, { serviceResourceId: '$serviceResourceId', dateLocation: '$dateLocation' })
    lcoationsWired(value) {
        // this.locationsResource = value;
        /*if (value.data) {
            console.log('obtainLocations');
            console.log(value.data);
            this.locationsResource = adjustLocations(value.data);
            //console.log(this.locationsResource);
            var distance = 0.0;
            for (var index in this.locationsResource) {
                if (index < this.locationsResource.length - 1) {
                    distance += this.getDistanceFromLatLonInKm(this.locationsResource[parseInt(index)][1], this.locationsResource[parseInt(index)][0], this.locationsResource[parseInt(index) + 1][1], this.locationsResource[parseInt(index) + 1][0]);
                }
            }
            //console.log(distance.toFixed(2));

            this.insertLocation(distance.toFixed(2));
        }
        if (value.error) {
            console.error(JSON.stringify(value.error));
        }*/

        obtainLocations({ serviceResourceId: this.serviceResourceId, inicio: this.inicio, fim: this.fim })
            .then(result => {
                console.log('obtainLocations');
                console.log(result);
                this.locationsResource = adjustLocations(result);
                //console.log(this.locationsResource);
                var distance = 0.0;
                for (var index in this.locationsResource) {
                    if (index < this.locationsResource.length - 1) {
                        let data1 = '' + this.locationsResource[parseInt(index)][2];
                        let data2 = '' + this.locationsResource[parseInt(index) + 1][2];
                        let hora1 = parseInt(data1.substring(11, 13));
                        let dia1 = parseInt(data1.substring(8, 10));
                        if (hora1 < 3) {
                            dia1 = dia1 - 1; 
                        }
                        let hora2 = parseInt(data2.substring(11, 13));
                        let dia2 = parseInt(data2.substring(8, 10));
                        if (hora2 < 3) {
                            dia2 = dia2 - 1; 
                        }
                        if (dia1 == dia2) {
                            distance += this.getDistanceFromLatLonInKm(this.locationsResource[parseInt(index)][1], this.locationsResource[parseInt(index)][0], this.locationsResource[parseInt(index) + 1][1], this.locationsResource[parseInt(index) + 1][0]);
                        }
                    }
                }
                //console.log(distance.toFixed(2));

                this.insertLocation(distance.toFixed(2));
            }).catch(err => {
                console.error(JSON.stringify(err));
            })
    }

    insertLocation(distance) {

        this.map.eachLayer((layer) => {
            if (layer instanceof L.GeoJSON || layer instanceof L.CircleMarker) {
                layer.remove();
            }
        });

        if (this.locationsResource.length > 0) {
            var myLines = [{
                "type": "LineString",
                "coordinates": this.locationsResource
            }];

            var myStyle = {
                "color": "red",
                "weight": 3,
                "opacity": 0.65
            };

            L.geoJSON(myLines, {
                style: myStyle
            }).addTo(this.map).bindPopup(`<h1 style="font-size: 1.2em;">Distância percorrida: <b>${distance} km</b></h1><br>Total de agendamentos:${this.serviceAppointments.length}<br>Total de concluídos:${this.serviceAppointmentsCompleted}`).openPopup();

            const finalPosition = this.locationsResource.length - 1;
            var horarioInicial = this.locationsResource[0][2];            
            var horarioFinal = this.locationsResource[finalPosition][2];
            this.insertInitialPoint(this.locationsResource[0][1], this.locationsResource[0][0], this.formataDatetime(horarioInicial));
            this.insertFinalPoint(this.locationsResource[finalPosition][1], this.locationsResource[finalPosition][0], this.formataDatetime(horarioFinal));
        }
    }

    formataDatetime(dt) {

        var d = new Date(dt);
        var dtFormatado = d.toLocaleString();
        var listaDt = dtFormatado.split(' ');
        dtFormatado = listaDt[1] + ' (' + listaDt[0] + ')';
        return dtFormatado;
    }

    insertInitialPoint(latitude, longitude, horario) {
        var circle = L.circle([latitude, longitude], {
            color: 'green',
            fillColor: 'green',
            fillOpacity: 1,
            radius: 3
        }).addTo(this.map).bindPopup(`Ponto Inicial<br>Horário: ${horario}`);

        // this.circles.push(circle);
    }

    insertFinalPoint(latitude, longitude, horario) {
        var circle = L.circle([latitude, longitude], {
            color: 'black',
            fillColor: 'black',
            fillOpacity: 1,
            radius: 3
        }).addTo(this.map).bindPopup(`Ponto Final<br>Horário: ${horario}`);

        // this.circles.push(circle);
    }

    getIconStatusAppointment(status) {
        switch (status) {
            case 'Scheduled':
                return ICON_AGENDADO;
            case 'In Progress':
                return ICON_ANDAMENTO;
            case 'Canceled':
                return ICON_CANCELADO;
            case 'Completed':
                return ICON_CONCLUIDO;
            case 'Rescheduled':
                return ICON_REAGENDADO;
            default:
                return ICON_AGENDADO;
        }
    }

    getDateTime(dtValue) {
        var dt = new Date(dtValue);
        return `${('0' + dt.getDate()).slice(-2)}/${('0' + (dt.getMonth() + 1)).slice(-2)}/${dt.getFullYear()} - ${('0' + dt.getHours()).slice(-2)}:${('0' + dt.getMinutes()).slice(-2)}:${('0' + dt.getSeconds()).slice(-2)}`;
    }

    //Haversine formula
    getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
        var R = 6371; // Radius of the earth in km
        var dLat = this.deg2rad(lat2 - lat1);  // deg2rad below
        var dLon = this.deg2rad(lon2 - lon1);
        var a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        var d = R * c; // Distance in km
        return d;
    }

    deg2rad(deg) {
        return deg * (Math.PI / 180)
    }
}