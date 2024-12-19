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
import ballerina/lang.runtime;
import ballerina/log;
import ballerinax/googleapis.drive as drive;
import ballerinax/googleapis.sheets as gsheets;

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
const NAME_COLUMN = "C";
const CONTENT_TYPE = "application/pdf";

final gsheets:Client spreadsheetClient = check new ({auth});
drive:ConnectionConfig driveConfig = {auth};
drive:Client driveClient = check new (driveConfig);

final string tmpDir = check file:createTempDir();
isolated string filePath = "";
final isolated map<gsheets:Range> sheetRangeMap = {};

isolated function generatePdf(handle pdfGenerator) = @java:Method {
    'class: "org.PDFCreator.PDFGenerator",
    name: "pdf"
} external;

isolated function generateParams(handle inputFilePath, handle replacement, handle fontType, int fontsize, int centerX, int centerY, handle fontFilePath, handle outputFileName) returns handle = @java:Method {
    'class: "org.PDFCreator.PDFGenerationParams",
    name: "createInstance"
} external;

isolated function certificateGeneration(string fontFilePath, string checkID, string sheetName)
    returns error?|http:NotFound|http:BadRequest {
    (int|string|decimal)[][] values;
    lock {
        if !sheetRangeMap.hasKey(sheetName) {
            return <http:BadRequest>{body: {message: "Invalid credential ID provided"}};
        }
        values = sheetRangeMap.get(sheetName).values.clone();
    }
    log:printInfo("Generating the certificate for " + sheetName + "-" + checkID);
    foreach var entry in values {
        if entry[3].toString() != checkID {
            continue;
        }
        string replacement = entry[2].toString();
        string fileName = replacement + checkID + PDF_EXTENSION;
        lock {
            filePath = check file:joinPath(tmpDir, fileName);
        }
        
        int fontsize = check int:fromString(entry[4].toString());
        int centerX = check int:fromString(entry[5].toString());
        int centerY = check int:fromString(entry[6].toString());
        handle javastrName = java:fromString(replacement);
        handle javafontType = java:fromString(entry[7].toString());

        string certTemplateFile = entry[9].toString();
        string templatePath = check file:joinPath(tmpDir, "template", certTemplateFile);

        handle javafontPath = java:fromString(fontFilePath);
        handle pdfpath = java:fromString(templatePath);
        lock {
            handle javaOutputfileName = java:fromString(filePath);
            handle pdfData = generateParams(
                pdfpath, javastrName, javafontType, fontsize, centerX, centerY, javafontPath, javaOutputfileName);
            generatePdf(pdfData);
        }
        return;
    }
    return <http:NotFound>{body: {message: "No certificate found for the credential ID: " + checkID}};
}

isolated function getCertTemplate(handle url, string fileName) returns error? {
    http:Client httpEP = check new (url.toString(), followRedirects = {enabled: true});
    http:Response e = check httpEP->get("");
    io:Error? fileWriteBlocksFromStream = io:fileWriteBlocksFromStream(fileName, check e.getByteStream());
    runtime:sleep(3);
    return fileWriteBlocksFromStream;
}

service / on new http:Listener(port) {
    isolated function init() returns error? {
        log:printInfo("Initializing the service");
        gsheets:Sheet[] sheets = check spreadsheetClient->getSheets(spreadsheetId);
        foreach gsheets:Sheet sheet in sheets {
            string sheetName = sheet.properties.title;
            if sheetName == "Resources" {
                gsheets:Column col = check spreadsheetClient->getColumn(spreadsheetId, sheetName, "B");
                string a1Notation = string `B2:${col.values.length()}`;
                gsheets:Range range = check spreadsheetClient->getRange(spreadsheetId, sheetName, a1Notation);
                foreach var entry in range.values {
                    handle templateUrl = java:fromString(entry[1].toString());
                    string templatePath = check file:joinPath(tmpDir, "template", entry[0].toString());
                    check getCertTemplate(templateUrl, templatePath);
                }
                continue;
            }
            gsheets:Column col = check spreadsheetClient->getColumn(spreadsheetId, sheetName, NAME_COLUMN);
            string a1Notation = string `A2:${col.values.length()}`;
            lock {
                gsheets:Range range = check spreadsheetClient->getRange(spreadsheetId, sheetName, a1Notation);
                sheetRangeMap[sheetName] = range;
            }
        }
        log:printInfo("Started the service...");
        log:printInfo("Created the output directory: " + tmpDir);
    }
    isolated resource function get certificates/[string value]() returns http:NotFound|http:BadRequest|http:InternalServerError|error|http:Ok {
        string:RegExp r = re `-`;
        string[] data = r.split(value);
        string ID = data[1];
        string sheetName = data[0];
        error?|http:NotFound|http:BadRequest err = certificateGeneration(fontFilePath, ID, sheetName);
        if err !is () {
            log:printError("failed to generate certificate for credential ID: " + value);
            return err;
        }

    byte[]|io:Error dataRead;
        lock {
            dataRead = io:fileReadBytes(filePath);
        }
        if dataRead is io:Error {
            return <http:InternalServerError>{body: {message: dataRead.message()}};
        } else {
            lock {
                error? fileResult = deleteFile(filePath);
                if fileResult is error {
                    // ignore
                }
            }
            string content_disposition = "inline; filename=" + value + ".pdf";
            return <http:Ok>{headers: {Content\-Type: CONTENT_TYPE, Content\-Disposition: content_disposition}, body: dataRead};
            }
        
    }
}

isolated function deleteFile(string filePath) returns error? {
    return check file:remove(filePath);
}
