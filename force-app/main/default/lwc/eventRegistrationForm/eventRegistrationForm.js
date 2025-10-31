import { LightningElement, track, wire } from 'lwc';
import registerAttendeeFromLWC from '@salesforce/apex/EventRegistrationHandler.registerAttendeeFromLWC';
import getAvailableEvents from '@salesforce/apex/EventRegistrationHandler.getAvailableEvents';
import getSessionsByEventId from '@salesforce/apex/EventRegistrationHandler.getSessionsByEventId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EventRegistrationForm extends LightningElement {
    // Attendee Data
    @track name = '';
    @track email = '';
    
    // Selection Data
    @track eventId = '';
    @track sessionId = '';
    @track message = '';

    // Combobox Options
    @track eventOptions = [];
    @track sessionOptions = [];
    @track isSessionDisabled = true; // Disable session dropdown until event is selected

    // Wire method to fetch all available events
    @wire(getAvailableEvents)
    wiredEvents({ error, data }) {
        if (data) {
            // Apex method returns List<Map<String, String>>, which LWC converts to an array of objects
            this.eventOptions = data;
        } else if (error) {
            this.showToast('Error', 'Could not load events: ' + error.body.message, 'error');
            console.error('Error loading events', error);
        }
    }

    // Handlers for Attendee data
    handleNameChange(event) {
        this.name = event.target.value;
    }
    handleEmailChange(event) {
        this.email = event.target.value;
    }

    // Handler for Event selection (imperatively calls Apex for Sessions)
    handleEventChange(event) {
        this.eventId = event.detail.value;
        this.sessionId = ''; // Reset session when event changes
        this.isSessionDisabled = true;
        this.sessionOptions = []; // Clear current options

        if (this.eventId) {
            this.loadSessions();
        }
    }

    // Imperative Apex call to load sessions for the selected event
    loadSessions() {
        getSessionsByEventId({ eventId: this.eventId })
            .then(result => {
                this.sessionOptions = result;
                this.isSessionDisabled = result.length === 0;
                if (this.isSessionDisabled) {
                    this.showToast('Info', 'No available sessions for this event.', 'info');
                }
            })
            .catch(error => {
                this.showToast('Error', 'Error loading sessions: ' + error.body.message, 'error');
                console.error('Error loading sessions', error);
            });
    }

    // Handler for Session selection
    handleSessionChange(event) {
        this.sessionId = event.detail.value;
    }

    // Registration Logic
    handleRegistration() {
        // Basic Validation
        if (!this.name || !this.email || !this.eventId || !this.sessionId) {
             this.showToast('Error', 'Please complete all required fields.', 'error');
             return;
        }

        this.message = 'Processing registration...';
        
        registerAttendeeFromLWC({ 
            attendeeName: this.name, 
            attendeeEmail: this.email, 
            sessionId: this.sessionId 
        })
        .then(result => {
            let toastVariant = result.startsWith('Error') ? 'error' : 'success';
            let toastTitle = result.startsWith('Error') ? 'Registration Failed' : 'Registration Complete';
            
            this.showToast(toastTitle, result, toastVariant);

            if (toastVariant === 'success') {
                // Clear the form on success
                this.name = '';
                this.email = '';
                // this.eventId = '';
                // this.sessionId = '';
            }
            this.message = result;
        })
        .catch(error => {
            this.message = 'An unexpected error occurred: ' + error.body.message;
            this.showToast('System Error', error.body.message, 'error');
        });
    }
    handleDiscard() {
        this.name = '';
        this.email = '';
        
        this.eventId = '';
        this.sessionId = '';
        this.sessionOptions = [];
        this.isSessionDisabled = true;
        
        this.message = '';
        this.showToast('Form Cleared', 'Registration form has been reset.', 'info');
        // window.location.reload();
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}