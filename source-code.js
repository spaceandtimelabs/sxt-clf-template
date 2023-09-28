// This example shows how to fetch data from SxT Public Views API and parse the data to valid string response
const validateStringResponse = (responseObject) => {
    let result = "";

	if (!(responseObject.data.length > 0)) {
		return undefined;
	}

	for (let obj of responseObject.data) {
    const keys = Object.keys(obj);

    for (let key of keys) {
			const valueString = validateValueString(obj[key]);
			result = result.concat(`${valueString}`);

			if ((keys.indexOf(obj) != keys.length - 1) || (responseObject.data.indexOf(obj) != responseObject.data.length - 1)) {
				result = result.concat(',');
			} 
}
	}

	result = result.slice(0, -1);

	const buf = Buffer.from(result, "utf8");
	const bufferLength = Buffer.byteLength(buf);

	if (!buf || !result || !(bufferLength <= Number(256))) {
    return undefined;
}

return result;
}

const validateValueString = (value) => {
	let validStringValue = value.toString();

	if (validStringValue.includes(",")) {
		validStringValue = validStringValue.replace(/,/g, '|');
	}

	return validStringValue;
}

// more than one biscuit can be specified in the secrets so that multiple biscuits can be sent in the request
const response = await Functions.makeHttpRequest(
	{
		url: "https://actual_space_and_time_url_here.com",
		method: "POST",
		timeout: 9000,
		headers: {
			"Content-Type": "application/json",
			"apikey": secrets.apiKey,
		},
		data: {
			"sqlText": "YOUR SQL TEXT HERE",
			//biscuits here is provided as an example, if you're request does not require authorization remove line below
			//"biscuits": [secrets.biscuit1]
		}
	}
);
console.log(response)

// Use this in case if you are sure the view response would be single row and single column and the value is valid string
// const result = response.data[0]["COLUMN_NAME"].toString();

// Use this in case if view response would have multiple columns and multiple rows and need to convert it to ',' separated string values
// const result = validateStringResponse(response);

if (!response || !response.data || !response.data.length > 0) {
    throw Error("Could not get response from API");
}

const result = validateStringResponse(response);

if (!result) {
    throw Error("Invalid response");
}

return Functions.encodeString(result);