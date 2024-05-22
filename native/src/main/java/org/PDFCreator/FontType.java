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
 * Enum representing different font types for PDF generation.
 * Each enum constant corresponds to a PDType1Font from Apache PDFBox.
 */
public enum FontType {
    TIMES_ROMAN(PDType1Font.TIMES_ROMAN),
    TIMES_BOLD(PDType1Font.TIMES_BOLD),
    TIMES_ITALIC(PDType1Font.TIMES_ITALIC),
    TIMES_BOLD_ITALIC(PDType1Font.TIMES_BOLD_ITALIC),
    HELVETICA(PDType1Font.HELVETICA),
    HELVETICA_BOLD(PDType1Font.HELVETICA_BOLD),
    HELVETICA_OBLIQUE(PDType1Font.HELVETICA_OBLIQUE),
    HELVETICA_BOLD_OBLIQUE(PDType1Font.HELVETICA_BOLD_OBLIQUE),
    COURIER(PDType1Font.COURIER),
    COURIER_BOLD(PDType1Font.COURIER_BOLD),
    COURIER_OBLIQUE(PDType1Font.COURIER_OBLIQUE),
    COURIER_BOLD_OBLIQUE(PDType1Font.COURIER_BOLD_OBLIQUE),
    SYMBOL(PDType1Font.SYMBOL),
    ZAPF_DINGBATS(PDType1Font.ZAPF_DINGBATS);

    private final PDType1Font font;

    /**
     * Constructor for FontType enum.
     * @param font The PDType1Font corresponding to this enum constant.
     */
    FontType(PDType1Font font) {
        this.font = font;
    }

    /**
     * Get the PDType1Font associated with this FontType enum constant.
     * @return The PDType1Font object.
     */
    public PDType1Font getFont() {
        return font;
    }

    /**
     * Get the PDType1Font corresponding to the given font name.
     * @param fontName The name of the font.
     * @return The PDType1Font object corresponding to the font name.
     * @throws IllegalArgumentException if the font name is invalid or not supported.
     */
    public static PDType1Font getFontByName(String fontName) {
        for (FontType fontType : FontType.values()) {
            if (fontType.name().equalsIgnoreCase(fontName)) {
                return fontType.getFont();
            }
        }
        throw new IllegalArgumentException("Invalid font name: " + fontName);
    }
}
