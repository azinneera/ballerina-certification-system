/**
 * Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

 package org.PDFCreator;

 import org.apache.pdfbox.pdmodel.PDDocument;
 import org.apache.pdfbox.pdmodel.font.PDType1Font;
 import org.apache.pdfbox.pdmodel.font.PDType0Font;
 import org.apache.pdfbox.pdmodel.PDPage;
 import org.apache.pdfbox.pdmodel.PDPageContentStream;
 import java.io.File;
 import java.io.IOException;

 public class PDFGenerator {
     /**
      * This method is used to generate a PDF file with the given text.
      *
      * @param params The parameters for PDF generation.
      */
     public static void pdf(PDFGenerationParams params) {
         String outputDirectory = "outputs/";
         File inputFile = new File(params.inputFilePath);
         File outputDir = new File(outputDirectory);
         float nameHeight = 0;
         float nameWidth = 0;
         if (!outputDir.exists()) {
             outputDir.mkdirs();
         }
         String outputFilePath = outputDirectory + params.outputFileName;
         try (PDDocument pdfDocument = PDDocument.load(inputFile)) {
             PDPage page = pdfDocument.getPage(0);
             // if centerX is negative, the text will be centered horizontally
             //page.getMediaBox().getWidth()- this will get the width of the page
             float centerXF = params.centerX < 0 ? (float) (page.getMediaBox().getWidth() / 2.0) : params.centerX;
             PDPageContentStream contentStream = new PDPageContentStream(pdfDocument, page,
                     PDPageContentStream.AppendMode.APPEND, true, true);

             if ("CUSTOM".equals(params.fontType)) {
                 File fontFile = new File(params.fontFilePath);
                 PDType0Font font = PDType0Font.load(pdfDocument, fontFile);
                 contentStream.setFont(PDType1Font.HELVETICA, params.fontSize);
                 nameWidth = font.getStringWidth(params.replacement) / 1000 * params.fontSize;
                 nameHeight = (font.getFontDescriptor().getCapHeight()) / 1000 * params.fontSize;
             } else {
                 PDType1Font font = PDType1Font.HELVETICA;
                 contentStream.setFont(font, params.fontSize);
                 nameWidth = font.getStringWidth(params.replacement) / 1000 * params.fontSize;
                 nameHeight = (font.getFontDescriptor().getCapHeight()) / 1000 * params.fontSize;
             }
             float posY = params.centerY + nameHeight + 7.5f;
             float posX = centerXF - (nameWidth / 2.0f);
             contentStream.beginText();
             contentStream.newLineAtOffset(posX, posY);
             contentStream.showText(params.replacement);
             contentStream.endText();
             contentStream.close();
             pdfDocument.save(outputFilePath);
             System.out.println("Name written successfully. Modified PDF saved to: " + outputFilePath);
         } catch (IOException e) {
             e.printStackTrace();
         }
     }
 }
