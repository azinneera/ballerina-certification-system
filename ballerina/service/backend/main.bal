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
import ballerinax/googleapis.drive as drive;

type Auth record {|
    string clientId;
    string clientSecret;
    string refreshToken;
    string refreshUrl = gsheets:REFRESH_URL;
|};

configurable string fontFilePath = "Helvetica";
configurable int port = ?;
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

drive:ConnectionConfig driveConfig = {
    auth 
};

drive:Client driveClient = check new (driveConfig);

string filePath = "";

isolated function generatePdf(handle pdfGenerator) = @java:Method {
    'class: "org.PDFCreator.PDFGenerator",
    name: "pdf"
} external;

isolated function generateParams(handle inputFilePath, handle replacement, handle fontType, int fontsize, int centerX, int centerY, handle fontFilePath, handle outputFileName) returns handle = @java:Method {
    'class: "org.PDFCreator.PDFGenerationParams",
    name: "createInstance"
} external;

public function certificateGeneration(string fontFilePath, string checkID, string sheetName) returns error?|http:NotFound {
    gsheets:Column|error col = spreadsheetClient->getColumn(spreadsheetId, sheetName, NAME_COLUMN);
    if col is error {
        return <http:NotFound> {body: {message: "No certificate found for the credential ID"}};
    }
    
    int i = 1;
    while i < col.values.length() {
        gsheets:Row row = check spreadsheetClient->getRow(spreadsheetId, sheetName, i + 1);
        if row.values[3].toString() == checkID {
            string replacement = row.values[2].toString();
            string fileName = replacement + checkID + PDF_EXTENSION;
            filePath = OUTPUT_DIRECTORY + fileName;

            int fontsize = check int:fromString(row.values[4].toString());
            int centerX = check int:fromString(row.values[5].toString());
            int centerY = check int:fromString(row.values[6].toString());
            handle javastrName = java:fromString(replacement);
            handle javafontType = java:fromString(row.values[7].toString());

            handle certTemplateUrl = java:fromString(row.values[8].toString());
            check getCertTemplate(certTemplateUrl, fileName);

            handle javafontPath = java:fromString(fontFilePath);
            handle pdfpath = java:fromString(fileName);
            handle javaOurputfileName = java:fromString(fileName);
            handle pdfData = generateParams(pdfpath, javastrName, javafontType, fontsize, centerX, centerY, javafontPath, javaOurputfileName);
            generatePdf(pdfData);
            return;
        }
        i += 1;
    }
    return <http:NotFound> {body: {message: "No certificate found for the credential ID"}};
}

function getCertTemplate(handle url, string fileName) returns error? {
    http:Client httpEP = check new (url.toString(), followRedirects = {enabled: true});
    http:Response e = check httpEP->get("");
    return io:fileWriteBlocksFromStream(fileName, check e.getByteStream());
}

service / on new http:Listener(port) {
    resource function get certificates/[string value]() returns http:InternalServerError|http:NotFound|error|http:Ok {
        string:RegExp r = re `-`;
        string[] data = r.split(value);
        string ID = data[1];
        string sheetName = data[0];
        error?|http:NotFound err = certificateGeneration(fontFilePath, ID, sheetName);
        if err is http:NotFound {
            return err;
        }
        if err is error {
            return err;
        }

        byte[]|io:Error dataRead =  io:fileReadBytes(filePath);
        if dataRead is io:Error {
            return <http:InternalServerError>{body: {message: dataRead.message()}};
        } else {
            error? fileResult = deleteFile(filePath);
            if fileResult is error {
                // ignore
            }
            return <http:Ok>{headers: { Content\-Type: CONTENT_TYPE, Content\-Disposition: CONTENT_DISPOSITION }, body: dataRead};
        }
    }
}

public function deleteFile(string filePath) returns error?{
    return check file:remove(filePath);
}