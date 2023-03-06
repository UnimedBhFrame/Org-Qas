({
    closeModal: function (component, event) {
        console.log('closeModal');
        // Original
        $A.get("e.force:closeQuickAction").fire();
    }
})