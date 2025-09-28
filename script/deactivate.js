// Inline implementation for Maestro compatibility
function getEnvVar(name, defaultValue) {
    try {
        if (typeof process !== 'undefined' && process && process.env && Object.prototype.hasOwnProperty.call(process.env, name)) {
            return process.env[name];
        }
        if (typeof globalThis !== 'undefined' && globalThis && globalThis[name] !== undefined) {
            return globalThis[name];
        }
    } catch (_) {}
    return defaultValue;
}

class Interface {
    constructor() {
        this.header = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Connection": "keep-alive"
        };
    }

    getCookie(businessName, email, password) {
        const url = this.getBoBaseUrl(businessName) + "login";

        try {
            console.log(`Attempting login to: ${url}`);
            console.log(`Email: ${email}`);

            const body = JSON.stringify({ username: email, password: password });
            const response = http.post(url, {
                headers: this.header,
                body: body
            });

            console.log(`Login response status: ${response.status}`);

            if (response.status !== 200) {
                throw new Error(`Login failed with status ${response.status}: ${response.body}`);
            }

            const cookies = response.headers['set-cookie'];
            if (!cookies) {
                throw new Error("No cookies received from login response");
            }

            const cookieString = cookies.split(',').map(cookie => cookie.split(';')[0]).join('; ');
            console.log(`Received cookies: ${cookieString}`);

            return cookieString;
        } catch (error) {
            console.log(`Error details: ${error.message}`);
            throw new Error(`Failed to get cookie: ${error.message}`);
        }
    }

    deactivateRegister(business, email, password, registerId) {
        try {
            const cookie = this.getCookie(business, email, password);
            this.header["Cookie"] = cookie;

            const url = this.getBoBaseUrl(business) + "settings/registers/deactivate";
            const body = JSON.stringify({ registerId: registerId });

            console.log(`Sending deactivation request to: ${url}`);
            console.log(`Request body: ${JSON.stringify(body)}`);
            console.log(`Headers:`, JSON.stringify(this.header, null, 2));

            const response = http.post(url, {
                headers: this.header,
                body: body
            });

            let parsedBody = response.body;
            try {
                parsedBody = JSON.parse(response.body);
            } catch (e) {
                // ignore
            }

console.log(`Deactivation response status: ${response.status}`);

            console.log(`\n--- Checking register status after deactivation ---`);
            this.checkRegisterStatus(business, registerId);

            return {
                status: response.status,
                data: parsedBody,
                success: response.status >= 200 && response.status < 300
            };
        } catch (error) {
            console.log(`Error details: ${error.message}`);
            throw new Error(`Failed to deactivate register: ${error.message}`);
        }
    }

    checkRegisterStatus(business, registerId) {
        try {
            const url = this.getBoBaseUrl(business) + `settings/registers/${registerId}`;
            console.log(`Checking register status at: ${url}`);

            const response = http.get(url, {
                headers: this.header
            });

            let parsedBody = response.body;
            try {
                parsedBody = JSON.parse(response.body);
            } catch (e) {
                // ignore
            }

            console.log(`Register status check - Status: ${response.status}`);
            console.log(`Register status check - Data:`, parsedBody);

            return {
                status: response.status,
                data: parsedBody,
                success: response.status >= 200 && response.status < 300
            };
        } catch (error) {
            console.log(`Error checking register status: ${error.message}`);
            return { status: 0, data: null, success: false };
        }
    }

    getBoBaseUrl(businessName = "uiautomation") {
        const business = 'https://' + businessName;
        const env = getEnvVar('ENV', "fat"); // Default to fat

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

function runFromMaestro() {
    try {
        const apiClient = new Interface();
        
        const businessName = getEnvVar('myAccount', getEnvVar('myParameter', "mcm"));
        const email = getEnvVar('myEmail', "chad.deng@storehub.com");
        const password = getEnvVar('myPassword', "1Qaz2wsx");
        const registerId = getEnvVar('myRegisterId', "19");

        console.log(`Deactivating register ${registerId} for business ${businessName}...`);

        const result = apiClient.deactivateRegister(businessName, email, password, registerId);

        console.log(`Status: ${result.status}`);
        console.log(`Success: ${result.success}`);
        console.log(result.success ? "Success!" : "Failed!");

    } catch (error) {
        console.error("Error:", error.message);
    }
}

runFromMaestro();
