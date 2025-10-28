import { LightningElement, wire, track } from 'lwc';
import getOngoingEvents from '@salesforce/apex/EventMapController.getOngoingEvents';

export default class EventMap extends LightningElement {
    @track mapMarkers = [];
    @track error;
    @track isLoading = true;

    @wire(getOngoingEvents)
    wiredEvents({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.mapMarkers = data.map(eventRec => ({
                location: {
                    Latitude: eventRec.Location__Latitude__s,
                    Longitude: eventRec.Location__Longitude__s
                },
                title: eventRec.Name,
                description: `Event Dates: ${eventRec.Start_Date__c} to ${eventRec.End_Date__c}`,
                icon: 'standard:event'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
            this.mapMarkers = [];
        }
    }
}
