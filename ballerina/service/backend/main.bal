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
import ballerina/regex;

import ballerinax/googleapis.sheets as gsheets;

type Auth record {|
    string clientId;
    string clientSecret;
    string refreshToken;
    string refreshUrl;
|};

type Conflict record {|
    *http:Conflict;
    record {
        string message;
    } body;
|};

configurable string pdfFilePath = ?;
configurable string fontFilePath = ?;
configurable int port = 9090;
configurable string spreadsheetId = ?;
configurable Auth auth = ?;

const PDF_EXTENSION = ".pdf";
const OUTPUT_DIRECTORY = "outputs/";
const FILE_NAME = "certificate.pdf";
const NAME_COLUMN = "C";
const SUCCESS_CODE = 200;
const ERROR_CODE = 400;
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
    int i = 1;
    while i < col.values.length() {
        gsheets:Row row = check spreadsheetClient->getRow(spreadsheetId, sheetName, i);
        if row.values[3].toString() == checkID {
            string replacement = col.values[i].toString();
            string fileName = replacement + PDF_EXTENSION;
            filePath = OUTPUT_DIRECTORY + fileName;
            int fontsize = check int:fromString(row.values[7].toString());
            int centerX = check int:fromString(row.values[4].toString());
            int centerY = check int:fromString(row.values[5].toString());
            handle javastrName = java:fromString(replacement);
            handle javafontType = java:fromString(row.values[6].toString());
            handle javafontPath = java:fromString(fontFilePath);
            handle pdfpath = java:fromString(inputFilePath);
            handle javaOurputfileName = java:fromString(fileName);
            handle pdfData = generateParams(pdfpath, javastrName, javafontType, fontsize, centerX, centerY, javafontPath, javaOurputfileName);
            generatePdf(pdfData);
            break;
        }
        i += 1;

    }
}

service / on new http:Listener(port) {
    resource function get certificates/[string value]() returns http:Response|error {
        string[] data = regex:split(value, "-");
        string ID = data[1];
        string sheetName = data[0];
        error? err = certificateGeneration(pdfFilePath, fontFilePath, ID, sheetName);
        byte[]|io:Error dataRead =  io:fileReadBytes(filePath);
        http:Response response = new;
        if err is error || dataRead is io:Error{ 
            response.setJsonPayload("invalid UserID ");
            response.statusCode = ERROR_CODE;
            return response;
        }
        response.setPayload(check io:fileReadBytes(filePath));
        response.statusCode = SUCCESS_CODE;
        response.setHeader("Content-Type", CONTENT_TYPE);
        response.setHeader("Content-Disposition", CONTENT_DISPOSITION);
        check file:remove(filePath);
        return response;
    }
}

