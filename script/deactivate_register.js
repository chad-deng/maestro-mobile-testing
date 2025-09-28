const axios = require('axios');
const fs = require('fs');

class Interface {
    constructor() {
        this.header = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Connection": "keep-alive"
        };
        this.session = axios.create();
    }

    async getCookie(businessName, email, password) {
        const url = this.getBoBaseUrl(businessName) + "login";

        try {
            console.log(`Attempting login to: ${url}`);
            console.log(`Email: ${email}`);

            const body = JSON.stringify({ username: email, password: password });
            const response = await this.session.post(url, body, { headers: this.header });

            console.log(`Login response status: ${response.status}`);

            if (response.status !== 200) {
                throw new Error(`Login failed with status ${response.status}: ${response.statusText}`);
            }

            const cookies = response.headers['set-cookie'];
            if (!cookies) {
                throw new Error("No cookies received from login response");
            }

            // Format cookies properly for subsequent requests
            const cookieString = cookies.map(cookie => cookie.split(';')[0]).join('; ');
            console.log(`Received cookies: ${cookieString}`);

            return cookieString;
        } catch (error) {
            if (error.response) {
                console.log(`HTTP Error: ${error.response.status} - ${error.response.statusText}`);
                console.log(`Response data:`, error.response.data);
            }
            throw new Error(`Failed to get cookie: ${error.message}`);
        }
    }

    async deactivateRegister(business, email, password, registerId) {
        try {
            // Get the cookie for the business
            const cookie = await this.getCookie(business, email, password);

            // Set the cookie in the header (use "Cookie" not "Cookies")
            this.header["Cookie"] = cookie;

            const url = this.getBoBaseUrl(business) + "settings/registers/deactivate";
            const body = JSON.stringify({ registerId: registerId });

            console.log(`Sending deactivation request to: ${url}`);
            console.log(`Request body: ${body}`);

            const response = await this.session.post(url, body, { headers: this.header });

            console.log(`Deactivation response status: ${response.status}`);
            console.log(`Response data:`, response.data);

            return {
                status: response.status,
                data: response.data,
                success: response.status === 200
            };
        } catch (error) {
            if (error.response) {
                console.log(`HTTP Error: ${error.response.status} - ${error.response.statusText}`);
                console.log(`Response data:`, error.response.data);
            }
            throw new Error(`Failed to deactivate register: ${error.message}`);
        }
    }

    getBoBaseUrl(businessName = "uiautomation") {
        const business = 'https://' + businessName;
        const env = process.env.ENV || "fat"; // Default to fat

        let boLoginUrl;

        if (env === "fat") {
            boLoginUrl = business + '.backoffice.test17.shub.us/';
        } else if (env === "staging") {
            boLoginUrl = business + '.backoffice.staging.mymyhub.com/';
        } else if (env === "production") {
            boLoginUrl = business + '.storehubhq.com/';
        } else {
            console.log("Unknown ENV value, defaulting to fat");
            boLoginUrl = business + '.backoffice.test17.shub.us/';
        }

        console.log(`Using URL: ${boLoginUrl}`);
        return boLoginUrl;
    }
}

module.exports = Interface;