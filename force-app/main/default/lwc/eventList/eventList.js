import { LightningElement, wire } from 'lwc';
import getUpcomingEvents from '@salesforce/apex/EventUtility.getUpcomingEvents';

export default class EventList extends LightningElement {
    events;
    @wire(getUpcomingEvents) wiredEvents({ data, error }) {
        if (data) this.events = data;
        else if (error) console.error(error);
    }
}
