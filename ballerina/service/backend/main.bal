// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com).
// This line specifies the copyright holder and their website.

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// This block mentions the licensing terms under which the file is provided.

// You may obtain a copy of the License at
// This line provides the URL where you can find the full text of the Apache License, Version 2.0.

// http://www.apache.org/licenses/LICENSE-2.0
// This line gives the specific location where the License can be obtained.

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.
// These lines describe the conditions under which the software is distributed and disclaim any warranties or conditions.

import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/jballerina.java;

import ballerinax/googleapis.sheets as gsheets;

type Auth record {|
    string clientId;
    string clientSecret;
    string refreshToken;
    string refreshUrl;
|};

type ResponseError record {|
    *http:BadRequest;
    record {
        string message;
    } body;
|};

type ResponseOK record {|
    *http:Ok;
    record {|
        string Content\-Type;
        string Content\-Disposition;
    |} headers;

    byte[] body;
|};

configurable string pdfFilePath = ?;
configurable string fontFilePath = ?;
configurable int port = 8080;
configurable string spreadsheetId = ?;
configurable Auth auth = ?;

const PDF_EXTENSION = ".pdf";
const OUTPUT_DIRECTORY = "outputs/";
const NAME_COLUMN = "C";
const CONTENT_TYPE = "application/pdf";
const CONTENT_DISPOSITION = "inline; filename='certificate.pdf'";

gsheets:Client spreadsheetClient = check new ({
    auth
});

string filePath = "";

isolated function generatePdf(handle pdfGenerator) = @java:Method {
    'class: "org.PDFCreator.PDFGenerator",
    name: "pdf"
} external;

isolated function generateParams(handle inputFilePath, handle replacement, handle fontType, int fontsize, int centerX, int centerY, handle fontFilePath, handle outputFileName) returns handle = @java:Method {
    'class: "org.PDFCreator.PDFGenerationParams",
    name: "createInstance"
} external;

public function certificateGeneration(string inputFilePath, string fontFilePath, string checkID, string sheetName) returns error? {
    gsheets:Column col = check spreadsheetClient->getColumn(spreadsheetId, sheetName, NAME_COLUMN);
    string a1Notation = string `A2:${col.values.length()}`;
    gsheets:Range range = check spreadsheetClient->getRange(spreadsheetId, sheetName, a1Notation);
    foreach var entry in range.values {
        if entry[3].toString() != checkID {
            continue;
        }
        string replacement = entry[2].toString();
        string fileName = replacement + checkID + PDF_EXTENSION;
        filePath = OUTPUT_DIRECTORY + fileName;
        int fontsize = check int:fromString(entry[4].toString());
        int centerX = check int:fromString(entry[5].toString());
        int centerY = check int:fromString(entry[6].toString());
        handle javastrName = java:fromString(replacement);
        handle javafontType = java:fromString(entry[7].toString());
        handle javafontPath = java:fromString(fontFilePath);
        handle pdfpath = java:fromString(inputFilePath);
        handle javaOurputfileName = java:fromString(fileName);
        handle pdfData = generateParams(pdfpath, javastrName, javafontType, fontsize, centerX, centerY, javafontPath, javaOurputfileName);
        generatePdf(pdfData);
        break;
    }
}

service / on new http:Listener(port) {
    resource function get certificates/[string value]() returns ResponseOK|ResponseError {
        string:RegExp r = re `-`;
        string[] data = r.split(value);
        string ID = data[1];
        string sheetName = data[0];
        byte[] payload;
        error? err = certificateGeneration(pdfFilePath, fontFilePath, ID, sheetName);
        byte[]|io:Error dataRead =  io:fileReadBytes(filePath);
        if err is error {
            return {body: { message: "Invalid Request" }};
        }
        else if dataRead is io:Error {
            return {body: { message: "Error in getting PDF" }};
        }
        else{
            payload = dataRead;
            error? removeFile =deleteFile(filePath);
            return {headers: { Content\-Type: CONTENT_TYPE, Content\-Disposition: CONTENT_DISPOSITION }, body: payload};
        }
    }
}

public function deleteFile(string filePath) returns error?{
    return check file:remove(filePath);
}