import { LightningElement, wire, track } from 'lwc';
import getMonthlyCounts from '@salesforce/apex/EventSummaryController.getMonthlyCounts';

export default class EventSummaryTiles extends LightningElement {
    @track events = 0;
    @track attendees = 0;
    @track sessions = 0;
    @track error;

    @wire(getMonthlyCounts)
    wiredCounts({ data, error }) {
        if (data) {
            this.events = data.events;
            this.attendees = data.attendees;
            this.sessions = data.sessions;
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
        }
    }
}
