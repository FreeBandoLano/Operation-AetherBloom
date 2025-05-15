// Simple API to connect the website with the Flutter app data
const API_ENDPOINT = 'http://localhost:5000';

console.log("API.js loaded, will attempt to connect to:", API_ENDPOINT);

async function fetchUsageData() {
    try {
        console.log("Attempting to fetch data from API...");
        const response = await fetch(`${API_ENDPOINT}/fetchData`);
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        const data = await response.json();
        console.log("Data received:", data);
        return data;
    } catch (error) {
        console.error('Error fetching usage data:', error);
        return null;
    }
}

// Function to display usage data on the website
function displayUsageData(data) {
    const usageDataElement = document.getElementById('usage-data');
    if (!usageDataElement) {
        console.error("Could not find usage-data element in DOM");
        return;
    }
    
    if (!data) {
        usageDataElement.innerHTML = '<p>Unable to fetch data. Server may be offline.</p>';
        return;
    }
    
    console.log("Displaying data in usage-data element");
    usageDataElement.innerHTML = `
        <div class='data-card'>
            <h3>Recent Inhaler Usage</h3>
            <p>Count: ${data.inhalerUseCount}</p>
            <p>Last Used: ${data.timestamp}</p>
            <p>Notes: ${data.notes}</p>
        </div>
    `;
}

// Load data when page loads
window.addEventListener('DOMContentLoaded', async () => {
    console.log("DOM loaded, fetching usage data...");
    const data = await fetchUsageData();
    displayUsageData(data);
});
