({
    init : function(component, event, helper) {
        // Replace 'Your_LWC_Tab_API_Name' with the actual API Name of your custom LWC tab.
        var targetURL = "/lightning/n/Event_Registration"; 

        var urlEvent = $A.get("e.force:navigateToURL");
        
        if (urlEvent) {
            urlEvent.setParams({
              "url": targetURL
            });
            urlEvent.fire();
        } else {
            // Fallback for Community/External sites where force:navigateToURL might not be available
            console.error("force:navigateToURL event not supported or missing.");
            window.location.href = targetURL;
        }
    }
})