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

import org.apache.pdfbox.pdmodel.font.PDType1Font;

/**
 * This class provides a method to get a PDType1Font object by its name.
 */

public class getFontByName {
    /**
     * Returns a PDType1Font object based on the provided font name.
     * The method supports the following font names: TIMES_ROMAN, TIMES_BOLD, TIMES_ITALIC, TIMES_BOLD_ITALIC,
     * HELVETICA, HELVETICA_BOLD, HELVETICA_OBLIQUE, HELVETICA_BOLD_OBLIQUE, COURIER, COURIER_BOLD,
     * COURIER_OBLIQUE, COURIER_BOLD_OBLIQUE, SYMBOL, ZAPF_DINGBATS.
     *
     * @param fontName The name of the font. It is case insensitive.
     * @return The PDType1Font object corresponding to the provided font name.
     * @throws IllegalArgumentException if the provided font name is not supported.
     */
     public static PDType1Font getFontByName(String fontName) {
        return switch (fontName.toUpperCase()) {
            case "TIMES_ROMAN" -> PDType1Font.TIMES_ROMAN;
            case "TIMES_BOLD" -> PDType1Font.TIMES_BOLD;
            case "TIMES_ITALIC" -> PDType1Font.TIMES_ITALIC;
            case "TIMES_BOLD_ITALIC" -> PDType1Font.TIMES_BOLD_ITALIC;
            case "HELVETICA" -> PDType1Font.HELVETICA;
            case "HELVETICA_BOLD" -> PDType1Font.HELVETICA_BOLD;
            case "HELVETICA_OBLIQUE" -> PDType1Font.HELVETICA_OBLIQUE;
            case "HELVETICA_BOLD_OBLIQUE" -> PDType1Font.HELVETICA_BOLD_OBLIQUE;
            case "COURIER" -> PDType1Font.COURIER;
            case "COURIER_BOLD" -> PDType1Font.COURIER_BOLD;
            case "COURIER_OBLIQUE" -> PDType1Font.COURIER_OBLIQUE;
            case "COURIER_BOLD_OBLIQUE" -> PDType1Font.COURIER_BOLD_OBLIQUE;
            case "SYMBOL" -> PDType1Font.SYMBOL;
            case "ZAPF_DINGBATS" -> PDType1Font.ZAPF_DINGBATS;
            default -> throw new IllegalArgumentException("Invalid font name: " + fontName);
        };
    }   
}
